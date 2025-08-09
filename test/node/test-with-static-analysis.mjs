// @ts-check

import path from "path";
import fs from "fs";
import assert from "assert";
import { describe, it } from "node:test";
import { getSchema } from "../../tools/schema.mjs";

const directories = {
  src: "src",
  lib: "lib",
};

/**
 * @param {string} folder
 */
function* mssPaths(folder) {
  for (const item of fs.readdirSync(folder).map((f) => path.join(folder, f))) {
    if (fs.lstatSync(item).isDirectory()) {
      yield* mssPaths(item);
    } else if (item.match(/\.mss$/)) {
      yield item;
    }
  }
}

describe("attribute and element usage", async () => {
  const { attributes, elements } = await getSchema();
  /** @type {{[filePath: string]: string[]}} */
  const undecidableLines = {};

  for (const filePath of mssPaths(directories.src)) {
    describe(filePath, () => {
      const lines = fs.readFileSync(filePath, { encoding: "utf8" }).split("\n");
      for (let lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        const { error, undecidable } = checkLine(lines[lineIndex], attributes, elements);
        if (error) {
          it(`${filePath}:${lineIndex + 1}: ${lines[lineIndex]}`, () => {
            assert(false, error);
          });
        }
        if (undecidable) {
          (undecidableLines[filePath] ||= []).push(lineIndex + 1 + ": " + lines[lineIndex]);
        }
      }
    });
  }

  const undecidableFiles = Object.entries(undecidableLines);
  if (undecidableFiles.length > 0) {
    console.log(
      "For the following lines, it can only be checked manually if the passed element or attribute names are legal:"
    );
    for (const [filePath, messages] of undecidableFiles) {
        console.log("\x1b[43m  " + filePath + "\x1b[0m");
      for (const message of messages) {
        console.log("  " + message);
      }
    }
  }
});

describe("test if static analysis of lines works", () => {
  it("reports an error if a line creates invalid elements", () => {
    assertLine("el = CreateElement('foo'):", new Set(), new Map([["bar", ""]]), true, false);
  });
  it("reports an error if a line adds invalid attributes", () => {
    assertLine("AddAttribute(el, 'foo', 'bar'):", new Set(["bar"]), new Map(), true, false);
  });
  it("reports an error if a line adds invalid attributes with AddAttributeValue()", () => {
    assertLine(
      "AddAttributeValue(my.element, 'foo', 'bar'):",
      new Set(["bar"]),
      new Map(),
      true,
      false
    );
  });
  it("reports no error if a line creates valid elements", () => {
    assertLine("el = CreateElement('foo'):", new Set(), new Map([["foo", ""]]), false, false);
  });
  it("reports no error if a line adds valid attributes", () => {
    assertLine(
      "AddAttribute(getElement(), 'foo', 'bar'):",
      new Set(["foo"]),
      new Map(),
      false,
      false
    );
  });
  it("reports an undecidable situation if a variable is used for element names", () => {
    assertLine("el = CreateElement(foo):", new Set(), new Map(), false, true);
  });
  it("reports an undecidable situation if a variable is used for attribute names", () => {
    assertLine("AddAttribute(el, foo, 'bar'):", new Set(), new Map(), false, true);
  });
});

/**
 * @param {string} line
 * @param {Set<string>} legalAttributes
 * @param {Map<string, any>} legalElements
 * @param {boolean} errorExpected
 * @param {boolean} undecidableExpected
 */
function assertLine(line, legalAttributes, legalElements, errorExpected, undecidableExpected) {
  const { error, undecidable } = checkLine(line, legalAttributes, legalElements);
  assert.equal(
    !!error,
    errorExpected,
    errorExpected ? "error field expected" : "no error field expected"
  );
  assert.equal(
    !!undecidable,
    undecidableExpected,
    undecidableExpected ? "undecidable field expected" : "no undecidable field expected"
  );
}

/**
 * @param {string} line
 * @param {Set<string>} legalAttributes
 * @param {Map<string, any>} legalElements
 * @returns {{undecidable?: string, error?: string}}
 */
function checkLine(line, legalAttributes, legalElements) {
  if (line.match(/^\s*(export +)?function\s+/)) {
    return {};
  }

  const stringArgumentRegex = /^'([^']+)/;

  const [a, b, attributeArgument] = line.match(/AddAttribute(Value)?\s*\(\s*[^,]+,\s*(.+)/) || [];
  const [, attributeName] = attributeArgument?.match(stringArgumentRegex) || [];
  if (attributeArgument) {
    if (!attributeName) {
      return { undecidable: attributeArgument };
    }
    if (!legalAttributes.has(attributeName) && !attributeName.match(/^xmlns(:.+)?$/)) {
      return { error: attributeName + " is not a valid attribute name" };
    }
  }

  const [, elementArgument] = line.match(/CreateElement\s*\((.+)/) || [];
  const [, elementName] = elementArgument?.match(stringArgumentRegex) || [];
  if (elementArgument) {
    if (!elementName) {
      return { undecidable: elementArgument };
    }
    if (!legalElements.has(elementName)  && elementName !== '<!--') {
      return { error: elementName + " is not a valid element name" };
    }
  }

  return {};
}

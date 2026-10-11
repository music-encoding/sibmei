// @ts-check

"use strict";

const { describe, it } = require("node:test");
const assert = require("assert");
const xpath = require("fontoxpath");

const utils = require("./utils");

/**
 * This test iterates over all exported MEI test files, and in those files,
 * iterates over all <annot> elements with `@type='xquery-test'` and applies the
 * content as XQuery to the <annot>'s parent <measure>. The test passes if the
 * XQuery result is truthy (i.e. returns true or matches something).
 *
 * XQuery annotations are input in Sibelius with a text style named 'XQuery
 * test' (or, for legacy reasons, 'XPath test'). The text must be a valid XQuery
 * expression that can be evaluated in the context of the measure. This style is
 * present e.g. in lines.sib and can be copied from there (by simply copying a
 * text object of that style).
 */

/** @type {{[prefix: string]: string}} */
const namespaceMap = {
  assert: "NS:ASSERT",
  mei: "http://www.music-encoding.org/ns/mei",
  xlink: "http://www.w3.org/1999/xlink",
};

/**
 * @param {any} _domFacade  (unused)
 * @param {any} a  Any XQuery value
 * @param {any} b  Any XQuery value
 * @param {string} [testDescription ]
 * @returns {boolean}
 */
function xqueryAssertEqual(_domFacade, a, b, testDescription) {
  // Do comparison with XQuery semantics
  /** @type boolean */
  const valuesEqual = xpath.evaluateXPath("$a = $b", null, null, { a, b });
  if (valuesEqual) return true;
  const atomicValues = [a, b].map((v) => xpath.evaluateXPath("data($v)", null, null, { v }));
  const message = testDescription ? "Failed: " + testDescription + "\n" : "";
  // Use JSON.stringify to better show the types of `a` and `b`
  assert.fail(message + atomicValues.map((v) => JSON.stringify(v)).join(" != "));
}

/**
 * @param {any} _domFacade  (unused)
 * @param {any} result  The result of an evaluated XQuery.  Assertion fails if
 *  this result is empty or falsy.
 * @param {string} [message]
 * @returns {boolean}
 */
function xqueryAssertOk(_domFacade, result, message) {
  message = message && "Failed: " + message;
  if (result instanceof Array && result.length === 0) {
    assert.ok(false, message || "XQuery did not match the expected node(s)");
  }
  assert(result !== false, message || "XQuery evaluated to a falsy result");
  return true;
}

/**
 * @param {string} localName
 * @param {(_domFacade: any, ...functionArgs: any[]) => any} callback
 * @param {string[]} minimalSignature  Signature including all optional parameters
 */
function registerXQueryAssertion(localName, callback, minimalSignature) {
  const namespaceURI = namespaceMap.assert;
  const returnType = "xs:boolean";
  // Register function with and without assertion message as last parameter
  for (const signature of [minimalSignature, [...minimalSignature, "xs:string"]]) {
    xpath.registerCustomXPathFunction({ namespaceURI, localName }, signature, returnType, callback);
  }
}

registerXQueryAssertion("ok", xqueryAssertOk, ["item()*"]);
registerXQueryAssertion("equal", xqueryAssertEqual, ["item()?", "item()?"]);

// Make sure that the export actually exported XQuery test annotations
let foundXQueryTest = false;

for (const fileName of utils.getExportedTestFileNames()) {
  const mei = utils.getTestMeiDom(fileName);
  /** @type Element[] */
  let xqueryAnnots = xpath.evaluateXPath("//*:annot[@type='xquery-test']", mei);
  // evaluateXPath() returns a single object when the XQuery evaluates to a
  // single object or value, but we always want an array
  if (!Array.isArray(xqueryAnnots)) {
    xqueryAnnots = [xqueryAnnots];
  }
  if (xqueryAnnots.length === 0) {
    continue;
  }
  foundXQueryTest = true;
  describe(fileName, () => {
    it(`${fileName} matches XQuery tests`, function () {
      /** @type string[] */
      const messages = [];
      for (const annot of xqueryAnnots) {
        const measureN = xpath.evaluateXPathToString("ancestor::*:measure/@n", annot);
        if (!measureN) {
          messages.push(
            "<annot type='xquery-test'> elements are expected to be children of <measure> elements with an @n attribute",
          );
          continue;
        }
        const annotText = annot.textContent;
        // If we find a leading comment, we use it as test description
        const [, , testDescription, testXquery] =
          annotText.match(/^\s*(\(:\s*(.*?)\s*:\))?([\s\S]*)$/) || [];
        try {
          assertTestXQuery(annot, testXquery, testDescription);
        } catch (e) {
          messages.push(
            `measure: ${measureN}\n${testDescription ? testDescription + "\n" : ""}XQuery: ${testXquery}\n${e}`,
          );
        }
      }
      assert.ok(messages.length === 0, "\n" + messages.join("\n\n"));
    });
  });
}

const evaluationOptions = {
  language: xpath.evaluateXPath.XQUERY_3_1_LANGUAGE,
  /** @param {string} prefix */
  namespaceResolver(prefix) {
    return namespaceMap[prefix || "mei"];
  },
};

/**
 * @param {Element} annot
 * @param {string} testXquery
 * @param {string} [testDescription]
 */
function assertTestXQuery(annot, testXquery, testDescription) {
  const measure = xpath.evaluateXPathToFirstNode("ancestor::*:measure", annot);
  assert(measure, "XQuery test <annot> must have an ancestor <measure>");
  const staffN = annot.getAttribute("staff");
  const staff = staffN && xpath.evaluateXPathToFirstNode(`*:staff[@n='${staffN}']`, measure);
  assert(
    staff,
    `<staff> ${staffN} for XQuery test <annot> ${annot.getAttribute("xml:id")} not found`,
  );
  xqueryAssertOk(
    null,
    xpath.evaluateXPath(
      testXquery,
      annot.parentNode,
      null,
      {
        measure,
        staff,
      },
      undefined,
      evaluationOptions,
    ),
    testDescription,
  );
}

describe("XQuery annotation export", function () {
  it("exports XQuery annotations", function () {
    assert.ok(foundXQueryTest, "No XQuery test annotations were exported");
  });
});

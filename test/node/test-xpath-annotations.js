"use strict";

const { describe, it } = require('node:test');
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const xpath = require('fontoxpath');

const utils = require('./utils');

/**
 * This test iterates over all exported MEI test files, and in those files,
 * iterates over all <annot> elements with @type='xpath-test' and applies the
 * content as XPath to the <annot>'s parent <measure>. The test passes if the
 * XPath result is truthy (i.e. returns true or matches something).
 *
 * XPath annotations are input in Sibelius with a text style named 'XPath
 * test'. The text must be a valid XPath expression that can be evaluated in
 * the context of the measure. This style is present e.g. in lines.sib and can
 * be copied from there (by simply copying a text object of that style).
 *
*/

// If we have an XPath test that ends with an "=" followed by a string or a
// number, we do assert.Equal() to make interpreting the test results easer. To
// do this we have to extract the right hand side from the XPath.
const xpathWithComparison = /^(.*)\s*=\s*((\d+)|"([^"]*)"|'([^']*)')\s*$/;
// Make sure that the export actually exported XPath test annotations
let foundXPathTest = false;

for (const fileName of fs.readdirSync(path.join('build', 'develop', 'sibmeiTestSibs'), 'utf8')) {
  if (!fileName.match(/\.mei$/)) {
    continue;
  }
  const mei = utils.getTestMeiDom(fileName);
  let xpathAnnots = xpath.evaluateXPath("//*:annot[@type='xpath-test']", mei);
  // evaluateXPath() returns a single object when the XPath evaluates to a
  // single object or value, but we always want an array
  if (!Array.isArray(xpathAnnots)) {
    xpathAnnots = [xpathAnnots];
  }
  if (xpathAnnots.length === 0) {
    continue;
  }
  foundXPathTest = true;
  describe(fileName, () => {
    it("matches XPath tests", function() {
      const messages = [];
      for (const annot of xpathAnnots) {
        const measure = annot.parentNode.getAttribute("n");
        const [, testXpath, expectedString, expectedNumber] = (
          annot.textContent.match(xpathWithComparison) || [, annot.textContent]
        );
        // If we find a leading comment, we us it as test description
        const testDescription = (annot.textContent.match(/s*\(:\s*(.*)\s*:\)/) || [])[1];
        const result = xpath.evaluateXPath(
          expectedString || expectedNumber ? `string-join(${testXpath}, '')` : testXpath,
          annot.parentNode
        );
        if (expectedNumber) {
          evaluateResult(messages, measure, testXpath, result, expectedNumber);
        } else if (expectedString) {
          const stringWithoutQuotes = expectedString.replace(/.(.*)./, "$1");
          evaluateResult(messages, measure, testXpath, result, testDescription, stringWithoutQuotes);
        } else {
          evaluateResult(messages, measure, testXpath, result, testDescription);
        }
      }
      assert.ok(messages.length === 0, '\n' + messages.join('\n\n'));
    });
  });
}

function evaluateResult(messages, measure, testXpath, result, testDescription, expectedResult) {
  let message = '';
  if (expectedResult === undefined) {
    const resultIsEmptyArray = result instanceof Array && result.length === 0;
    if (resultIsEmptyArray || result === false) {
      message = `measure: ${measure}, XPath: ${testXpath}`;
    }
  } else {
    // Intentionally compare with "!=" instead of "!=="
    if (result != expectedResult) {
      message = `measure: ${measure}, XPath: ${testXpath}, expected: ${expectedResult}, actual: ${result}`;
    }
  }
  if (message) {
    if (testDescription) {
      message = message + '\n' + testDescription;
    }
    messages.push(message);
  }
}

describe("XPath annotation export", function() {
  it("exports XPath annotations", function() {
    assert.ok(foundXPathTest, "No XPath test annotations were exported");
  });
});

"use strict";

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

let foundXPathTest = false;

for (const fileName of fs.readdirSync(path.join('build', 'develop', 'sibmeiTestSibs'), 'utf8')) {
  if (!fileName.match(/\.mei$/)) {
    continue;
  }
  const mei = utils.getTestMeiDom(fileName);
  const xpathAnnots = xpath.evaluateXPath("//*:annot[@type='xpath-test']", mei);
  if (xpathAnnots.length === 0) {
    continue;
  }
  foundXPathTest = true;
  describe(fileName, () => {
    it("matches XPath tests", function() {
      const messages = [];
      for (const annot of xpathAnnots) {
        const measure = annot.parentNode.getAttribute("n");
        const testXpath = annot.textContent;
        const result = xpath.evaluateXPath(testXpath, annot.parentNode);
        const resultIsEmptyArray = result instanceof Array && result.length === 0;
        if (resultIsEmptyArray || result === false) {
          messages.push(`measure: ${measure}, XPath: ${testXpath}`);
        }
      }
      assert.ok(messages.length === 0, '\n' + messages.join('\n\n'));
    });
  });
}

describe("XPath annotation export", function() {
  it("exports XPath annotations", function() {
    assert.ok(foundXPathTest, "No XPath test annotations were exported");
  });
});

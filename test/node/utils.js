"use strict";

const fs = require('fs');
const path = require('path');
const parser = require('slimdom-sax-parser');
const assert = require('assert');

module.exports = {
  getTestMeiContent: function(fileName) {
    const meiPath = path.join('build', 'develop', 'sibmeiTestSibs', fileName);
    return fs.readFileSync(meiPath, {encoding: 'utf16le'});
  },

  getTestMeiDom: function(fileName) {
    return parser.sync(this.getTestMeiContent(fileName));
  },

  getExportedTestFileNames: function () {
    return fs
      .readdirSync(path.join("build", "develop", "sibmeiTestSibs"), "utf8")
      .filter((fileName) => fileName.match(/\.mei$/));
  },

  assertAttrOnElements: function(elements, indices, attName, expectedValue) {
    for (let i = 0; i < elements.length; i += 1) {
      const actualValue = elements[i].getAttribute(attName);
      const elementDescription = 'element index ' + i + ' (' + elements[i].localName + ')' + ' ("' + elements[i].outerHTML + '")';
      if (indices.indexOf(i) >= 0) {
        assert.strictEqual(actualValue, expectedValue, `value for ${attName} not found on ${elementDescription}`);
      } else {
        assert.notEqual(actualValue, expectedValue, `value for ${attName} unexpectedly found on ${elementDescription}`);
      }
    }
  },

  assertHasAttr: function(elements, attName) {
    for (let i = 0; i < elements.length; i += 1) {
      assert.notEqual(elements[i].getAttribute(attName), null, 'element ' + i + ' misses attribute @' + attName);
    }
  },

  assertHasAttrNot: function(elements, attName) {
    for (let i = 0; i < elements.length; i += 1) {
      assert.strictEqual(elements[i].getAttribute(attName), null, `element ${i} should not have attribute @${attName}`);
    }
  },

  assertElsHasAttr: function(elements, indices, attName) {
    for (let i = 0; i < elements.length; i += 1) {
      const elementDescription = 'element index ' + i + ' (' + elements[i].localName + ')';
      if (indices.indexOf(i) >= 0) {
        assert.notEqual(elements[i].getAttribute(attName), null, 'attribute not found on ' + elementDescription);
      }
      else {
        assert.equal(elements[i].getAttribute(attName), null,  'attribute unexpectedly found on ' + elementDescription);
      }
    }
  },

  /**
   * @param  {Element[]} elements
   * @param  {string} attName
   * @param  {string|RegExp} expectedFormat  If a string is supplied, the
   *    attributes will be tested for strict equality, otherwise if they match
   *    the RegExp.
   */
  assertAttrValueFormat: function (elements, attName, expectedFormat) {
    for (let i = 0; i < elements.length; i += 1) {
      const actualValue = elements[i].getAttribute(attName);
      if (actualValue == undefined) {
        assert.ok(false, 'element ' + i + ' has no @' + attName);
      }
      else if (expectedFormat instanceof RegExp) {
        assert.ok(expectedFormat.test(actualValue), 'value on element ' + i + ' does not match');
      }
      else {
        assert.strictEqual(actualValue, expectedFormat);
      }
    }
  },
}

"use strict";

const fs = require('fs');
const path = require('path');
const parser = require('slimdom-sax-parser');
const assert = require('assert');
const xpath = require('fontoxpath');

module.exports = {
  getTestMeiDom: function(fileName) {
    const meiPath = path.join('build', 'MEI Export', 'sibmeiTestSibs', fileName);
    const meiString = fs.readFileSync(meiPath, {encoding: 'utf16le'});
    return parser.sync(meiString);
  },

  assertAttrOnElements: function(elements, indices, attName, expectedValue) {
    for (let i = 0; i < elements.length; i += 1) {
      const actualValue = elements[i].getAttribute(attName);
      const elementDescription = 'element index ' + i + ' ("' + elements[i].innerHTML + '")';
      if (indices.indexOf(i) >= 0) {
        assert.strictEqual(actualValue, expectedValue, 'value not found on ' + elementDescription);
      } else {
        assert.notEqual(actualValue, expectedValue, 'value unexpectedly found on ' + elementDescription);
      }
    }
  }
}

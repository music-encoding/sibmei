"use strict";

const fs = require('fs');
const path = require('path');
const parser = require('slimdom-sax-parser');

module.exports = {
  getTestMeiDom: function(fileName) {
    const meiPath = path.join('build', 'MEI Export', 'sibmeiTestSibs', fileName);
    const meiString = fs.readFileSync(meiPath, {encoding: 'utf16le'});
    return parser.sync(meiString);
  }
}

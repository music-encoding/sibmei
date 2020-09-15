"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

describe("Extensions", function() {
  const mei = utils.getTestMeiDom('extensions.mei');
  const symbols = xpath.evaluateXPath('//*:symbol', mei);
  const text = xpath.evaluateXPath('//*:anchoredText', mei);

  it("exports custom symbols", function() {
    utils.assertAttrValueFormat(symbols, 'fontfam', 'myCustomFont');
    utils.assertAttrValueFormat(symbols, 'glyph.name', 'mySymbolGlyph');
    assert.strictEqual(symbols.length, 2, '2 symbols expected');
    utils.assertAttrOnElements(symbols, [1], 'type', 'myRedType');
  });

  it("attaches control events to measures", function(){
    for (let i = 0; i < 2; i++) {
      const measure = symbols[i].parentElement;
      assert.strictEqual(measure.tagName, "measure", 'must be attached to measures');
      assert.strictEqual(String(i + 1), measure.getAttribute("n"), 'test file has 1 symbol per measure');
    }
  });

  it("exports custom text by name", function(){
    assert.notStrictEqual(text.length, 0 ,"custom <anchoredText> is missing");
  });
});

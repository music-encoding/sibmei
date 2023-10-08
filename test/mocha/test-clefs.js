"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

describe("Clefs", () => {
  const mei = utils.getTestMeiDom('clefs.mei');

  it("handles clefs inside beams", () => {
    assert.deepEqual(
      xpath.evaluateXPath(
        '//*:measure[@n="1"]/*:staff[1]/*:layer[1]/*:beam[1]/*', mei
      ).map(el => el.tagName),
      ["note", "clef", "note"]
    );
  });

  it("handles clefs inside tuplets", () => {
    assert.deepEqual(
      xpath.evaluateXPath(
        '//*:measure[@n="1"]/*:staff[1]/*:layer[1]/*:tuplet[1]/*:beam/*', mei
      ).map(el => el.tagName),
      ["note", "note", "clef", "note"]
    );
    assert.deepEqual(
      xpath.evaluateXPath(
        '//*:measure[@n="1"]/*:staff[1]/*:layer[1]/*:tuplet[2]/*', mei
      ).map(el => el.tagName),
      ["note", "clef", "note", "note"]
    );
  });

  it("handles clefs as first elements in bar", function(){
    assert.strictEqual(
      xpath.evaluateXPath(
        '//*:measure[@n="2"]/*:staff[1]/*:layer[1]/*[1]', mei
      ).tagName,
      'clef'
    );
  });

  it("exports clef color", function() {
    const coloredClef = xpath.evaluateXPath('//*:clef[@color]', mei);
    // only the clef in bar 2 is colored
    const measure = xpath.evaluateXPath('ancestor::*:measure', coloredClef);
    assert.strictEqual(measure.getAttribute("n"), "2");
  });
});

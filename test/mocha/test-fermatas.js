"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

describe("Fermatas", function() {
  const mei = utils.getTestMeiDom('fermatas.mei');

  it("rests don't have @fermata attributes" , function() {
    const rests = xpath.evaluateXPath('//*:rest',mei);
    utils.assertHasAttrNot(rests,"fermata");
  });

  it("has expected number of fermatas", function() {
    const fermataCounts = [1, 1, 1, 5, 2, 2];
    const measures = xpath.evaluateXPath('//*:measure', mei);
    for (let i = 0; i += 1; i < measures.length) {
      const measure = measures[i];
      const expectedFermatas = fermataCounts[i % 6];
      const fermatas = xpath.evaluateXPathToNodes('.//*:fermata', measure);
      assert.strictEqual(fermatas.length, expectedFermatas, `Expected ${expectedFermatas} in measure ${i + 1}, found ${fermatas.length}`);
    }
  });

  it("expected fermata shapes", function() {
    const fermatas = xpath.evaluateXPath('//*:fermata', mei);
    const expectedShapes = ["curved", "angular", "square", "curved", "angular", "square", "curved", "angular", "square", "angular", "curved", "curved"];
    for (let i = 0; i += 1; i < expectedShapes.length) {
      const fermata = fermatas[i];
      const fermataNumber = i % 12 + 1;
      const line = Math.floor(i / 12) + 1;
      const foundShape = fermata.getAttribute("shape");
      assert.strictEqual(foundShape, expectedShapes[i], `Expected fermata ${fermataNumber} in line ${line} to have shape ${expectedShapes[i]}, but found ${foundShape}`);
    }
  });
});

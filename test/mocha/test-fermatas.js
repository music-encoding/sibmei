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
    const expectedShapes = ["curved", "angular", "square", "curved", "angular", "square", "curved", "angular", "angular", "square", "curved", "curved"];
    for (let i = 0; i += 1; i < expectedShapes.length) {
      const fermata = fermatas[i];
      const fermataNumber = i % 12 + 1;
      const line = Math.floor(i / 12) + 1;
      const expectedShape = expectedShapes[i % 12];
      const foundShape = fermata.getAttribute("shape");
      assert.strictEqual(foundShape, expectedShape, `Expected fermata ${fermataNumber} in line ${line} to have shape ${expectedShape}, but found ${foundShape}`);
    }
  });

  it("expected fermata forms", function() {
    const fermatas = xpath.evaluateXPath('//*:fermata', mei);
    const expectedForms = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1];
    for (let i = 0; i += 1; i < expectedForms.length) {
      const fermata = fermatas[i];
      const fermataNumber = i % 12 + 1;
      const line = Math.floor(i / 12) + 1;
      const flip = line == 3 ? -1 : 1;
      const expectedForm = expectedForms[i % 12] * flip == 1 ? 'norm' : 'inv';
      const foundForm = fermata.getAttribute("form");
      assert.strictEqual(foundForm, expectedForm, `Expected fermata ${fermataNumber} in line ${line} to have form ${expectedForm}, but found ${foundForm}`);
    }
  });
});

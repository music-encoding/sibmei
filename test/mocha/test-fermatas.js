"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

describe("Fermatas", function() {
  const mei = utils.getTestMeiDom('fermatas.mei');
  const measures = xpath.evaluateXPath('//*:measure', mei);
  // Fermatas may be written in arbitrary order, so we sort them.
  const fermatasByMeasure = measures.map(measure => xpath
    .evaluateXPathToNodes('.//*:fermata', measure)
    .sort((a, b) => {
      const tstampA = a.getAttribute('tstamp');
      const tstampB = b.getAttribute('tstamp');
      if (tstampA < tstampB) {
        return -1;
      } else if (tstampA > tstampB) {
        return 1;
      }
      // For multiple fermatas at the same tstamp, sort alphabeticall by @shape
      if (a.getAttribute('shape') < b.getAttribute('shape')) {
        return -1;
      } else {
        return 1;
      }
    })
  );


  it("rests don't have @fermata attributes" , function() {
    const rests = xpath.evaluateXPath('//*:rest',mei);
    utils.assertHasAttrNot(rests,"fermata");
  });

  it("expected fermata shapes", function() {
    const expectedShapes = [
      ["curved"],                                           // b. 1,  7, 13
      ["angular"],                                          // b. 2,  8, 14
      ["square"],                                           // b. 3,  9, 15
      ["curved", "angular", "square", "angular", "curved"], // b. 4, 10, 16
      ["angular", "square"],                                // b. 5, 11, 17
      ["curved", "curved"]                                  // b. 6, 12, 18
    ];
    for (let barIndex = 0; barIndex < measures.length; barIndex += 1) {
      const foundShapes = (fermatasByMeasure[barIndex] || []).map(fermata => fermata.getAttribute("shape"));
      const expectedShapesInBar = expectedShapes[barIndex % 6];
      assert.deepEqual(foundShapes, expectedShapesInBar, `Expected fermata shapes ${expectedShapesInBar} in bar ${barIndex + 1}, but found ${foundShapes}`);
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

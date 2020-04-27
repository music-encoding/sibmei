"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

describe("Staves", () => {
    const mei = utils.getTestMeiDom('staves.mei');
    const staffDefs = xpath.evaluateXPath('//*:staffDef',mei);
    const transposing = [0,3,4,5,6,8,9,10,11,12,13,21,22,23,24,35];
    const diatTrans = [7,-4,2,-1,-8,-7,-4,-4,-8,-1,-1,14,7,7,7,-7];
    const chromTrans = [12,-7,3,-2,-14,-12,-7,-7,-14,-2,-2,24,12,12,12,-12];
    const transUp = [0,4,21,22,23,24];
    const transDown = [3,5,6,8,9,10,11,12,13,35];
    const isNeg = /^-[0-9]*$/;
    const isPos = /^[0-9]*$/;

    it("transposing instruments have @trans.diat", function() {
        utils.assertElsHasAttr(staffDefs,transposing,"trans.diat");
    });
    it("transposing instruments have @trans.semi", function() {
        utils.assertElsHasAttr(staffDefs,transposing,"trans.semi");
    });
    it("@trans.diat and @trans.semi have the same sign", function() {

        staffDefs.forEach(element => {
            if(element.getAttribute("trans.diat" != null)) {
                if(isNeg.test(element.getAttribute("trans.diat"))) {
                    assert.ok(isNeg.test(element.getAttribute("trans.semi")),
                    "staffDef no. " + element.getAttribute("n") + ": if @trans.diat is negative @trans.semi must be too");
                }
                else {
                    assert.ok(isPos.test(element.getAttribute("trans.semi")),
                    "staffDef no. " + element.getAttribute("n") + ": if @trans.diat is positive @trans.semi must be too");
                }
            }
        });
    });
    it("instruments transposing upwards have positive values", function() {
        transUp.forEach(element => {
            var diat = staffDefs[element].getAttribute("trans.diat");
            var semi = staffDefs[element].getAttribute("trans.semi");
            assert.ok(isPos.test(diat) && isPos.test(semi),
            "staffDef no. " + staffDefs[element].getAttribute("n") + " should have positive values");
        });
    });
    it("instruments transposing downwards have negative values", function() {
        transDown.forEach(element => {
            var diat = staffDefs[element].getAttribute("trans.diat");
            var semi = staffDefs[element].getAttribute("trans.semi");
            assert.ok(isNeg.test(diat) && isNeg.test(semi),
            "staffDef no. " + staffDefs[element].getAttribute("n") + " should have positive values");
        });
    });
    it("writes correct transposition values", function() {
      for (let i = 0; i < transposing.length; i++) {
        const staffDef = staffDefs[transposing[i]];
        assert.equal(parseInt(staffDef.getAttribute("trans.diat")), diatTrans[i]);
        assert.equal(parseInt(staffDef.getAttribute("trans.semi")), chromTrans[i]);
      }
    });
});

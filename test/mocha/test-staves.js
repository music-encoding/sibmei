"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

describe("Staves", () => {
    const mei = utils.getTestMeiDom('staves.mei');
    const staffDefs = xpath.evaluateXPath('//*:staffDef',mei);
    const transposing = [0,3,4,5,6,8,9,10,11,12,13,21,22,23,24,35];
    const transUp;
    const transDown;

    it("transposing instruments have @trans.diat", () => {
        utils.assertElsHasAttr(staffDefs,transposing,"trans.diat");
    });
    it("transposing instruments have @trans.semi", () => {
        utils.assertElsHasAttr(staffDefs,transposing,"trans.semi");
    });
});
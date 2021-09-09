"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

const mei = utils.getTestMeiDom('transposing-instruments.mei');

describe("scoreDef", function() {
    const staffDefs = xpath.evaluateXPath("//*:staffDef", mei);
    it("@trans.semi", function() {
        assert.deepStrictEqual(staffDefs.map(s => s.getAttribute("trans.semi")), ["-2", "-7", null]);
    });
    it("@trans.diat", function() {
        assert.deepStrictEqual(staffDefs.map(s => s.getAttribute("trans.diat")), ["-1", "-4", null]);
    });
});

// TODO: The test file has an instrument change with changing transposition that
// is not exported properly

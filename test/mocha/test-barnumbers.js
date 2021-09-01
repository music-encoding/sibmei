"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

const mei = utils.getTestMeiDom('barnumbers.mei');

describe("bar numbers", function() {
    it("exports @n attributes", function() {
        const nAttributes = xpath.evaluateXPath("//*:measure/@n", mei);
        assert.deepEqual(nAttributes, ['1', '2', '3', '4'], "@n is simply ascending");
    });
    it("exports @label attributes", function() {
        const nAttributes = xpath.evaluateXPath("//*:measure", mei).map(m => m.getAttribute('label'));
        assert.deepEqual(nAttributes, [null, null, '5', '1'], "@n is simply ascending");
    });
});

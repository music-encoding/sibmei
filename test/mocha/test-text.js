"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

const meiText = utils.getTestMeiDom('text.mei');

describe("Text elements", function() {
    it("figured bass elements in measure 4", function() {
        const m4harms = xpath.evaluateXPath("//*:measure[@n='4']/*:harm", meiText);
        assert.strictEqual(m4harms.length, 3, "There should be 3 <harm> elements in measure 4");
    });
    it("check for <tempo> in measure 6", function() {
        const tempo = xpath.evaluateXPath("//*:measure[@n='6']/*:tempo", meiText);
        assert.notStrictEqual(tempo.length, null ,"<tempo> in measure 6 is missing");
    });
    // test for dynam
    it("two <dynam> elements", function() {
        const dynams = xpath.evaluateXPath("//*:dynam", meiText);
        assert.strictEqual(dynams.length,2,"there should be 2 <dynam> elements");
    });
    // test for title, subtitle & composer
    // test for plain text
    // test formatting: bold, subscript, superscript,italic, font change, font size

});
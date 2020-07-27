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
        assert.notStrictEqual(tempo.length, 0 ,"<tempo> in measure 6 is missing");
    });
    // test for dynam
    it("two <dynam> elements", function() {
        const dynams = xpath.evaluateXPath("//*:dynam", meiText);
        assert.strictEqual(dynams.length, 2,"there should be 2 <dynam> elements");
    });
    // test for title, subtitle & composer
    it("check for composer label in measure 1", function() {
        const composerEl = xpath.evaluateXPath("//*:measure[@n='1']//*:persName[@role='Composer']", meiText);
        assert.notStrictEqual(composerEl.length, 0,"The composer label is missing");
    });
    it("check for subordinate title in measure 1", function() {
        const subTitle = xpath.evaluateXPath("//*:measure[@n='1']//*:title[@type='subordinate']", meiText);
        assert.notStrictEqual(subTitle.length, 0, "The subtitle is missing");
    });
    // test for plain text (not implemented yet)
    it("check for plain text in measure 2", function() {
        const plain = xpath.evaluateXPath("//*:measure[@n='2']/*:anchoredText", meiText);
        assert.notStrictEqual(plain.length, 0 ,"plain text in measure 2 is missing");
    });
    // test formatting: subscript, superscript
    it("check for superscript", function() {
        const superscript = xpath.evaluateXPath("//*:measure[@n='1']//*:title[@type='subordinate']/*:rend[@rend='sup']", meiText);
        assert.notStrictEqual(superscript.length, 0, "Superscript in subtitle is missing");
    });
    it("check for subscript", function() {
        const subscript = xpath.evaluateXPath("//*:measure[@n='1']//*:title[@type='subordinate']/*:rend[@rend='sub']", meiText);
        assert.notStrictEqual(subscript.length, 0, "Subscript in subtitle is missing");
    });
    // check for front matter
    it("check for front matter", function() {
        const firstMusicChild = xpath.evaluateXPath("//*:music/element()[1]", meiText);
        assert.strictEqual(firstMusicChild.localName, "front");
    });
    // test formatting: bold, italic, font change, font size
});
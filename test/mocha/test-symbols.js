"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

const meiSymbols = utils.getTestMeiDom('symbols.mei');

describe("Symbols", function() {
    describe("Control events: Expected attributes (mordents and turns)", function() {
        const mordents = xpath.evaluateXPath('//*:mordent', meiSymbols);
        const turns = xpath.evaluateXPath('//*:turn', meiSymbols);
        it("Mordent has @form='upper'", function() {
          utils.assertAttrOnElements(mordents, [1], 'form', 'upper');
        });
        it("Inverted mordent has @form='lower'", function() {
          utils.assertAttrOnElements(mordents, [0], 'form', 'lower');
        });
        it("Turn has @form='upper'", function() {
          utils.assertAttrOnElements(turns, [0], 'form', 'upper');
        });
        it("Inverted turn has @form='lower'", function() {
          utils.assertAttrOnElements(turns, [1], 'form', 'lower');
        });
      });
    describe("Modifiers (children of note): Articulations", function() {
        var artics = xpath.evaluateXPath('//*:artic', meiSymbols);
        it("21 articulations were created", function () {
            assert.strictEqual(artics.length, 21, "Not all 21 articulations were created");
        });
        it("<artic> is child of <note>", function() {
            for (let count = 0; count < artics.length; count++) {
                assert.strictEqual(artics[count].parentNode.localName, "note", '<artic> ${i} is not a child of <note>');
            }
        });
        it("every <artic> has @artic", function() {
            utils.assertHasAttr(artics, "artic");
        });
        it("<artic> with @place", function() {
            utils.assertElsHasAttr(artics, [9, 10, 11, 12, 13, 14], 'place');
        });
    });
});
  
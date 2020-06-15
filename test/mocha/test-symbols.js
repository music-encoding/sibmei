"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

const meiSymbols = utils.getTestMeiDom('symbols.mei');

describe("Expected attributes for symbols (mordents and turns)", () => {
    const mordents = xpath.evaluateXPath('//*:mordent', meiSymbols);
    const turns = xpath.evaluateXPath('//*:turn', meiSymbols);
    it("Mordent has @form='upper'", () => {
      utils.assertAttrOnElements(mordents, [0], 'form', 'upper');
    });
    it("Inverted mordent has @form='lower'", () => {
      utils.assertAttrOnElements(mordents, [1], 'form', 'lower');
    });
    it("Turn has @form='upper'", () => {
      utils.assertAttrOnElements(turns, [0], 'form', 'upper');
    });
    it("Inverted turn has @form='lower'", () => {
      utils.assertAttrOnElements(turns, [1], 'form', 'lower');
    });
  });
  
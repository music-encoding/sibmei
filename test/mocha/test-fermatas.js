"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

describe("Fermatas", () => {
  const mei = utils.getTestMeiDom('fermatas.mei');

  it("rests don't have @fermata attributes" , () => {
    const rests = xpath.evaluateXPath('//*:rest',mei);
    utils.assertHasAttrNot(rests,"fermata");
  })
});
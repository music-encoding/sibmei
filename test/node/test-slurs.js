"use strict";

const { describe, it } = require('node:test');
const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

describe("Slurs", () => {
  const mei = utils.getTestMeiDom('slurs.mei');

  const measure1Layer1Slurs = xpath.evaluateXPathToNodes('//*:measure[1]/*:slur[@layer="1"]', mei);
  const measure1Layer2Slurs = xpath.evaluateXPathToNodes('//*:measure[1]/*:slur[@layer="2"]', mei);
  const measure1Layer1Notes = xpath.evaluateXPathToNodes('//*:measure[1]/*:staff[1]/*:layer[@n="1"]/*:note', mei);
  const measure1Layer2Notes = xpath.evaluateXPathToNodes('//*:measure[1]/*:staff/*:layer[@n="2"]/*:note', mei);

  const measure2Layer1Slurs = xpath.evaluateXPathToNodes('//*:measure[2]/*:slur[@layer="1"]', mei);
  const measure2Layer2Slurs = xpath.evaluateXPathToNodes('//*:measure[2]/*:slur[@layer="2"]', mei);
  const measure2Layer1Notes = xpath.evaluateXPathToNodes('//*:measure[2]/*:staff[1]/*:layer[@n="1"]/*:note', mei);
  const measure2Layer2Notes = xpath.evaluateXPathToNodes('//*:measure[2]/*:staff/*:layer[@n="2"]/*:note', mei);

  it("writes expected number of slurs", () => {
    assert.strictEqual(measure1Layer1Slurs.length, 1);
    assert.strictEqual(measure1Layer2Slurs.length, 2);
    assert.strictEqual(measure2Layer1Slurs.length, 1);
    assert.strictEqual(measure2Layer2Slurs.length, 1);
  });
  it("Writes proper @startid/@endid", () => {
    assert.strictEqual(measure1Layer1Slurs[0].getAttribute('startid'), '#' + measure1Layer1Notes[0].getAttribute('xml:id'));
    assert.strictEqual(measure1Layer1Slurs[0].getAttribute('endid'), '#' + measure1Layer1Notes[2].getAttribute('xml:id'));
    assert.strictEqual(measure1Layer2Slurs[0].getAttribute('startid'), '#' + measure1Layer2Notes[0].getAttribute('xml:id'));
    assert.strictEqual(measure1Layer2Slurs[0].getAttribute('endid'), '#' + measure2Layer2Notes[3].getAttribute('xml:id'));
    assert.strictEqual(measure1Layer2Slurs[1].getAttribute('startid'), '#' + measure1Layer2Notes[1].getAttribute('xml:id'));
    assert.strictEqual(measure1Layer2Slurs[1].getAttribute('endid'), '#' + measure1Layer2Notes[3].getAttribute('xml:id'));

    assert.strictEqual(measure2Layer1Slurs[0].getAttribute('startid'), '#' + measure2Layer1Notes[0].getAttribute('xml:id'));
    assert.strictEqual(measure2Layer1Slurs[0].getAttribute('endid'), '#' + measure2Layer1Notes[3].getAttribute('xml:id'));
    assert.strictEqual(measure2Layer2Slurs[0].getAttribute('startid'), '#' + measure2Layer2Notes[0].getAttribute('xml:id'));
    assert.strictEqual(measure2Layer2Slurs[0].getAttribute('endid'), '#' + measure2Layer2Notes[3].getAttribute('xml:id'));
  });
});

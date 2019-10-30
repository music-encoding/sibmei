"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

const meiLines = utils.getTestMeiDom('lines.mei');

const octavaLines = xpath.evaluateXPath('//*:octave', meiLines);
const trills = xpath.evaluateXPath('//*:trill', meiLines);
const lines = xpath.evaluateXPath('//*:line', meiLines);

describe("Lines", () => {
  /*it("First Octava line has @endid", () => {
    assert.notEqual(octavaLines[0].getAttribute('endid'), null, 'element misses attribute @' + 'endid');
  });
  it("Second Octava line has @tstamp2", () => {
    assert.notEqual(octavaLines[1].getAttribute('tstamp2'), null, 'element misses attribute @' + 'tstamp2');
  });
  it("First trill has @endid", () => {
    assert.notEqual(trills[0].getAttribute('endid'), null, 'element misses attribute @' + 'endid');
  });
  it("Second trill has @tstamp2", () => {
    assert.notEqual(trills[1].getAttribute('tstamp2'), null, 'element misses attribute @' + 'tstamp2');
  });*/
  it("Horizontal lines has @dur.ppq", () => {
    utils.assertElsHasAttr(lines, [0,1,2,3,4,5,6,7], 'dur.ppq');
  });
  it("value of @dur.ppq is a number", () => {
    const horizontalLines = lines.length = 8;
    utils.assertAttrValueFormat(horizontalLines, 'dur.ppq', /^[0-9]*$/);
  });
  //it("Horizontal lines have @tstamp or @endid", () => {});
  //it("Brackets have a line start and a line end symbol", () => {});
  //it("Vertical lines have offset", () => {});
});

"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

const meiLines = utils.getTestMeiDom('lines.mei');

const octavaLines = xpath.evaluateXPath('//*:octave', meiLines);
const trills = xpath.evaluateXPath('//*:trill', meiLines);
const lines = xpath.evaluateXPath('//*:line', meiLines);

describe("Lines", () => {
  it("First Octava line has @endid", () => {
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
  });
  it("First three <line> elements have form: solid, dashed, dotted", () =>{
    assert.strictEqual(lines[0].getAttribute('form'),'solid','First line has no @form=solid!');
    assert.strictEqual(lines[1].getAttribute('form'),'dashed','First line has no @form=dashed!');
    assert.strictEqual(lines[2].getAttribute('form'),'dotted','First line has no @form=dotted!');
  });
  it("Last two <line> elements have form: solid, dashed", () =>{
    assert.strictEqual(lines[11].getAttribute('form'),'solid','Penultimate line has no @form=solid!');
    assert.strictEqual(lines[12].getAttribute('form'),'dashed','Last line has no @form=dashed!');
  });
  it("Brackets have a line start and a line end symbol", () => {
    const brackets = [lines[4],lines[6],lines[9],lines[10]];
    const startBracktes = [lines[3],lines[5]];
    const endBracktes = [lines[7],lines[8]];
    utils.assertHasAttr(brackets, "startsym");
    utils.assertHasAttr(brackets, "endsym");
    utils.assertHasAttr(startBracktes, "startsym");
    utils.assertHasAttr(endBracktes, "endsym");
  });
  it("Horizontal lines has @dur.ppq", () => {
    utils.assertElsHasAttr(lines, [0,1,2,3,4,5,6,7,8], 'dur.ppq');
  });
  it("value of @dur.ppq is a number", () => {
    var horizontalLines = lines;
    horizontalLines = horizontalLines.length = 9;
    utils.assertAttrValueFormat(horizontalLines, 'dur.ppq', /^[0-9]*$/);
  });
  it("Lines have @startid and @endid", () => {
    utils.assertHasAttr(lines, "startid");
    utils.assertHasAttr(lines, "endid");
  });
});

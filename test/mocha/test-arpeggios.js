"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

describe("Arpeggios", () => {
  const mei = utils.getTestMeiDom('arpeggios.mei');

  it("writes 3 arpeggios in each of the 3 measures", () => {
    assert.strictEqual(xpath.evaluateXPath('//*:arpeg', mei).length, 9);
  });
  it("writes arpeggios with up arrow on beat 2 of each measure", () => {
    const upArpeggiosOnBeat2 = xpath.evaluateXPath(
      '//*:arpeg[@arrow="true"][@tstamp="2"][@order="up"]', mei
    );
    assert.strictEqual(upArpeggiosOnBeat2.length, 3);
  });
  it("writes arpeggios with down arrow on beat 3 of each measure", () => {
    const downArpeggiosOnBeat3 = xpath.evaluateXPath(
      '//*:arpeg[@arrow="true"][@tstamp="3"][@order="down"]', mei
    );
    assert.strictEqual(downArpeggiosOnBeat3.length, 3);
  });
  it("writes arrowless arpeggios on beat 4 of each measures", () => {
    const arrowlessArpeggionsOnBeat4 = xpath.evaluateXPath(
      '//*:arpeg[@arrow="false"][@tstamp="4"][not(@order)]', mei
    )
    assert.strictEqual(arrowlessArpeggionsOnBeat4.length, 3);
  });
});

"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

describe("Arpeggios", () => {
  const mei = utils.getTestMeiDom('arpeggios.mei');

  it("writes 3 arpeggios in each of the 3 measures", () => {
    assert.strictEqual(9, xpath.evaluateXPath('//*:arpeg', mei).length);
  });
  it("writes arpeggios with up arrow on beat 2 of each measure", () => {
    assert.strictEqual(3, xpath.evaluateXPath(
      '//*:arpeg[@arrow="true"][@tstamp="2"][@order="up"]', mei
    ).length);
  });
  it("writes arpeggios with down arrow on beat 3 of each measure", () => {
    assert.strictEqual(3, xpath.evaluateXPath(
      '//*:arpeg[@arrow="true"][@tstamp="3"][@order="down"]', mei
    ).length);
  });
  it("writes arrowless arpeggios on beat 4 of each measures", () => {
    assert.strictEqual(3, xpath.evaluateXPath(
      '//*:arpeg[@arrow="false"][@tstamp="4"][not(@order)]', mei
    ).length);
  });
});

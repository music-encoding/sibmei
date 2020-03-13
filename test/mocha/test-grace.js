"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

describe("Grace notes", () => {
  const mei = utils.getTestMeiDom('grace.mei');

  it("handles grace notes before tuplet and beams", () => {
    assert.deepEqual(
      xpath.evaluateXPath(
        '//*:measure[@n="1"]/*:staff[1]/*:layer[1]/*', mei
      ).map(el => el.tagName),
      ["note", "tuplet", "note", "beam", "note", "tuplet"]
    );
  });
});

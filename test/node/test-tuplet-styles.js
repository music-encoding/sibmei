"use strict";

const { describe, it } = require('node:test');
const assert = require('assert');
const xpath = require("fontoxpath");
const utils = require("./utils");

const mei = utils.getTestMeiDom("tuplet-styles.mei");

function tupletInfo(tuplet) {
  const measure = xpath.evaluateXPath("ancestor::*:measure[1]", tuplet);
  const staff = xpath.evaluateXPath("ancestor::*:staff", tuplet);

  return `staff ${staff.getAttribute("n")}, measure ${measure.getAttribute("n")}`
}

describe("Tuplet styles", function () {
  it("writes no bracket information for automatic brackets where it is not known if the bracket is drawn", function () {
    xpath.evaluateXPath("//*:staff[@n='1']//*[self::*:tuplet or self::*:tupletSpan]", mei)
      .forEach(tuplet => assert.strictEqual(tuplet.getAttribute('bracket.visible'), null, tupletInfo(tuplet)));
  });
  it("writes bracket.visible='false' where it is known that the bracket is not shown", function () {
    xpath.evaluateXPath("//*:staff[@n='2']//*[self::*:tuplet or self::*:tupletSpan]", mei)
      .forEach(tuplet => assert.strictEqual(tuplet.getAttribute('bracket.visible'), "false", tupletInfo(tuplet)));
  });
  it("writes bracket.visible='true' where it is known that the bracket is shown", function () {
    xpath.evaluateXPath("//*:staff[@n='3']//*[self::*:tuplet or self::*:tupletSpan]", mei)
      .forEach(tuplet => assert.strictEqual(tuplet.getAttribute('bracket.visible'), "true", tupletInfo(tuplet)));
  });

  it("writes no number visibility information for automatic brackets where it is not known if the number is shown", function () {
    xpath.evaluateXPath("//*:measure[@n='1']//*[self::*:tuplet or self::*:tupletSpan]", mei)
      .forEach(tuplet => assert.strictEqual(tuplet.getAttribute('num.visible'), null, tupletInfo(tuplet)));
  });
  it("writes num.visible='false' where we know that the number is not shown", function () {
    xpath.evaluateXPath("//*:measure[@n='2']//*[self::*:tuplet or self::*:tupletSpan]", mei)
      .forEach(tuplet => assert.strictEqual(tuplet.getAttribute('num.visible'), 'false', tupletInfo(tuplet)));
  });
  it("writes num.visible='true' where we know that the number is shown", function () {
    xpath.evaluateXPath("//*:measure[@n='3']//*[self::*:tuplet or self::*:tupletSpan]", mei)
      .forEach(tuplet => assert.strictEqual(tuplet.getAttribute('num.visible'), 'true', tupletInfo(tuplet)));
  });

  it("writes num.format='count' where we know that a simple number is shown", function () {
    xpath.evaluateXPath("//*:measure[@n='1']//*[self::*:tuplet or self::*:tupletSpan]", mei)
      .forEach(tuplet => assert.strictEqual(tuplet.getAttribute('num.format'), 'count', tupletInfo(tuplet)));
  });
  it("writes no @num.format where no number is displayed", function () {
    xpath.evaluateXPath("//*:measure[@n='2']//*[self::*:tuplet or self::*:tupletSpan]", mei)
      .forEach(tuplet => assert.strictEqual(tuplet.getAttribute('num.format'), null, tupletInfo(tuplet)));
  });
  it("writes num.format='ratio'", function () {
    xpath.evaluateXPath("//*:measure[@n='3']//*[self::*:tuplet or self::*:tupletSpan]", mei)
      .forEach(tuplet => assert.strictEqual(tuplet.getAttribute('num.format'), 'ratio', tupletInfo(tuplet)));
  });
  it("writes no @num.format for tuplets displaying a note on the right side of the ratio", function () {
    // Waiting for https://github.com/music-encoding/music-encoding/issues/661
    // to be addressed.
    xpath.evaluateXPath("//*:measure[@n='4']//*[self::*:tuplet or self::*:tupletSpan]", mei)
      .forEach(tuplet => assert.strictEqual(tuplet.getAttribute('num.format'), null, tupletInfo(tuplet)));
  });
});

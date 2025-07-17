"use strict";

const { describe, it } = require('node:test');
const assert = require('assert');
const xpath = require("fontoxpath");
const utils = require("./utils");

describe("Lyrics styles", () => {
  const mei = utils.getTestMeiDom("lyrics-styles.mei");

  it("creates verses with proper verse number, or no @n otherwise", () => {
    xpath.evaluateXPath("//*:syl", mei)
      .forEach(syl => {
        // The text of all our test verse lyric items is of the form "verseX",
        // where X is the verse number
        const versePattern = /^.*verse(\d)$/i;
        const expectedNAttribute = syl.textContent.match(versePattern)
          ? syl.textContent.replace(versePattern, "$1")
          : null;
        assert.strictEqual(syl.parentNode.getAttribute("n"), expectedNAttribute, 'Wrong verse/@n for lyric item ' + syl.textContent);
      });
  });

  it("writes <refrain> for chorus style text and <verse> for all the others", function () {
    xpath.evaluateXPath("//*:syl", mei)
      .forEach(syl => {
        const expectedParentElement = syl.textContent === "chorus" ? "refrain" : "verse";
        assert.strictEqual(syl.parentNode.localName, expectedParentElement, "wrong parent for lyric item " + syl.textContent);
      });
  });
});

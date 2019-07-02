"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

function assertAttrOnElements(elements, indices, attName, expectedValue) {
  for (let i = 0; i < elements.length; i += 1) {
    const actualValue = elements[i].getAttribute(attName);
    const elementDescription = 'element index ' + i + ' ("' + elements[i].innerHTML + '")';
    if (indices.indexOf(i) >= 0) {
      assert.strictEqual(actualValue, expectedValue, 'value not found on ' + elementDescription);
    } else {
      assert.notEqual(actualValue, expectedValue, 'value unexpectedly found on ' + elementDescription);
    }
  }
}

describe("Lyrics", () => {
  const mei = utils.getTestMeiDom('lyrics.mei');
  const syls = xpath.evaluateXPath('//*:syl', mei);

  describe("writes an elision", () => {
    const note1 = xpath.evaluateXPathToNodes('(//*:note)[1]', mei)[0];
    const note1Syls = xpath.evaluateXPathToNodes('.//*:syl', note1);
    it("exports 2 syllables for elisions", () =>
      assert.strictEqual(note1Syls.length, 2)
    );
    it("sets @con='b' on first syl, but not any others", () => {
      assert.strictEqual(note1Syls[0].getAttribute('con'), 'b');
      const sylsWithCon = xpath.evaluateXPathToNodes('.//*:syl[@con="b"]', note1);
      assert.strictEqual(sylsWithCon.length, 1);
    });
    it("creates correct character entities on elisions", function() {
      assert.strictEqual(syls[13].firstChild._data, "n'u");
    });
  });

  describe("wordpos", () => {
    it("marks initial syllables (@wordpos='i')", () => {
      assertAttrOnElements(syls, [1, 5, 7, 11], 'wordpos', 'i');
    });
    it("marks medial syllables (@wordpos='m')", () => {
      assertAttrOnElements(syls, [2, 8], 'wordpos', 'm');
    });
    it("marks terminal syllables (@wordpos='t')", () => {
      assertAttrOnElements(syls, [3, 6, 9, 12], 'wordpos', 't');
    });
    it("handles single syllable words (omit @wordpos)", () => {
      assertAttrOnElements(syls, [0, 4, 10, 13, 14], 'wordpos', null);
    });
  });

  describe("con", () => {
    it("marks dashes (@con='d')", () => {
      assertAttrOnElements(syls, [1, 2, 5, 7, 8, 11], 'con', 'd');
    });
    it("marks syllable extensions (undescore, @con='u')", () => {
      assertAttrOnElements(syls, [10, 12], 'con', 'u');
    });
    it("marks syllable elisions (breve, @con='b')", () => {
      assertAttrOnElements(syls, [0, 13], 'con', 'b');
    });
  });
});

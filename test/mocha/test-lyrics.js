"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

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
      assert.strictEqual(syls[13].textContent, "n'u");
    });
  });

  describe("wordpos", () => {
    it("marks initial syllables (@wordpos='i')", () => {
      utils.assertAttrOnElements(syls, [1, 5, 7, 11, 17, 19, 22, 27, 29], 'wordpos', 'i');
    });
    it("marks medial syllables (@wordpos='m')", () => {
      utils.assertAttrOnElements(syls, [2, 8, 20, 23, 30], 'wordpos', 'm');
    });
    it("marks terminal syllables (@wordpos='t')", () => {
      utils.assertAttrOnElements(syls, [3, 6, 9, 12, 18, 21, 24, 28, 31], 'wordpos', 't');
    });
    it("handles single syllable words (omit @wordpos)", () => {
      utils.assertAttrOnElements(syls, [0, 4, 10, 13, 14, 15, 16, 25, 26, 32, 33, 34, 35], 'wordpos', null);
    });
  });

  describe("con", () => {
    it("marks dashes (@con='d')", () => {
      utils.assertAttrOnElements(syls, [1, 2, 5, 7, 8, 11, 17, 19, 20, 22, 23, 27, 29, 30], 'con', 'd');
    });
    it("marks syllable extensions (undescore, @con='u')", () => {
      utils.assertAttrOnElements(syls, [10, 12], 'con', 'u');
    });
    it("marks syllable elisions (breve, @con='b')", () => {
      utils.assertAttrOnElements(syls, [0, 13, 18, 31, 33, 34], 'con', 'b');
    });
  });

  describe("chords", () => {
    it("adds <syl> to <chord>s", () => {
      assert.strictEqual(syls[4].parentNode.nodeName, 'verse');
      assert.strictEqual(syls[4].parentNode.parentNode.nodeName, 'chord');
    });
  });
});

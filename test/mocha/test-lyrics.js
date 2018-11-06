"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

function assertAttrOnElements(elements, indices, attName, attValue) {
  for (const i of indices) {
    assert.strictEqual(
      attValue, elements[i].getAttribute(attName),
      'failed on element index ' + i + ' ("' + elements[i].innerHTML + '")'
    );
  }
}

describe("Lyrics", () => {
  const mei = utils.getTestMeiDom('lyrics.mei');
  const syls = xpath.evaluateXPath('//*:syl', mei);

  describe("writes an elision", () => {
    const elisionSyls = xpath.evaluateXPathToNodes('(//*:note)[1]//*:syl', mei);
    it("exports 2 syllables for elisions", () =>
      assert.strictEqual(2, elisionSyls.length)
    );
    it("sets @con='b' on first syl, but not any others", () => {
      assert.strictEqual('b', elisionSyls[0].getAttribute('con'));
      assert.strictEqual(1, xpath.evaluateXPathToNodes(
        '//*:syl[@con="b"]', mei
      ).length);
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
      assertAttrOnElements(syls, [0, 4, 10], 'wordpos', null);
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
      assertAttrOnElements(syls, [0], 'con', 'b');
    });
  });
});

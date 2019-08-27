"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');


const meiHead = utils.getTestMeiDom('header.mei');
const meiMdivs = utils.getTestMeiDom('mdivs.mei');

describe("Head 4.0", () => {
  it("correct meiversion is set", () => {
    assert.strictEqual(xpath.evaluateXPath('/*:mei/@meiversion', meiHead), "4.0.1");
  });
  it("the parent of <work> is <workList>", () => {
    assert.strictEqual(xpath.evaluateXPath('//*:work', meiHead).parentNode.localName, "workList");
  });
  it("<encodingDesc> follows <fileDesc>", () => {
    const fileDescNextSib = xpath.evaluateXPath('//*:fileDesc/following-sibling::element()', meiHead);
    assert.strictEqual(fileDescNextSib[0].localName, "encodingDesc");
  });

  describe("Work description 4.0", () => {
    it("<title> is the first child of <work>", () => {
      const workChild = xpath.evaluateXPath('//*:work/element()[1]', meiHead);
      assert.strictEqual(workChild.localName, "title");
    });
    it("<composer> is the second child of <work>", () => {
      const workChild = xpath.evaluateXPath('//*:work/element()[2]', meiHead);
      assert.strictEqual(workChild.localName, "composer");
    });
    it("<lyricist> is the third child of <work>", () => {
      const workChild = xpath.evaluateXPath('//*:work/element()[3]', meiHead);
      assert.strictEqual(workChild.localName, "lyricist");
    });
    it("<arranger> is the forth child of <work>", () => {
      const workChild = xpath.evaluateXPath('//*:work/element()[4]', meiHead);
      assert.strictEqual(workChild.localName, "arranger");
    });
  });
});

describe("Mdiv", () => {
  it("<annot> is inside <score>", () => {
    const annots = xpath.evaluateXPath('//*:annot', meiMdivs);
    for (let i = annots.length; i = 0; i -= 1 ) {
        assert.strictEqual(annots[i].parentNode.localName, "score");
    }
  });
  it("the number of <mDiv> elements is equal to the number of <work> elements", () => {
    const mdivs = xpath.evaluateXPath('//*:mdiv', meiMdivs);
    const workEls = xpath.evaluateXPath('//*:workList/*:work', meiMdivs);
    assert.strictEqual(mdivs.length, workEls.length);
  });
});

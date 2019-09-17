"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');


const meiHead = utils.getTestMeiDom('header.mei');
const meiMdivs = utils.getTestMeiDom('mdivs.mei');
const meiNRsmall = utils.getTestMeiDom('nrsmall.mei');
const meiBarRests = utils.getTestMeiDom('barrests.mei');
const meiSymbols = utils.getTestMeiDom('symbols.mei');

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

const notes = xpath.evaluateXPath('//*[local-name()!="chord"]/*:note', meiNRsmall);
const rests = xpath.evaluateXPath('//*:rest', meiNRsmall);
const chords = xpath.evaluateXPath('//*:chord', meiNRsmall);

const nrs = [notes, rests, chords];
const smallnrs = [[1, 10], [1], [1]];
const elnames = ["note", "rest", "chord"];

for(let i = 0; i < nrs.length; i++) {
  describe(elnames[i] + " attributes 4.0", () => {
    it("has @dur.ppq attribute", () => {
      utils.assertHasAttr(nrs[i], 'dur.ppq');
    });
    it("value of @dur.ppq is a number", () => {
      utils.assertAttrValueFormat(nrs[i], 'dur.ppq', /^[0-9]*$/);
    });
    it("has @tstamp.real attribute", () => {
      utils.assertHasAttr(nrs[i], 'tstamp.real');
    });
    it("value of @tstamp.real is isotime", () => {
      utils.assertAttrValueFormat(nrs[i], 'tstamp.real', /[0-9][0-9]:[0-9][0-9]:[0-9][0-9](\.?[0-9]*)?/);
    });
    it("has @fontsize", () => {
      utils.assertElsHasAttr(nrs[i], smallnrs[i], 'fontsize');
    });
    it("value of @fontsize is 'small'", () => {
      utils.assertAttrOnElements(nrs[i], smallnrs[i], 'fontsize', 'small');
    });
  });
}

describe("Measure rests and repeats", () => {
  it("First measure has <mRest>." ,() => {
    assert.strictEqual(xpath.evaluateXPath('//*:measure[@n="1"]//*:layer/*', meiBarRests).localName, 'mRest');
  });
  it("Third measure has <mRpt>", () => {
    assert.strictEqual(xpath.evaluateXPath('//*:measure[@n="3"]//*:layer/*', meiBarRests).localName, 'mRpt');
  });
  it("Fifth measure has <mRpt2>", () => {
    assert.strictEqual(xpath.evaluateXPath('//*:measure[@n="5"]//*:layer/*', meiBarRests).localName, 'mRpt2');
  });
  it("Eighth measure has <multiRpt>", () => {
    assert.strictEqual(xpath.evaluateXPath('//*:measure[@n="8"]//*:layer/*', meiBarRests).localName, 'multiRpt');
  });
  it("<multiRpt> has num='4'", () => {
    assert.strictEqual(xpath.evaluateXPath('//*:measure[@n="8"]//*:multiRpt', meiBarRests).getAttribute('num'), '4');
  });
});

describe("Updated attributes for symbols (mordents and turns)", () => {
  const mordents = xpath.evaluateXPath('//*:mordent', meiSymbols);
  const turns = xpath.evaluateXPath('//*:turn', meiSymbols);
  it("Mordent has @form='upper'", () => {
    utils.assertAttrOnElements(mordents, [0], 'form', 'upper');
  });
  it("Inverted mordent has @form='lower'", () => {
    utils.assertAttrOnElements(mordents, [1], 'form', 'lower');
  });
  it("Turn has @form='upper'", () => {
    utils.assertAttrOnElements(turns, [0], 'form', 'upper');
  });
  it("Inverted turn has @form='lower'", () => {
    utils.assertAttrOnElements(turns, [1], 'form', 'lower');
  });
});

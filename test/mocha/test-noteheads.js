"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

const meiNoteHeads = utils.getTestMeiDom('noteheads.mei');
const shapestyle = ['CrossNoteStyle', 'DiamondNoteStyle', 'CrossOrDiamondNoteStyle', 'BlackAndWhiteDiamondNoteStyle', 'SlashedNoteStyle', 'BackSlashedNoteStyle', 'ArrowDownNoteStyle',
                    'ArrowUpNoteStyle', 'InvertedTriangleNoteStyle', 'ShapedNote1NoteStyle', 'ShapedNote2NoteStyle', 'ShapedNote3NoteStyle', 'ShapedNote4StemUpNoteStyle',
                    'ShapedNote4StemDownNoteStyle', 'ShapedNote5NoteStyle', 'ShapedNote6NoteStyle', 'ShapedNote7NoteStyle'];
const headshapeValue = ['x', 'diamond', 'x', 'filldiamond', 'addslash', 'addbackslash', 'isotriangle', 'isotriangle',
                        'isotriangle', 'isotriangle', 'semicircle', 'diamond', 'rtriangle', 'rtriangle', '', 'square', 'piewedge'];

describe("Note heads", () => {
  for(let i = 0; i < 17; i++) {
    it(shapestyle[i] + " has @head.shape= '" + headshapeValue[i] + "'", () => {
      assert.equal(xpath.evaluateXPath('//*:measure[@n="' + (i+1) + '"]//*:layer/*:note[1]/@head.shape', meiNoteHeads), headshapeValue[i]);
    });
  }
});

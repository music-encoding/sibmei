"use strict";

const assert = require('assert');
const xpath = require('fontoxpath');
const utils = require('./utils');

const mei = utils.getTestMeiDom('tuplet-beams.mei');


function layerStructure(element) {
    const children = [];
    for (const child of xpath.evaluateXPathToNodes("*:note|*:beam|*:tuplet", element)) {
        children.push(child.localName);
        switch (child.localName) {
            case "beam":
            case "tuplet":
                children.push(layerStructure(child));
        }
    }
    return children;
}


describe("Beam-tuplet combinations", function() {
    it("creates a tuplet at the beginning of a beam", function() {
        assert.deepStrictEqual(
            layerStructure(xpath.evaluateXPath("//*:measure[@n='1']//*:layer", mei)),
            [
                "beam", [
                    "tuplet", ["note", "note", "note"],
                    "note", "note", "note", "note",
                ],
            ]
        );
    });
    it("creates a tuplet in the middle of a beam", function() {
        assert.deepStrictEqual(
            layerStructure(xpath.evaluateXPath("//*:measure[@n='2']//*:layer", mei)),
            [
                "beam", [
                    "note", "note",
                    "tuplet", ["note", "note", "note"],
                    "note", "note",
                ],
            ]
        );
    });
    it("creates a tuplet at the end of a beam", function() {
        assert.deepStrictEqual(
            layerStructure(xpath.evaluateXPath("//*:measure[@n='3']//*:layer", mei)),
            [
                "beam", [
                    "note", "note", "note", "note",
                    "tuplet", ["note", "note", "note"],
                ],
            ]
        );
    });
    it("handles beams starting in a tuplet and ending outside of it", function() {
        assert.deepStrictEqual(
            layerStructure(xpath.evaluateXPath("//*:measure[@n='4']//*:layer", mei)),
            [
                "tuplet", [
                    "beam", ["note", "note"],
                    "note",
                ],
                "note",
            ]
        );
        const noteRefs = xpath.evaluateXPath("//*:measure[@n='4']//*:note", mei).map(note => "#" + note.getAttribute("xml:id"));
        const beamSpan = xpath.evaluateXPath("//*:measure[@n='4']//*:beamSpan", mei);
        assert.strictEqual(beamSpan.getAttribute("startid"), noteRefs[2]);
        assert.strictEqual(beamSpan.getAttribute("endid"), noteRefs[3]);
    });
    it("handles beams starting outside a tuplet and ending inside of it", function() {
        assert.deepStrictEqual(
            layerStructure(xpath.evaluateXPath("//*:measure[@n='5']//*:layer", mei)),
            [
                "note",
                "tuplet", [
                    "note",
                    "beam", ["note", "note"],
                ],
            ]
        );
        const noteRefs = xpath.evaluateXPath("//*:measure[@n='5']//*:note", mei).map(note => "#" + note.getAttribute("xml:id"));
        const beamSpan = xpath.evaluateXPath("//*:measure[@n='5']//*:beamSpan", mei);
        assert.strictEqual(beamSpan.getAttribute("startid"), noteRefs[0]);
        assert.strictEqual(beamSpan.getAttribute("endid"), noteRefs[1]);
    });
    it("handles nested tuplets, inner one 'splitting' a beam", function() {
        assert.deepStrictEqual(
            layerStructure(xpath.evaluateXPath("//*:measure[@n='6']//*:layer", mei)),
            [
                "tuplet", [
                    "note",
                    "tuplet", [
                        "note", "note",
                        "beam", ["note", "note"],
                    ],
                ],
            ]
        );
        const noteRefs = xpath.evaluateXPath("//*:measure[@n='6']//*:note", mei).map(note => "#" + note.getAttribute("xml:id"));
        const beamSpan = xpath.evaluateXPath("//*:measure[@n='6']//*:beamSpan", mei);
        assert.strictEqual(beamSpan.getAttribute("startid"), noteRefs[0]);
        assert.strictEqual(beamSpan.getAttribute("endid"), noteRefs[2]);
    });
});
"use strict";

const { describe, it } = require('node:test');
const assert = require('assert');
const xpath = require("fontoxpath");
const utils = require("./utils");

describe("Hairpins", () => {
  const mei = utils.getTestMeiDom("hairpins.mei");

  it("creates crescendos and diminuendos", () => {
    assert.deepEqual(
      xpath
        .evaluateXPath("//*:hairpin", mei)
        .map((el) => el.getAttribute("form")),
      ["cres", "cres", "cres", "cres", "dim", "dim", "dim"]
    );
  });

  it("detects niente", function () {
    assert.deepEqual(
      xpath
        .evaluateXPath("//*:hairpin", mei)
        .map((el) => el.getAttribute("niente") || "false"),
      ["false", "true", "false", "false", "false", "false", "true"]
    );
  });

  it("detects dashed and dotted hairpins", function () {
    assert.deepEqual(
      xpath
        .evaluateXPath("//*:hairpin", mei)
        .map((el) => el.getAttribute("lform") || "solid"),
      ["solid", "solid", "dashed", "dotted", "solid", "solid", "solid"]
    );
  });

  // This should work for MEI 5
  // it("detects hairpins in parentheses", function () {
  //   assert.deepEqual(
  //     xpath
  //       .evaluateXPath("//*:hairpin", mei)
  //       .map((el) => el.getAttribute("enclose") || "none"),
  //     ["none", "none", "none", "none", "none", "paren", "none"]
  //   );
  // });
});

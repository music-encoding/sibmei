"use strict";

const utils = require('./utils');

const mei = utils.getTestMeiDom('lines.mei');

describe("Lines", () => {
  it("matches XPath tests", function() {
    utils.assertXpathAnnotations(mei);
  });
});

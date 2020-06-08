#!/usr/bin/env node

/*
This script checks for any invalid libmei calls or MEI attribute names. It's
intended to help with upgrading to a new MEI version, but it can not catch all
invalid uses of element/attribute combinations.

Run it like:

    npm run analyze

No problems were found if nothing is output.
*/


const fs = require("fs");
const https = require("https");
const parser = require('slimdom-sax-parser');
const path = require("path");
const xpath = require('fontoxpath');

// TODO: Don't hard code the MEI version. Create a global variable that is
// shared with ProcessScore() in ExportProcessors.mss
const meiVersion = "4.0.1";
const schemaUrl = `https://raw.githubusercontent.com/music-encoding/music-encoding/v${meiVersion}/schemata/mei-CMN.rng`;
const directories = {
  src: "src",
  lib: "lib",
}


function reportIssue(filePath, lineIndex, line, message) {
  console.log(`${filePath}:${lineIndex + 1}`);
  console.log(line.replace(/^\s*/, '  '));
  console.log('  ' + message);
}


function analyzeUsage(methods, attributes) {
  console.log('Analyze libmei and attribute usage...');
  for (const fileName of fs.readdirSync(directories.src)) {
    const filePath = path.join(directories.src, fileName);
    const lines = fs.readFileSync(filePath, {encoding: 'utf8'}).split("\n");

    for (let lineIndex = 0; lineIndex < lines.length; lineIndex ++) {
      const line = lines[lineIndex];
      const libmeiCall = line.match(/\blibmei\.([a-zA-Z0-9_]+)\s*(.*)$/);

      if (libmeiCall) {
        const [, methodName, arguments] = libmeiCall;
        switch (methodName) {
          case 'AddAttribute':
          case 'AddAttributeValue':
            const splitArguments = arguments.match(/[^,]+,\s*'([^']+)/);
            if (splitArguments) {
              const attributeName = splitArguments[1];
              if (!(attributes[attributeName] || attributeName.match(/^xmlns/))) {
                reportIssue(filePath, lineIndex, line, "Unknown attribute");
              }
            } else {
              reportIssue(filePath, lineIndex, line, "Can not identify attribute name");
            }
            break;
          default:
            if (!methods[methodName]) {
              reportIssue(filePath, lineIndex, line, "Unknown libmei method");
            }
        }
      }
    }
  }
  console.log('Done');
}


const majorVersion = meiVersion.split(".")[0];
const libmeiPath = path.join(directories.lib, `libmei${majorVersion}.plg`)
const libmeiCode = fs.readFileSync(libmeiPath, {encoding: 'utf8'}).split("\n");
if (!libmeiCode) {
  console.log(libmeiPath + " not found");
  process.exit(1);
}

let libmeiFields = {};
let match;
const methodRegex = /([a-zA-Z0-9_]+)\s*"\(/g;
while (match = methodRegex.exec(libmeiCode)) {
  libmeiFields[match[1]] = true;
}
const globalVarRegex = /Self._property:([a-zA-Z0-9_]+)/g;
while (match = globalVarRegex.exec(libmeiCode)) {
  libmeiFields[match[1]] = true;
}


https.get(schemaUrl, (res) => {
  let data = '';
  console.log('Downloading MEI schema...')

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    let schame;
    try {
      schema = parser.sync(data);
    } catch(e) {
      console.log(schemaUrl);
      console.log(data);
      throw e;
    }

    console.log('Extracting attribute definitions...');
    // TODO: Use saxes right away instead of creating a DOM first and running
    // XPath on it. This is really slow.
    const attributeNames = xpath.evaluateXPath(`
      //*:define[starts-with(@name, 'mei_')]//*:attribute/@name
    `, schema);
    const attributes = {};
    for (const attribute of attributeNames) {
      attributes[attribute] = true;
    }

    analyzeUsage(libmeiFields, attributes);
  });
}).on("error", e => {throw e;});

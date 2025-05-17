// @ts-check

import c from "ansi-colors";
import chokidar from "chokidar";
import * as fs from "fs";
import l from "fancy-log";
import { argv } from "process";
// @ts-ignore
import * as plgconf from "../plgconfig.js";

/**
 * @param {string} src
 * @param {string} dest
 * @param {RegExp} filter
 */
function copy(src, dest, filter) {
  fs.cpSync(src, dest, {filter: (path) => filter.test(path)});
}

/**
 * Converts JavaScript-like *.mss function syntax to *.plg syntax.
 * @param {string} mssCode  Code of an entire *.mss file
 */
function mssToPlg (mssCode) {
  return mssCode
    .split(/\/\/\s*\$end/)
    .filter((functionCode) => functionCode.match(/[^\s]/))
    .map((functionCode) => {
      const [, name, body] = functionCode.match(/function\s+([^ (]+)\s*([\s\S]+})/) || [];
      if (!name) {
        throw new Error("Syntax error: Could not split code into function name and body:\n\n\"" + functionCode + "\"");
      }
      return `${name} "${body}"`;
    })
    .join('\n\n');
}

/**
 * @param {string[]} sourceFiles  source file names
 * @param {string} target  name of target *.plg file
 */
function compile (sourceFiles, target) {
  const bom = "\ufeff";
  const compiledCode = bom + sourceFiles
    .map((filename) => {
      const [,extension] = filename.match(/.+\.([^.]+)$/) || [];
      switch (extension) {
        case "mss":
        case "msd":
          const code = fs.readFileSync(filename, {encoding: "utf8"});
          // *.msd files are raw ManuScript Data files that we copy verbatim
          // *.mss files use JavaScript-ish function syntax we have to compile
          return extension === "msd" ? code : mssToPlg(code);
        default:
          return "";
      }
    })
    // Skip files we ignore
    .filter(code => code)
    .join("\n\n");
  fs.writeFileSync(target, compiledCode, {encoding: "utf16le"});
}

/**
 * @param {string} dir
 */
function fileList (dir) {
  return fs.readdirSync(dir, {encoding: "utf8"})
    .map((file) => dir + "/" + file);
}

function build() {
  l.info(c.blue('Copying "linked" libraries'));
  copy("lib", "build", /\.plg$/);

  const mainSourceFiles = fileList("src");
  const testSourceFiles = fileList("test/sib-test");
  compile(mainSourceFiles, "build/sibmei4.plg");
  compile(testSourceFiles, "build/Testsibmei4.plg");

  l.info(c.blue("Copying test data"));
  const destPath = plgconf.plgPath + '/' + plgconf.plgCategory + '/sibmeiTestSibs';
  copy("test/sibmeiTestSibs", destPath, /\.sib$/);
}

build();

if (argv[2] === "--watch") {
  l.info(c.blue("Watching files for changes"));
  chokidar.watch(["src", "test", "lib"], {ignoreInitial: true}).on('all', build);
}

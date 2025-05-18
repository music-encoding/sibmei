// @ts-check

import c from "ansi-colors";
import chokidar from "chokidar";
import * as fs from "fs";
import * as path from "path";
import l from "fancy-log";
import { argv } from "process";
import pckg from "../package.json" with {type: "json"};
import { fileURLToPath } from "url";
const {name} = pckg;
if (!name) {
  throw new Error("package.json must provide the plg base file name as `name`");
}

// byte order mark
const BOM = "\ufeff";

/**
 * @param {string} src
 * @param {string} dest
 * @param {string} extension
 */
function copy(src, dest, extension, prefix = "") {
  for (const filePath of fileList(src)) {
    if (filePath.endsWith(extension)) {
      fs.copyFileSync(filePath, path.join(dest, prefix + path.basename(filePath)));
    }
  }
}

/**
 * Converts JavaScript-like *.mss function syntax to *.plg syntax.
 * @param {string} mssCode  Code of an entire *.mss file
 */
function mssToPlg(mssCode) {
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
function buildPlg(sourceFiles, target) {
  fs.writeFileSync(target, `${BOM}{\n${compile(sourceFiles)}\n}`, {encoding: "utf16le"});
}

/**
 * @param {string[]} sourceFiles  source file names
 */
function compile(sourceFiles) {
  const compiledFiles = [];
  for (const filename of sourceFiles) {
    const [,extension] = filename.match(/.+\.([^.]+)$/) || [];
    switch (extension) {
      case "mss":
      case "msd":
        const code = fs.readFileSync(filename, {encoding: "utf8"});
        // *.msd files are raw ManuScript Data files that we copy verbatim
        // *.mss files use JavaScript-ish function syntax we have to compile
        compiledFiles.push(extension === "msd" ? code : mssToPlg(code));
    }
  }
  return compiledFiles.join("\n\n");
}

/**
 * @param {string} dir
 */
function fileList(dir) {
  return fs.readdirSync(dir, {encoding: "utf8"})
    .map((file) => dir + "/" + file);
}

function build() {
  l.info(c.blue('Copying lib plugins'));
  fs.mkdirSync("build/release", {recursive: true});
  fs.mkdirSync("build/test/sibmeiTestSibs", {recursive: true});
  const prefix = name + "_";
  copy("lib", "build/release", ".plg", prefix);
  copy("lib", "build/test", ".plg", prefix);
  copy("test", "build/test", ".plg", prefix);
  l.info(c.blue("Copying test data"));
  copy("test/sibmeiTestSibs", "build/test/sibmeiTestSibs", ".sib");

  const mainSourceFiles = fileList("src");
  const testSourceFiles = fileList("test/sib-test");
  l.info(c.blue("Building plugin"));
  buildPlg(mainSourceFiles, `build/release/${name}.plg`);
  l.info(c.blue("Building test plugin"));
  buildPlg([...mainSourceFiles, ...testSourceFiles], `build/test/${name}.plg`);
}

build();

if (argv[2] === "--watch") {
  l.info(c.blue("Watching files for changes"));
  chokidar.watch(["src", "test", "lib"], {ignoreInitial: true}).on('all', build);
}

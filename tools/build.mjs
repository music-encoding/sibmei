// @ts-check

import c from "ansi-colors";
import chokidar from "chokidar";
import * as fs from "fs";
import * as path from "path";
import l from "fancy-log";
import { argv } from "process";
import pckg from "../package.json" with {type: "json"};

const { name, version, sibmei: { meiVersion } } = pckg;
const GLOBALS = `
  MainPlgBaseName "${name}"
  PluginVersion "${version}"
  MeiVersion "${meiVersion}"
`;

// byte order mark
const BOM = "\ufeff";

const sourceExtensions = new Set(["msd", "mss", "plg"]);

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
  fs.writeFileSync(target, `${BOM}{
    ${compile(sourceFiles)}
    ${GLOBALS}
  }`, {encoding: "utf16le"});
}

/**
 * Iterates over all *.plg files in `sourceDir`, compiles (to add `GLOBALS`) and
 * writes the compiled files to `targetDir` as UTF-16, adding a sibmei version
 * dependent prefix so that multiple sibmei instances together with their
 * companion plugins can coexist in the Sibelius plugin folder without naming
 * conflicts.
 *
 * @param {string} sourceDir
 * @param {string} targetDir
 */
function buildCompanionPlgs(sourceDir, targetDir) {
  for (const fileName of fs.readdirSync(sourceDir, {encoding: "utf8"})) {
    const targetPath = path.join(
      targetDir,
      // Do not prefix libmei with sibmei
      (fileName.startsWith("libmei") ? "" : name + "_") + fileName
    );
    if (fileName.endsWith(".plg")) {
      buildPlg([path.join(sourceDir, fileName)], targetPath);
    }
  }
}

/**
 * @param {string[]} sourceFiles  Source file names.  Any file names with
 * extensions other than msd, mss and plg are ignored.
 */
function compile(sourceFiles) {
  const compiledFiles = [];
  for (const filename of sourceFiles) {
    const [,extension] = filename.match(/.+\.([^.]+)$/) || [];
    if (!sourceExtensions.has(extension)) {
      continue;
    }
    const code = fs.readFileSync(filename, {encoding: "utf8"});
    compiledFiles.push((() => {
      switch (extension) {
        case "mss":
          // *.mss files use JavaScript-ish function syntax we have to compile
          return mssToPlg(code);
        case "msd":
          // *.msd files are raw ManuScript Data files that we copy verbatim
          return code;
        case "plg":
          // *.plg is similar to *.msd, but has wrapping braces, which we strip
          return code.replace(/\s*{([\s\S]*)}/, "$1");
      }
    })());
  }
  return compiledFiles.join("\n\n");
}

/**
 * @param {string} dir
 */
function fileList(dir) {
  return fs.readdirSync(dir, {encoding: "utf8"})
    .map((file) => path.join(dir, file));
}

function build() {
  l.info(c.blue("Compiling companion plugins"));
  fs.mkdirSync("build/release", {recursive: true});
  fs.mkdirSync("build/develop/sibmeiTestSibs", {recursive: true});
  buildCompanionPlgs("lib", "build/release");
  buildCompanionPlgs("lib", "build/develop");
  buildCompanionPlgs("test", "build/develop");

  const mainSourceFiles = fileList("src");
  const testSourceFiles = fileList("test/sib-test");
  l.info(c.blue("Compiling release build"));
  buildPlg(mainSourceFiles, `build/release/${name}.plg`);
  l.info(c.blue("Compiling development build"));
  buildPlg([...mainSourceFiles, ...testSourceFiles], `build/develop/${name}.plg`);

  l.info(c.blue("Copying test data"));
  for (const filePath of fileList("test/sibmeiTestSibs")) {
    if (filePath.endsWith(".sib")) {
      fs.copyFileSync(filePath, path.join("build/develop/sibmeiTestSibs", path.basename(filePath)));
    }
  }

  console.log("");
}

build();

if (argv[2] === "--watch") {
  l.info(c.blue("Watching files for changes\n"));
  chokidar.watch(["src", "test", "lib", "tools/build.mjs"], {ignoreInitial: true}).on('all', build);
}

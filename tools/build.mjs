// @ts-check

import chokidar from "chokidar";
import * as fs from "fs";
import * as path from "path";
import { argv } from "process";
import pckg from "../package.json" with { type: "json" };
import { getSchema, SCHEMA_URL } from "./schema.mjs";

const {
  version,
  sibmei: { meiVersion },
} = pckg;
const majorVersion = version.split(".")[0];
const GLOBALS = `
  MainPlgBaseName "sibmei${majorVersion}"
  PluginVersion "${version}"
  MeiVersion "${meiVersion}"
  SchemaUrl "${SCHEMA_URL}"
`;

// byte order mark
const BOM = "\ufeff";

const sourceExtensions = new Set(["msd", "mss", "plg"]);

/**
 * Converts JavaScript-like *.mss function syntax to *.plg syntax.
 * @param {string} mssCode  Code of an entire *.mss file
 * @param {string} filename  mss file name
 */
function mssToPlg(mssCode, filename) {
  return mssCode
    .split(/\/\/\s*\$end/)
    .filter((functionCode) => functionCode.match(/[^\s]/))
    .map((functionCode) => {
      const [, functionName, body] = functionCode.match(/function\s+([^ (]+)\s*([\s\S]+})/) || [];
      if (!functionName) {
        throw new Error(
          'Syntax error: Could not split code into function name and body:\n\n"' +
            functionCode +
            '"'
        );
      }
      // Add module information so it's easier to find the source file of a
      // function when an error is reported.
      const bodyWithModuleInfo = body.match(/{\s*\/\/\s*\$module/)
        ? body
        : body.replace("{", `{\n    //$module(${filename})`);
      return `${functionName} "${bodyWithModuleInfo}"`;
    })
    .join("\n\n");
}

/**
 * @param {string[]} sourceFiles  source file names
 * @param {string} target  name of target *.plg file
 * @param {boolean} [develop]  signals whether to include data only needed for
 * development
 */
async function buildPlg(sourceFiles, target, develop = false) {
  fs.writeFileSync(
    target,
    `${BOM}{
    ${compile(sourceFiles)}
    ${GLOBALS}
    LegalElements ${await compileLegalElements(develop)}
  }`,
    { encoding: "utf16le" }
  );
}

/**
 * @param {boolean} develop  For the release version, only a list of legal
 * elements is compiled. For the development version, every legal element has a
 * list of its legal attributes and children attached.
 */
async function compileLegalElements(develop) {
  const schema = await getSchema();
  if (!develop) {
    return serializeAsTreeNodeList(schema.elements.keys());
  }
  return `{\n${[...schema.elements.entries()]
    .map(([elementName, properties]) => {
      return `"${elementName}" {
      attributes ${serializeAsTreeNodeList(properties.attributes)}
      children ${serializeAsTreeNodeList(properties.children)}
    }`;
    })
    .join("\n")}
  }`;
}

/**
 * @param {Iterable<string>} list
 */
function serializeAsTreeNodeList(list) {
  return `{${[...list].map((item) => `"${item}"`).join(" ")}}`;
}

/**
 * Iterates over all *.plg files in `sourceDir`, compiles (to add `GLOBALS`) and
 * writes the compiled files to `targetDir` as UTF-16, adding a sibmei version
 * dependent prefix so that multiple sibmei instances (exporting to different
 * MEI versions) together with their companion plugins can coexist in the
 * Sibelius plugin folder without naming conflicts.
 *
 * @param {string} sourceDir
 * @param {string} targetDir
 */
function buildCompanionPlgs(sourceDir, targetDir) {
  for (const fileName of fs.readdirSync(sourceDir, { encoding: "utf8" })) {
    const targetPath = path.join(targetDir, `sibmei${majorVersion}_${fileName}`);
    if (fileName.endsWith(".plg")) {
      buildPlg([path.join(sourceDir, fileName)], targetPath, false);
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
    const [, extension] = filename.match(/.+\.([^.]+)$/) || [];
    if (!sourceExtensions.has(extension)) {
      continue;
    }
    const code = fs.readFileSync(filename, { encoding: "utf8" });
    compiledFiles.push(
      (() => {
        switch (extension) {
          case "mss":
            // *.mss files use JavaScript-ish function syntax we have to compile
            return mssToPlg(code, path.basename(filename));
          case "msd":
            // *.msd files are raw ManuScript Data files that we copy verbatim
            return code;
          case "plg":
            // *.plg is similar to *.msd, but has wrapping braces, which we strip
            return code.replace(/\s*{([\s\S]*)}/, "$1");
        }
      })()
    );
  }
  return compiledFiles.join("\n\n");
}

/**
 * @param {string} dir
 */
function fileList(dir) {
  return fs.readdirSync(dir, { encoding: "utf8" }).map((file) => path.join(dir, file));
}

/**
 * @param {string} message
 */
function info(message) {
  const time = new Date().toLocaleTimeString("en", { hour12: false });
  console.log(`[${time}] \x1b[34m${message}\x1b[0m`);
}

async function build() {
  info("Compiling companion plugins");
  fs.mkdirSync(path.join("build", "release"), { recursive: true });
  fs.mkdirSync(path.join("build", "develop", "sibmeiTestSibs"), { recursive: true });
  buildCompanionPlgs("lib", path.join("build", "release"));
  buildCompanionPlgs("lib", path.join("build", "develop"));
  buildCompanionPlgs("test", path.join("build", "develop"));

  const mainSourceFiles = fileList("src");
  const testSourceFiles = fileList(path.join("test", "sib-test"));
  info("Compiling release build");
  await buildPlg(mainSourceFiles, `${path.join("build", "release", "sibmei")}${majorVersion}.plg`);
  info("Compiling development build");
  await buildPlg(
    [...mainSourceFiles, ...testSourceFiles],
    `${path.join("build", "develop", "sibmei")}${majorVersion}.plg`,
    true
  );

  info("Copying test data");
  for (const filePath of fileList(path.join("test", "sibmeiTestSibs"))) {
    if (filePath.endsWith(".sib")) {
      fs.copyFileSync(
        filePath,
        path.join("build", "develop", "sibmeiTestSibs", path.basename(filePath))
      );
    }
  }

  console.log("");
}

build().finally(() => {
  if (argv[2] === "--watch") {
    info("Watching files for changes\n");
    chokidar.watch(["src", "test", "lib"], { ignoreInitial: true }).on("all", () => {
      build().catch((e) => console.error(e, "\n"));
    });
  }
});

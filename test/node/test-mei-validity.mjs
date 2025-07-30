// @ts-check
import assert from "node:assert";
import { spawnSync } from "node:child_process";
import { describe, it } from "node:test";
import utils from "./utils.js";
import { getSchemaFile } from "../../tools/schema.mjs";
import path from "node:path";

const jingIsAvailable =
  spawnSync(process.platform === "win32" ? "where" : "which", ["jing"]).status === 0;

if (!jingIsAvailable) {
  console.log(`\x1b[43m  Command "jing" must be on the path for validation of test files. Installation:
    * WSL/Ubuntu: apt install jing
    * Mac with homebrew: brew install jing-trang\x1b[0m`);
} else {
  const rngPath = await getSchemaFile();
  const testFileNames = utils.getExportedTestFileNames();
  const testFilePaths = testFileNames.map((file) =>
    path.join("build", "develop", "sibmeiTestSibs", file)
  );
  describe("RelaxNG validation", () => {
    const { stdout, status } = spawnSync("jing", [rngPath, ...testFilePaths], {
      encoding: "utf-8",
    });
    if (status === 0) return;
    /** @type {{[fileName: string]: string[]}} */
    const messagesByFile = {};
    for (const [, fileName, message] of stdout.matchAll(
      // Format of a Jing output line is:
      // /path/to/file.mei:12:34: error: attribute "foo" not allowed here; expected attribute "bar"
      /.*?([^/]+\.mei):(\d+:\d+:[\s\S\n]+?)\n/g
    )) {
      (messagesByFile[fileName] ||= []).push(message);
    }
    for (const fileName of testFileNames) {
      const messages = messagesByFile[fileName] || [];
      it(fileName, () => assert.ok(messages.length === 0, messages.join("\n")));
    }
  });
}

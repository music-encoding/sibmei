// @ts-check

import fs from "fs";
import https from "https";
import parser from "slimdom-sax-parser";
import path from "path";
import pckg from "../package.json" with {type: "json"};

const RNG = "mei-all.rng";
const meiVersion = pckg.sibmei.meiVersion;

/** @type {Set<string>?} */
let legalElements;

export async function getLegalElements() {
  if (legalElements) {
    return legalElements;
  }
  const schemaPath = path.join("cache", meiVersion, RNG);
  if (!fs.existsSync(schemaPath)) {
    fs.mkdirSync(path.dirname(schemaPath), {recursive: true});
    fs.writeFileSync(schemaPath, await fetchSchema(), "utf8");
  }

  const rngCode = fs.readFileSync(schemaPath, "utf8");
  legalElements = extractLegalElements(rngCode);
  return legalElements;
}

/**
 * @param {string} rngCode
 */
export function extractLegalElements(rngCode) {
  /** @type {Set<string>} */
  const legalElements = new Set();
  const rng = parser.sync(rngCode);
  for (const elementDefinition of /** @type {Element[]} */ (rng.getElementsByTagName("element"))) {
    const elementName = elementDefinition.getAttribute("name");
    // Only consider elements in the MEI namespace
    if (elementName && definitionNamespace(elementDefinition) ==="http://www.music-encoding.org/ns/mei") {
      legalElements.add(elementName);
    }
  }
  return legalElements;
}

/**
 * @return {Promise<string>}  The schema as RNG code
 */
async function fetchSchema() {
  const schemaUrl = `https://raw.githubusercontent.com/music-encoding/music-encoding/v${meiVersion}/schemata/${RNG}`;
  return new Promise((resolve, reject) => {
    https.get(schemaUrl, (res) => {
      let data = "";
      console.log("Downloading MEI schema...");

      res.on("data", (chunk) => {
        data += chunk;
      });

      res
        .on("end", () => {
          try {
            resolve(data);
          } catch (e) {
            reject(e);
          }
        })
        .on("error", reject);
    });
  });
}

/**
 * @param {Element} element
 * @returns {string?}
 */
function definitionNamespace(element) {
  return (
    element.getAttribute("ns") ||
    (element.parentElement ? definitionNamespace(element.parentElement) : null)
  );
}

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
/** @type {Set<string>?} */
let legalAttributes;

export async function getLegalElements() {
  if (legalElements) {
    return legalElements;
  }
  legalElements = (await getSchema()).legalElements;
  return legalElements;
}

export async function getLegalAttributes() {
  if (legalAttributes) {
    return legalAttributes;
  }
  legalAttributes = (await getSchema()).legalAttributes;
  return legalAttributes;
}

/**
 * @param {string} [rngCode]  Should be omitted unless passing a dummy schema for testing
 * @returns {Promise<{legalAttributes: Set<string>, legalElements: Set<string>}>}
 */
export async function getSchema(rngCode) {
  if (!rngCode) {
    const schemaPath = path.join("cache", meiVersion, RNG);
    if (!fs.existsSync(schemaPath)) {
      fs.mkdirSync(path.dirname(schemaPath), { recursive: true });
      fs.writeFileSync(schemaPath, await fetchSchema(), "utf8");
    }

    rngCode = fs.readFileSync(schemaPath, "utf8");
  }
  const rng = parser.sync(rngCode);

  /** @type Set<string> */
  const legalElements = new Set();
  for (const elementDefinition of /** @type Element[] */ (rng.getElementsByTagName("element"))) {
    const elementName = elementDefinition.getAttribute("name");
    // Only consider elements in the MEI namespace
    if (
      elementName &&
      definitionNamespace(elementDefinition) === "http://www.music-encoding.org/ns/mei"
    ) {
      legalElements.add(elementName);
    }
  }

  /** @type Set<string> */
  const legalAttributes = new Set();
  for (const defineElement of /** @type Element[] */ (rng.getElementsByTagName("define"))) {
    if (defineElement.getAttribute("name")?.startsWith("mei_")) {
      for (const attributeDefinition of defineElement.getElementsByTagName("attribute")) {
        const attributeName = attributeDefinition.getAttribute("name");
        if (!attributeName) {
          throw new Error('Found attribute definition without attribute name');
        }
        legalAttributes.add(attributeName);
      }
    }
  }

  return { legalAttributes, legalElements };
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

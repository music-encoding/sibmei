// @ts-check

import fs from "fs";
import https from "https";
import parser from "slimdom-sax-parser";
import path from "path";
import pckg from "../package.json" with {type: "json"};

const RNG = "mei-all.rng";
const meiVersion = pckg.sibmei.meiVersion;
const RNG_NS = "http://relaxng.org/ns/structure/1.0";
const MEI_NS = "http://www.music-encoding.org/ns/mei";

/**
 * @typedef {Object} ElementInfo
 * @property {Set<string>} attributes - List of allowed attribute names
 * @property {Set<string>} children - List of allowed child element names
 */

/**
 * @typedef {Object} Schema
 * @property {Map<string, ElementInfo>} elements - Map of all available elements
 * @property {Set<string>} attributes - List of all available attributes
 */

/** @type Map<string, Schema> - Keys are RNG code, values are  */
const cachedSchemas = new Map();

/**
 * @param {string} [rngCode]  Should be omitted unless passing a dummy schema for testing
 * @returns {Promise<Schema>}
 */
export async function getSchema(rngCode) {
  const cacheKey = rngCode || "";
  const cachedSchema = cachedSchemas.get(cacheKey);
  if (cachedSchema) return cachedSchema;

  const rng = await getRngDocument(rngCode);

  const defines = new Map();
  for (const def of rng.getElementsByTagNameNS(RNG_NS, "define")) {
    defines.set(def.getAttribute("name"), def);
  }
  const elements = /** @type {Map<string, ElementInfo>} */ (new Map());

  for (const elementDefinition of rng.getElementsByTagNameNS(RNG_NS, "element")) {
    if (!isMeiElementDefinition(elementDefinition)) continue;
    const elementName = elementDefinition.getAttribute("name");
    if (!elementName) {
      // At the moment, we ignore <anyName>
      continue;
    }
    if (elements.has(elementName)) {
      throw new Error("Duplicate element definition for " + elementName);
    }
    elements.set(elementName, extractElementInfo(elementDefinition, defines));
  }

  const attributes = new Set();
  for (const element of elements.values()) {
    for (const attribute of element.attributes) {
      attributes.add(attribute);
    }
  }

  const schema = { elements, attributes };
  cachedSchemas.set(cacheKey, schema);
  return schema;
}

/**
 * @param {string} [rngCode]
 */
async function getRngDocument(rngCode) {
  if (!rngCode) {
    const schemaPath = path.join("cache", meiVersion, RNG);
    if (!fs.existsSync(schemaPath)) {
      fs.mkdirSync(path.dirname(schemaPath), { recursive: true });
      fs.writeFileSync(schemaPath, await fetchSchema(), "utf8");
    }

    rngCode = fs.readFileSync(schemaPath, "utf8");
  }

  return parser.sync(rngCode);
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
 * Recursively extract attributes and child elements for a given <element>.
 * @param {Element} elem - The starting <element> node
 * @param {Map<string, Element>} defines - Map of <define name="..."> nodes
 * @returns {ElementInfo}
 */
function extractElementInfo(elem, defines) {
  const attributes = new Set();
  const children = new Set();
  const visitedRefs = new Set();

  /**
   * Recursive helper to traverse child patterns.
   * @param {Element|null|undefined} element
   */
  function walk(element) {
    if (!element || element.namespaceURI !== RNG_NS) return;

    for (const child of element.children) {
      switch (child.localName) {
        case "attribute":
          const name = child.getAttribute("name");
          if (!name) {
            // At the moment, we ignore <anyName>
            break;
          }
          attributes.add(name);
          break;
        case "element":
          if (!isMeiElementDefinition(child)) break;
          const childName = child.getAttribute("name");
          if (!childName) {
            // At the moment, we ignore <anyName>
            break;
          }
          children.add(childName);
          break;
        case "ref":
          const refName = child.getAttribute("name");
          if (refName && !visitedRefs.has(refName)) {
            visitedRefs.add(refName);
            walk(defines.get(refName));
          }
          break;
        case "choice":
        case "optional":
        case "zeroOrMore":
        case "oneOrMore":
        case "group":
        case "interleave":
          walk(child)
          break;
      }
    }
  }

  walk(elem);

  return { attributes, children };
}

/**
 * @param {Element} element
 */
function isMeiElementDefinition(element) {
  const elementName = element.getAttribute("name");
  while (element) {
    const ns = element.getAttribute("ns");
    if (ns) return ns === MEI_NS;
    if (!element.parentElement) {
      throw new Error("Could not determine namespace of element " + elementName);
    };
    element = element.parentElement;
  }
}

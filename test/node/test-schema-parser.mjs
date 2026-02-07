// @ts-check

import { deepEqual } from "assert";
import { describe, it } from "node:test";
import { getSchema } from "../../tools/schema.mjs";

describe("schema parsing", () => {
  it("parses test schema", async () => {
    const rngCode = `<grammar xmlns="http://relaxng.org/ns/structure/1.0" ns="http://www.music-encoding.org/ns/mei">
      <div ns="http://www.w3.org/2000/svg">
        <define name="svg_SVG.some.attrib">
          <optional>
            <attribute name="foo">
              <choice>
                <value>bar</value>
                <value>baz</value>
              </choice>
            </attribute>
          </optional>
        </define>
        <define name="svg_svg">
          <element name="svg">
            <ref name="svg_SVG.some.attrib"/>
          </element>
        </define>
      </div>
      <define name="mei_mei">
        <element name="mei">
          <ref name="mei_att.some.attributes"/>
          <ref name="mei_music"/>
        </element>
      </define>
      <define name="mei_music">
        <element name="music">
          <ref name="mei_att.some.more.attributes"/>
          <attribute name="type">
            <choice>
              <value>old</value>
              <value>new</value>
            </choice>
          </attribute>
        </element>
      </define>
      <define name="mei_att.some.attributes">
        <attribute name="someAttribute">
          <choice>
            <value>1</value>
            <value>2</value>
          </choice>
        </attribute>
        <ref name="mei_att.some.more.attributes"/>
      </define>
      <define name="mei_att.some.more.attributes">
        <attribute name="someOtherAttribute">
          <value>true</value>
        </attribute>
      </define>
      <start>
        <choice>
          <ref name="mei_mei"/>
        </choice>
      </start>
    </grammar>`;
    deepEqual(await getSchema(rngCode), {
      attributes: new Set(["someAttribute", "someOtherAttribute", "type"]),
      elements: new Map([
        [
          "mei",
          {
            attributes: new Set(["someAttribute", "someOtherAttribute"]),
            children: new Set(["music"]),
          },
        ],
        [
          "music",
          {
            attributes: new Set(["someOtherAttribute", "type"]),
            children: new Set(),
          },
        ],
      ]),
    });
  });
});

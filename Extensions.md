# Extension API

With extensions to Sibmei, text objects, symbols and lines can be exported in a customized way. This allows addressing custom symbols and text styles and project specific needs.

Extensions are regular Sibelius plugins written in ManuScript. When running Sibmei, it scans for extension plugins. Users can choose which extensions to activate when running Sibmei. Multiple extensions can be activated simultaneously.

![choosing Sibmei extensions](assets/extension-choice.png)

## Example

```js
{
  // The `SibmeiExtensionAPIVersion` field must be present so Sibmei can
  // recognize compatible extensions
  SibmeiExtensionAPIVersion "1.0.0"

  Initialize "() {
    // The extension choice dialog will list this extension as
    // 'Example extension' (the first argument to to AddToPluginsMenu()).
    // Second argument can be `null` because an extension plugin does not need a
    // `Run()` method.
    AddToPluginsMenu('Example extension', null);
  }"

  // InitSibmeiExtension() is the entry point for Sibmei and must be present
  // for Sibmei to recognize an extension plugin.
  InitSibmeiExtension "(api) {
    // It is recommended to register the api and libmei objects as global
    // variables:
    Self._property:api = api;
    Self._property:libmei = api.libmei;

    // Declare which text styles this extension handles
    api.RegisterTextHandlers(CreateDictionary(
      // Text objects can be matched either by their StyleId or StyleAsText
      // property. Here, we match by StyleAsText.
      'StyleAsText', CreateDictionary(
         // We want the HandleMyText() method to handle Text objects matching
         // textObj.StyleAsText = 'My text'
        'My text', 'HandleMyText'
      )
    ), Self);
  }"

  HandleMyText "(_, textObj) {
    // Create and return an MEI element that Sibmei will append as a child to
    // the measure element.
    textElement = api.GenerateControlEvent(textObj, 'AnchoredText');
    api.AddFormattedText(textElement, textObj);
    return textElement;
  }"
}
```

See [another example](./lib/sibmei4_extension_test.plg) for code handling symbols.

## Required Data

### `SibmeiExtensionAPIVersion`

A [semantic version string](https://en.wikipedia.org/wiki/Software_versioning#Degree_of_compatibility) specifying for which version of the Sibmei extension
API the extension was written. The current API version of Sibmei can be found in
[`GLOBALS.mss`](./src/GLOBALS.mss).

The API is guaranteed to remain backwards compatible with newer releases that retain the same major version number for `ExtensionAPIVersion`. With minor version numbers, new functionality is added while existing functionality remains backwards compatible.

## Required Methods

### Symbol or Text Handlers

The core purpose of an extension is to define symbol and text handlers to export Sibelius objects in custom ways. (See `HandleMyText()` in the above [example](#example))  These handlers take two arguments:

* `this`: a Dictionary that is passed for technical reasons and *must be ignored by the extension*
* a Sibelius object (`SymbolItem` or `SystemSymbolitem` for symbol handlers, `Text` or `SystemTextItem` for text handlers)

A text handler should return an MEI element (created using libmei) that
Sibmei will append to the `<measure>` element.  If `null` is returned instead,
the object will not be exported.

A symbol handler should either call the `HandleModifier()` or `HandleControlEvent()` methods. If neither is called, the object will not be exported. Symbol handlers needn't return anything.

### `InitSibmeiExtension()`

Sibmei calls this method and passes an API Dictionary as argument (see below).
Register your symbol and text handlers in this function using `RegisterSymbolHandlers()` and `RegisterTextHandlers()` (see below).

## API Dictionary

### Interaction with Sibmei

Extensions must only interact with Sibmei through the API dictionary passed to `InitSibmeiExtension()` because Sibmei's core methods may change at any point. If an extension requires access to functionality that is not exposed by the API dictionary, [create an issue](https://github.com/music-encoding/sibmei/issues/new) or a pull request on GitHub.

### Element templates

The API supports element templates in different places. A template is a SparseArray with the following content:

* The capitalized tag name (e.g. `Dynam` for `<dynam>` elements)

* A Dictionary with attribute names and values, or `null`, if no attributes are declared. Unlike tag names, attribute names are not capitalized.

* A child node (optional). This can be a string for text nodes, or a template SparseArray of the same form for a child element.

* Another child node

* ...

Example:

```js
CreateSparseArray(
	'P', null,
	'This is ',
	CreateSparseArray('Rend', CreateDictionary('rend', 'italic'),
		'declarative'
	),
	' MEI generation.'
)
```

Output:

```xml
<p>This is <rend rend='italic'>declarative</rend> MEI generation.</p>
```

#### Dynamic template fields

Sibmei has a few capabilities to dynamically fill in text and attribute values in templates, based on data from a text or line object.

##### Text

For filling in formatted or unformatted text, it supplies the special placeholder objects `api.AddFormattedText` and `api.AddUnformattedText`.

Example:

```js
CreateSparseArray(
	'PersName', null, CreateSparseArray(
        'Composer', null, api.AddUnformattedText
    )
)
```

Output for a text object with `Text` property 'Joseph Haydn':

```xml
<persName><composer>Joseph Haydn</composer></persName>
```

Where `api.AddFormattedText` is used, any formatting like bold or italic will be converted to the respective MEI markup.  For `api.AddUnformattedText`, any such formatting is stripped.

##### Line `@endid`

When exporting Sibelius line objects (lines, hairpins, highlights etc.), the MEI object can be given an `endid` attribute that will be written automatically.  In the template, the value of the attribute should be set to one of the placeholders described below.

Example:

```js
CreateSparseArray('Line', CreateDictionary('func', 'coloration', 'endid', 'PreciseMatch'))
```

The placeholder will be replaced by an ID reference when writing the XML. Which ID is written depends on the line's end position and the value of the placeholder:

* `'PreciseMatch'`: `@endid` will only be written if there is a NoteRest precisely at the `EndPosition` in the same voice as the line.
* `'Next'`: If there is no NoteRest at the `EndPosition`, will write an `@endid` pointing to the closest following NoteRest, if there is one in the same voice as the line.
* `'Previous'`:  If there is no NoteRest at the `EndPosition`, will write an `@endid` pointing to the closest preceding NoteRest, if there is one in the same voice as the line.
* `'Closest'`: Writes an `@endid` that points to the closest NoteRest to the `EndPosition` in the same voice as the line.

### API data and methods

The API dictionary exposes the following object:

* **`libmei`**: A reference to libmei that can be used to construct and
   manipulate MEI elements. *This dictionary must not be modified.*

#### Registering Text, Symbol and Line styles

It exposes the following methods that must only be called in the initialization phase:

* **`RegisterSymbolHandlers()`**: Call this function to tell Sibmei how to handle a specific Symbolitem or SystemSymbolItem. To tell Sibmei which symbols the extension handles, the symbols must be
   registered by their `Index` or `Name` property. For built-in
   symbols, always use the `Index` property, for custom symbols, always use the
   `Name` property.

   The Dictionary that needs to be passed to `RegisterSymbolHandlers()` has the
   following structure:

   ```
   CreateDictionary(
      'Name', CreateDictionary(
         'My custom symbol', 'MyCustomSymbolHandler',
         'My other custom symbol', 'MyAlternativeCustomSymbolHandler'
      ),
      'Index', CreateDictionary(
         builtInIndex, 'MyCustomSymbolHandler',
         otherBuiltInIndex, 'MyCustomSymbolHandler'
      )
   )
   ```

   If Sibmei finds a symbol with a `Name` or `Index` property matching a key in
   the respective sub-Dictionaries, it will call the symbol handler registered
   under that key. A method of that name must be present in the extension
   plugin.

   If no symbols are registered by either `Name` or `Index` property, the
   respective sub-dictionaries can be omitted.

   Second argument of `RegisterSymbolHandler()` must be `Self`.

* **`RegisterTextHandlers()`**: Works the same way as `RegisterSymbolHandlers()`, with two differences:

   * Sub-Dictionary keys are `StyleId` and `StyleAsText` instead of `Index` and `Name`. Always use `StyleId` for built-in text styles and `StyleAsText` for custom text styles.
   
   * Sub-Dictionary values can also be templates.  At the moment, this is only possible for control events (i.e. elements that will be attached to the measure).  For creating modifiers (that are attached to a note, rest or chord), registering a handler methods that calls `HandleModifier()` is required instead.

* **`RegisterLineHandlers()`**: Works the same way as `RegisterTextHandlers()`.

   If a line element (generated by a template or by a handler method) has an `endid` attribute, the value of the attribute should be set to one of the placeholders [described above](#line-@endid).

The following methods must only be used by handler methods:

* **`MeiFactory()`**: Takes a [template](#element-templates) as argument and generates an MEI element from it that is returned.

   Instead of calling `MeiFactory()` directly, consider leaving template handling to `HandleControlEvent()` or `HandleModifier()`, or even better `RegisterTextHandlers()` or `RegisterLineHandlers()` where possible.

* **`HandleControlEvent()`**:  Pass this function two arguments:

   * The to be exported `SymbolItem` or `SystemSymbolItem`
   * A template suitable for passing to `MeiFactory()`

   `HandleControlEvent()` creates an MEI element and attaches it to the `<measure>` element. It returns the element for further manipulation by the extension plugin.

* **`HandleModifier()`**: Works similarly to `HandleControlEvent()`, but attaches the generated MEI element to an event element (`<note>`, `<chord>` etc.) instead of the `<measure>` element.

* **`HandleLineTemplate()`**: Takes two arguments:

   * The line-like object (basically any of the ManuScript classes that has the `IsALine` flag set)
   * A template suitable for passing to `MeiFactory()`.

* **`AddFormattedText()`**: Takes arguments:

   * `parentElement`: MEI element that the formatted text nodes should be appended to
   * `textObj`: A  `Text` or `SystemTextItem` object. Its `TextWithFormatting` property is converted to MEI markup.

* **`GenerateControlEvent()`**: Takes two arguments:

   * `bobj`: A `BarObject`
   * `elementName`: Capitalized MEI element name, e.g. `'Line'`.

   Uses the `elementName` to generate an MEI element and adds applicable control event attributes (see  `AddControlEventAttributes`). Returns the created element.

   When calling this function in a handler method that was registered with `RegisterSymbolHandler()` or `RegisterLineHandler()`, the handler method has to return the created element.

* **`AddControlEventAttributes()`**:  Takes two arguments:

   * `bobj`: A `BarObject`
   * `element`: An MEI element

   Adds the following control event attributes:

   * `@startid` (if a start object could be identified) and `@tstamp`
   * If applicable (e.g. for lines), `@endid` (if an end object could be identified) and `@tstamp2`
   * `@staff` (if object is staff-attached)
   * `@layer`
   * For lines:
     * `@dur.ppq` (unless `Duration` is 0)
     * `@startho`, `@startvo`, `@endho`, `@endvo`
   * For elements other than lines:
     * `@ho`, `@vo`

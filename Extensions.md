# Extension API

Sibmei's extension API is designed to allow defining the export behavior of
custom text styles and symbols or customizing the export behavior of existing
symbols.

Extensions are regular Sibelius plugins written in ManuScript. They must define
specific global data and methods so that Sibmei can find them and interact with
them.

## Required Data

### `ExtensionAPIVersion`

A [semantic version string](https://en.wikipedia.org/wiki/Software_versioning#Degree_of_compatibility) specifying for which version of the Sibmei extension
API the extension was written. The current API version of Sibmei can be found in
[`GLOBALS.mss`](./src/GLOBALS.mss).

## Required Methods

### Symbol or Text Handlers

The core purpose of an extension is to define symbol and text handlers to export Sibelius objects in custom ways. These handlers take two arguments:

* `this` (this parameter should be ignored by the extension)
* a Sibelius object (`SymbolItem` or `SystemSymbolitem` for symbol handlers, `Text` and `SystemTextItem` for text handlers)

A handler should return an MEI element (created using libmei) that
Sibmei will append to the `<measure>` element.  If `null` is returned instead,
the Sibelius object will not be exported at all.

### `InitSibmeiExtension()`

Sibmei calls this method and passes an API Dictionary as argument (see below).
Register your symbol and text handlers in this function using `RegisterSymbolHandlers()` and `RegisterTextHandlers()` (see below).

## API Dictionary

### Interaction with Sibmei

Extensions must only interact with Sibmei through the API dictionary passed to `InitSibmeiExtension()`. The functionality provided by the API dictionary is guaranteed to remain backwards compatible with newer releases that retain the same major version number for the `ExtensionAPIVersion`, while Sibmei's core methods may change at any point.

If an extension requires access to functionality that is not exposed by the API dictionary, [create an issue](https://github.com/music-encoding/sibmei/issues/new) or a pull request on GitHub.

### API data and methods

* **`libmei`**: A reference to libmei that can be used to construct and
   manipulate MEI elements.
   
* **`RegisterSymbolHandlers()`**: Call this function to make a symbol handler
   known to Sibmei. To tell Sibelius which symbol to handle, it must be
   registered by the symbol's `Index` or `Name` properties. For built-in
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
         myIndex, 'MyCustomSymbolHandler',
         myOtherIndex,  'MyCustomSymbolHandler'
      )
   )
   ```

   If Sibmei finds a symbol with a `Name` or `Index` property matching a key in
   the respective sub-Dictionaries, it will call the symbol handler registered
   under that key. A method of that name must be present in the extension
   plugin.

   If no symbols are registered by either `Name` or `Index` property, the
   respective sub-dictionaries can be omitted.

   Second argument must be `Self`.

* **`RegisterTextHandlers()`**: Works the same way as
   `RegisterSymbolHandlers()`, with the difference that sub-Dictionary keys are
   `StyleId` and `StyleAsText` instead of `Index` and `Name`. Always use
   `StyleId` for built-in text styles and `StyleAsText` for custom text styles.

* **`MeiFactory()`**: A convenience method that takes a template SparseArray as
   argument and generates an MEI element from it. For detailed information, see
   the documentation comments in [`Utilities.mss`](./src/Utilities.mss).

   It is a good idea to define template dictionaries as global variables in the
   `InitSibmeiExtension()` method instead of defining them locally in the symbol
   handler methods.
   
* **`HandleControlEvent()`**:  Pass this function two arguments:

   * The to be exported `SymbolItem` or `SystemSymbolItem`
   * A template suitable for passing to `MeiFactory()`

   `HandleControlEvent()` will take care of creating an element and attaching it to the measure.

* **`HandleModifier()`** takes the same arguments as `HandleControlEvent()`, but attaches the MEI element to a `<note>` element instead of the `<measure>` element.

* **`AddFormattedText()`**: A method used for the export of text styles. It 
   adds the content of TextWithFormatting to the element.

## Example

An example extension plugin can be found
[on GitHub](./lib/sibmei4_extension_test.plg).

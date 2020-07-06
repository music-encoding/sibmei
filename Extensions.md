# Extension API

Sibmei's extension API is designed to allow defining the export behavior of
custom text styles and symbols or customizing the export behavior of existing
symbols.

Extensions are regular Sibelius plugins written in ManuScript. They must define
specific global data and methods so that Sibmei can find them and interact with
them.

## Required Data

### `ExtensionAPIVersion`

A semantic version string specifying for which version of the Sibmei extension
API the extension was written. The current API version can be found in
`GLOBALS.mss`.

## Required Methods

### Symbol or Text Handlers

These methods take a Sibelius object as argument and return an MEI element that
Sibmei will append to the `<measure>` element.  If `null` is returned instead,
the Sibelius object will not be exported at all.

### `InitSibmeiExtension()`

Sibmei calls this method and passes an API Dictionary as argument (see below).
Register your symbol and text handlers in this function.

#### API Dictionary Fields

* **`libmei`**: A refernce to libmei that can be used to construct and
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

* **`RegisterTextHandlers()`**: Works the same way as
   `RegisterSymbolHandlers()`, with the difference that sub-Dictionary keys are
   `StyleId` and `StyleAsText` instead of `Index` and `Name`. Always use
   `StyleId` for built-in text styles and `StyleAsText` for custom text styles.

* **`MeiFactory()`**: A convenience method that takes a template SparseArray as
   argument and generates an MEI element from it. For detailed information, see
   the documentation comments in `Initialize.mss`.

   It is a good idea to define template dictionaries as global variables in the
   `InitSibmeiExtension()` method instead of defining them locally in the symbol
   handler methods.

## Example

An example extension plugin can be found
[on GitHub](https://github.com/music-encoding/sibmei/tree/master/lib/sibmei4_extension_test.plg).

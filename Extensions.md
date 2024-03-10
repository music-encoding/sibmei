# Extension API

With extensions to Sibmei, text objects, symbols and lines can be exported in a customized way. This allows addressing custom symbols and text styles and project specific needs.

Extensions are regular Sibelius plugins written in ManuScript. When running Sibmei, it scans for extension plugins. Users can choose which extensions to activate when running Sibmei. Multiple extensions can be activated simultaneously.

![choosing Sibmei extensions](assets/extension-choice.png)

## Example

```js
{
  //"The `SibmeiExtensionAPIVersion` field must be present so Sibmei can"
  //"recognize compatible extensions"
  SibmeiExtensionAPIVersion "2.0.0"

  Initialize "() {
    // The extension choice dialog will list this extension as
    // 'Example extension' (the first argument to to AddToPluginsMenu()).
    // Second argument can be `null` because an extension plugin does not need a
    // `Run()` method.
    AddToPluginsMenu('Example extension', null);
  }"

  //"InitSibmeiExtension() is the entry point for Sibmei and must be present"
  //"for Sibmei to recognize an extension plugin."
  InitSibmeiExtension "(api) {
    // Declare which text styles this extension handles
    api.RegisterTextHandlers('StyleAsText', CreateDictionary(
      // We want to add support for Text objects matching
      //   textObj.StyleAsText = 'My text'
      // Sibmei will append the generated element to the measure element.
      'My text', CreateSparseArray('AnchoredText', null, api.FormattedText)
    ), Self);
  }"
}
```

See [another example](./lib/sibmei4_extension_test.plg) for an extension plugin that also handles symbols and lines.

## Required data and methods

### `SibmeiExtensionAPIVersion`

A [semantic version string](https://en.wikipedia.org/wiki/Software_versioning#Degree_of_compatibility) specifying for which version of the Sibmei extension
API the extension was written. The current API version of Sibmei can be found in
[`GLOBALS.mss`](./src/GLOBALS.mss).

The API is guaranteed to remain backwards compatible with newer releases that retain the same major version number for `ExtensionAPIVersion`. Sibmei may support legacy extension plugins with a lower major version number for a while. With minor version numbers, new functionality is added while existing functionality remains backwards compatible.

### `InitSibmeiExtension()`

Sibmei calls this method and passes an API Dictionary as argument (see below).
Register your symbol and text handlers in this function using `RegisterSymbolHandlers()` and `RegisterTextHandlers()` (see below).

## API Dictionary

### Interaction with Sibmei

Extensions must only interact with Sibmei through the API dictionary that is passed to `InitSibmeiExtension()` and Handler methods because Sibmei's core methods may change at any point. If an extension requires access to functionality that is not exposed by the API dictionary, [create an issue](https://github.com/music-encoding/sibmei/issues/new) or a pull request on GitHub.

### API data and methods

The API dictionary exposes the following object:

* **`libmei`**: A reference to libmei that can be used to construct and
   manipulate MEI elements. *This dictionary must not be modified.*

The API dictionary exposes the following [methods for registering Handlers](ExportHandlers.md#creating-and-registering-handlers) that must only be used inside the `InitSibmeiExtension()` method:

* **`RegisterSymbolHandlers()`**
* **`RegisterTextHandlers()`**
* **`RegisterLineHandlers()`**
* **`AsModifier()`**

The following methods can be used by Handler methods:

* [**`AddFormattedText()`** ](ExportHandlers.md#addformattedtext)
* [**`GenerateControlEvent()`**](ExportHandlers.md#generatecontrolevent)
* [**`GenerateModifier()`**]((ExportHandlers.md#generatemodifier))
* [**`MeiFactory()`**](ExportHandlers.md#meifactory)

# Handling of Text, Lines and Symbols

Text and Lines have in common that there are a multitude of different styles, and users can add their own styles.  The style of a text or line object can be determined by looking at their `StyleId` and/or `StyleAsText` properties.  Each style should be exported in a different fashion.

Symbols are similar, but instead of `StyleId` and `StyleAsText`, the properties to look at are `Index` and `Name`.

> [!NOTE]
>
> All the following code examples use an `api` prefix.  This prefix is only needed when creating handlers via extension plugin.  For Sibmei internal code, this prefix must be omitted.

## Handlers

To handle the multitude of styles and symbols, we have a mechanism to associate Handlers with the different styles and symbols.  For user-defined styles and symbols, extension plugins can register additional Handlers.

Handlers are tiny objects with a method `HandleObject()`. The line, text or symbol object is passed to this method and the method has to generate and return an MEI element.  It is also responsible for inserting them in the score.  This is done by calling `GenerateControlEvent()` for control events (which adds them to `<measure>`) and `GenerateModifier()` for modifiers (which adds them to `<note>`, `<rest>` or `<chord>`).

> [!NOTE]
>
> ### Internals: Associating BarObjects with their Handlers
>
> A mapping Dictionary is used to find the Handler that is used to convert an object to MEI.  There are three such mapping Dictionaries: `LineHandlers`, `TextHandlers` and `SymbolHandlers`. These dictionaries look like illustrated by the following pseudo-code:
>
> ```js
> {
>  StyleId: {
>      'line.staff.slur.down': {
>           HandleObject: function() ControlEventTemplateHandler(this, bobj){...},
>           template: ['Slur', {endid: 'PreciseMatch'}],
>      }
>  },
>  StyleAsText: {
>      // A line style that is handled with a custom, non-template based
>      // handler method:
>      'My Line': {
>          HandleObject: function HandleMyLine(this, bobj){...}
>      },
>      // And another one that uses a template:
>      'My template based line': {
>           HandleObject: function ControlEventTemplateHandler(this, bobj){...},
>           template: ['Line', {type: 'My other line'}],
>      },
>  },
> }
> ```
>
> For the `SymbolHandlers` Dictionary, the keys `Index` and `Name` are used instead of `StyleId` and `StyleAsText`.
>
> When Sibmei finds a a line or text object, it calls `HandleStyle()` (and  if it finds a symbol, it uses `HandleSymbol()`), and those methods retrieve the Handler defined from the respective Handler mapping Dictionary (if any) and execute it.
>

## Creating and registering Handlers

For creating entries in the Handler mapping Dictionaries, the `RegisterSymbolHandlers()`, `RegisterLineHandlers()` and `RegisterTextHandlers()` methods are used.  These functions also create the Handler objects and their `HandleObject()` methods.

There are two ways of registering a Handler:

### Registering a template

This is the preferred way of registering Handlers.

Example:

```js
api.RegisterTextHandlers('StyleId', CreateDictionary(
    'text.staff.technique', CreateSparseArray('Dir', CreateDictionary('label', 'technique'), api.FormattedText)
), Self);
```

Templates declaratively describe an MEI element by means of ManuScript data structures  for example:

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

`MeiFactory()` converts this to the following MEI:

```xml
<p>This is <rend rend='italic'>declarative</rend> MEI generation.</p>
```

Templates are SparseArrays with the following entries (in this order):

* The capitalized tag name (e.g. `Dynam` for `<dynam>` elements)

* A Dictionary with attribute names and values, or `null`, if no attributes are declared. Unlike tag names, attribute names are not capitalized.

* A child node. This can be a string for text nodes, or a template SparseArray of the same form for a child element.

* Another child node

* ...

Only the tag name is required, all other entries are optional.

#### Control event vs. modifier

By default, the built-in template Handler adds the created element to `<measure>` as a control event.  If it should instead be added to `<note>`, `<rest>` or `<chord>` as modifier, the `AsModifier` function must be used:

```js
api.RegisterSymbolHandlers('Index', CreateDictionary(
    209, api.AsModifier(CreateSparseArray('Artic', CreateDictionary('artic', 'stacc', 'place', 'above')))
));
```

#### Dynamic template fields

Templates offer a few ways of dynamically filling in text and attribute values, based on data from a text or line object.

##### Text

For filling in formatted or unformatted text, use the special placeholder objects `api.FormattedText` and `api.UnformattedText`.

Example:

```js
CreateSparseArray(
	'PersName', null, CreateSparseArray(
        'Composer', null, api.UnformattedText
    )
)
```

Output for a text object where the `Text` property is 'Joseph Haydn':

```xml
<persName><composer>Joseph Haydn</composer></persName>
```

Where `api.FormattedText` is used, any formatting like bold or italic will be converted to the respective MEI markup.  For `api.UnformattedText`, any such formatting is stripped.

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
* `'Closest'`: Writes an `@endid` that points to the closest NoteRest at the `EndPosition` in the same voice as the line.

### Registering a Handler method

Where templates do not suffice, a dedicated Handler method can be written.  Here is an example from an extension, where a simple template would not be able to output different things depending on the colour of the symbol:

```js
function HandleMySymbol (api, obj) {
    symbolElement = api.GenerateControlEvent(obj, api.MeiFactory(MySymbolTemplate, obj));
    if (obj.ColorRed = 255)
    {
        api.libmei.AddAttribute(symbolElement, 'type', 'myRedType');
    }
    return symbolElement;
} //$end
```

A Handler method receives the Handler object as first argument and the symbol, text or line object as second argument.  It has to call `api.GenerateControlEvent()` or `api.GenerateModifier()`, otherwise the created MEI element will note be attached to the score.

In the above example, the MEI element is initially also generated from a template (that is defined as a global variable) by calling `api.MeiFactory()` directly.  The very same MEI element can also be created by means of libmei:

```js
function HandleMySymbol (api, obj) {
    symbolElement = api.libmei.Symbol();
    api.libmei.AddAttribute(symbolElement, 'fontfam', 'myCustomFont');
    api.libmei.AddAttribute(symbolElement, 'glyph.name', 'mySymbolGlyph');
    if (obj.ColorRed = 255)
    {
        api.libmei.AddAttribute(symbolElement, 'type', 'myRedType');
    }
    return symbolElement;
} //$end
```

#### `GenerateControlEvent()`

Takes two arguments:

* `bobj`: A `BarObject`
* `element`: An element that is either created by means of libmei or `MeiFactory()`.

`GenerateControlEvent()` takes care of adding the element to the `<measures>` and adds the following control event attributes:

* `@startid` (if a start object could be identified) and `@tstamp`

* If applicable (e.g. for lines), `@endid` (if an end object could be identified) and `@tstamp2`
* `@staff` (if object is staff-attached)
* `@layer`
* For lines:
  * `@dur.ppq` (unless `Duration` is 0)
  * `@startho`, `@startvo`, `@endho`, `@endvo`
* For elements other than lines:
  * `@ho`, `@vo`

`GenerateControlEvent()` returns `element`, which allow patterns like:

```js
element = api.GenerateControlEvent(bobj, api.MeiFactory(template, bobj));
```

#### `GenerateModifier()` 

Works in the same way as `GenerateControlEvent()`, but attaches the element to `<note>`, `<chord>` or `<rest>` (depending on what's found at the position in the object's voice).  Unlike `GenerateControlEvent()`, it does not add any attributes automatically.

#### `MeiFactory()`

Takes two arguments:

* A [template](#registering-a-template)
* The text, line or symbol object for which an element is generated by means of the template.  This parameter is only of importance if [dynamic template fields](#dynamic-template-fields) are used.

### Handling built-in and user-defined objects

Built-in text, line and symbol styles should always be registered under their `StyleId` or `Index` property. This is Sibelius localizes the `StyleAsText` and `Name` properties of built-in styles in different languages.

User-defined text, line and symbol styles on the other hand should always be registered under their `StyleAsText` or `Name` properties because the what `StyleId` and `Index` values Sibelius will assign can not be controlled by the user, and the numeric postfix Sibelius assigns these properties will vary from document to document.

If a Handler is registered under a `StyleId` or `Index` property, this will always supersede any Handlers registered under `StyleAsText` or `Name` properties for the same object.

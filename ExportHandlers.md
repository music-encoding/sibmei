# Handling of Text, Lines and Symbols

Text, LyricItems and Lines have in common that there are a multitude of different styles, and users can add their own styles. The style of a text, lyric or line object can be determined by looking at their `StyleId` and/or `StyleAsText` properties. Each style should be exported in a different fashion.

Symbols are similar, but instead of `StyleId` and `StyleAsText`, the properties to look at are `Index` and `Name`.

> [!NOTE]
>
> All the following code examples use an `api` prefix. This prefix is only needed when creating handlers via extension plugin. For Sibmei internal code, this prefix must be omitted.

## Handler objects

To handle the multitude of styles and symbols, we have a mechanism to associate Handler objects with the different styles and symbols. [Extension plugins](Extensions.md) can register additional Handlers to export user-defined styles and symbols, and also to change the export for built-in styles and symbols.

Handler objects consist of two things:  The Handler method `HandleObject()` and a `template` field.  In JavaScript-like pseudo-code, a Handler object looks like this:

```js
{
    HandleObject: function ControlEventTemplateHandler(this, bobj){...},
    template: ['Slur', {endid: 'PreciseMatch'}],
}
```

> [!NOTE]
>
> ### Internals: Associating BarObjects with their Handlers
>
> A mapping Dictionary is used to find the Handler that is used to convert an object to MEI. There are three such mapping Dictionaries: `LineHandlers`, `TextHandlers` and `SymbolHandlers`. These dictionaries look like illustrated by the following pseudo-code:
>
> ```js
> {
>   StyleId: {
>     'line.staff.slur.down': {
>       HandleObject: function ControlEventTemplateHandler(this, bobj){...},
>       template: ['Slur', {endid: 'PreciseMatch'}],
>     }
>   },
>   StyleAsText: {
>     // A line style that is handled with a custom, non-template based
>     // handler method:
>     'My Line': {
>       HandleObject: function HandleMyLine(this, bobj){...},
>       template: null,
>     },
>     // And another one that uses a template:
>     'My template based line': {
>       HandleObject: function ControlEventTemplateHandler(this, bobj){...},
>       template: ['Line', {type: 'My other line'}],
>     },
>   },
> }
> ```
>
> For the `SymbolHandlers` Dictionary, the keys `Index` and `Name` are used instead of `StyleId` and `StyleAsText`.
>
> When Sibmei finds a a line or text object, it calls `HandleStyle()` (and if it finds a symbol, it uses `HandleSymbol()`), and those methods retrieve the Handler defined from the respective Handler mapping Dictionary (if any) and execute it.

## Creating and registering Handlers

For creating entries in the Handler mapping Dictionaries, the four registrations functions `RegisterSymbolHandlers()`, `RegisterLineHandlers()`, `RegisterLyricHandlers()` and `RegisterTextHandlers()` are available. These functions also create the Handler objects, set their `HandleObject()` methods and register the `template` field (if the Handler method is template based).

```js
api.RegisterTextHandlers('StyleId', 'ControlEventTemplateHandler', CreateDictionary(
    'text.staff.technique', @Element('Dir', @Attrs('label', 'technique'),
        api.FormattedText
    )
));
```

The registration functions require three arguments:

* The ID-like property under which the Handlers should be registered. This can be `'StyleId'` or `'StyleAsText'` for text, lyrics and lines. As Sibelius' line objects do not have these two properties,  `'Index'` or `'Name'` has to be used for them instead.
* The name of the Handler method that will be responsible for converting the Sibelius object to an MEI element. This should usually be either of the methods `'ControlEventTemplateHandler'`, `'ModifierTemplateHandler'` or `'LyricTemplateHandler'` provided by Sibmei. The names of custom handlers provided by an extension for special requirements can be given as well (see [below](#handler-methods) for more information).
* A dictionary that maps ID values to element templates. Keys are values of the `StyleId`, `StyleAsText`, `Index` or `Name` properties, depending on what was given as the first parameter to the registration function. If the Handler method given in the second parameter is not template-based, the value can be set to `null` instead of a template.

#### Registering lyrics Handlers

`RegisterLyricHandlers()` expects the template to include a `<syl>` element with a descendant `api.LyricText`. It will register Template Actions on the `<syl>` templates that take care of tracking the context of the lyrics to generate the proper `@wordpos` and `@con` attributes as well as properly handling elisions.

`api.LyricText` only works as descendant of a `<syl>` template node.

### Templates

Templates declaratively describe an MEI element by means of ManuScript data structures for example:

```js
@Element('P', null,
    'This is ',
    @Element('Rend', @Attrs('rend', 'italic'),
        'declarative'
    ),
    ' MEI generation.'
)
```

`api.MeiFactory()` or the standard template Handler methods would convert this to the following MEI:

```xml
<p>This is <rend rend='italic'>declarative</rend> MEI generation.</p>
```

`@Element()` takes the following arguments:

* The capitalized tag name (e.g. `Dynam` for `<dynam>` elements)

* A Dictionary with attribute names and values, or `null`, if no attributes are declared. Unlike tag names, attribute names are not capitalized. `@Attrs()` creates such a dictionary.

* A child node. This can be a string for text nodes, or a template SparseArray of the same form for a child element.

* Another child node

* ...

Only the tag name is required, all other arguments are optional.

(`@Element()` and `@Attrs()` are actually aliases for `CreateSparseArray()` and `CreateDictionary()`, respectively. They are introduced to make the code for templates a little more semantic and a little terser.)

### Dynamic template fields

Templates offer a few ways of dynamically filling in text and attribute values, based on data from a text or line object.

##### Text

For filling in formatted or unformatted text, use the special placeholder objects `api.FormattedText` and `api.UnformattedText`.

Example:

```js
@Element('PersName', null,
    @Element('Composer', null,
        api.UnformattedText
    )
)
```

Output for a text object where the `Text` property is 'Joseph Haydn':

```xml
<persName><composer>Joseph Haydn</composer></persName>
```

Where `api.FormattedText` is used, any formatting like bold or italic will be converted to the respective MEI markup. For `api.UnformattedText`, any such formatting is stripped.  For lyrics, `api.LyricText` must be used.

##### Line `@endid`

When exporting Sibelius line objects (lines, hairpins, highlights etc.), the MEI object can be given an `endid` attribute that will be written automatically. In the template, the value of the attribute should be set to one of the placeholders described below.

Example:

```js
@Element('Line', @Attrs(
    'func', 'coloration',
    'endid', 'PreciseMatch'
))
```

The placeholder will be replaced by an ID reference when writing the XML. Which ID is written depends on the line's end position and the value of the placeholder:

* `'PreciseMatch'`: `@endid` will only be written if there is a `NoteRest` precisely at the `EndPosition` in the same voice as the line.
* `'Next'`: If there is no `NoteRest` at the `EndPosition`, will write an `@endid` pointing to the closest following `NoteRest`, if there is one in the same voice as the line.
* `'Previous'`: If there is no `NoteRest` at the `EndPosition`, will write an `@endid` pointing to the closest preceding `NoteRest`, if there is one in the same voice as the line.
* `'Closest'`: Writes an `@endid` that points to the closest `NoteRest` at the `EndPosition` in the same voice as the line.

### Handler methods

The line, text, lyric or symbol object that needs to be handled is passed to the Handler method. The Handler method has to generate and return an MEI element. It is also responsible for inserting it at the appropriate place in the MEI tree.

In general, Handler object's `HandleObject()` method is set to one of the following methods provided by Sibmei:

* `ControlEventTemplateHandler()` uses [`GenerateControlEvent()`](#generatecontrolevent) to create a `<measure>`-attached control event.

*  `ModifierTemplateHandler()` uses [`GenerateModifier()`](#generatemodifier) to create an element that is attached to the closest `<note>`, `<rest>` or `<chord>`.

*  `LyricTemplateHandler()` attaches the created element to `<note>`, `<rest>` or `<chord>` as well, but warns if the closest element is a rest.

### Writing a Handler method

Where plain templates and the standard Sibmei handlers do not suffice, a dedicated Handler method can be written. Here is an example from an extension that outputs different markup, depending on what colour the handled object has.

```js
function HandleMySymbol (api, obj) {
    symbolElement = api.GenerateControlEvent(obj, api.MeiFactory(api.template, obj));
    if (obj.ColorRed = 255)
    {
        api.libmei.AddAttribute(symbolElement, 'type', 'myRedType');
    }
    return symbolElement;
} //$end
```

A Handler method receives the Handler object as first argument and the symbol, text, lyrics or line object as second argument. The Handler object exposes the extension API methods and objects (hance it's named `api` here) as well as the `template` field that can be passed to `api.MeiFactory()`.

A Handler method has to call `api.GenerateControlEvent()` or `api.GenerateModifier()`, otherwise the created MEI element will not be attached to the score.

While in the above example, the MEI element is generated from a registered template by calling `api.MeiFactory()`, a Handler method can however also create elements without relying on templates:

```js
function HandleMySymbol (api, obj) {
    symbolElement = api.GenerateControlEvent(api.libmei.Symbol());
    api.libmei.AddAttribute(symbolElement, 'fontfam', 'myCustomFont');
    api.libmei.AddAttribute(symbolElement, 'glyph.name', 'mySymbolGlyph');
    if (obj.ColorRed = 255)
    {
        api.libmei.AddAttribute(symbolElement, 'type', 'myRedType');
    }
    return symbolElement;
} //$end
```

A Handler method can use the following methods:

#### `api.GenerateControlEvent()`

Takes two arguments:

* `bobj`: A `BarObject`
* `element`: An element that is either created by means of libmei or `MeiFactory()`.

`GenerateControlEvent()` takes care of adding the element to the `<measures>` and adds the following control event attributes:

* `@startid` (if a start object could be identified) and `@tstamp`. The addition of `@tstamp` can be suppressed by setting `@tstamp` to `' '` (e.g. in the template).

* If applicable (e.g. for lines), `@endid` (if an end object could be identified) and `@tstamp2`

* `@staff` and `@layer` (if object is staff-attached)

* For lines:

  * `@dur.ppq` (unless `Duration` is 0)
  * `@startho`, `@startvo`, `@endho`, `@endvo`

* For elements other than lines:

  * `@ho`, `@vo`

`GenerateControlEvent()` returns `element`, which allow patterns like:

```js
element = api.GenerateControlEvent(bobj, api.MeiFactory(template, bobj));
```

#### `api.GenerateModifier()`

Works in the same way as `GenerateControlEvent()`, but attaches the element to `<note>`, `<chord>` or `<rest>` (depending on what's found at the position in the object's voice). Unlike `GenerateControlEvent()`, it does not add any attributes automatically.

#### `api.MeiFactory()`

Takes two arguments:

* A [template](#registering-a-template)
* The text, line or symbol object for which an element is generated by means of the template. This parameter is only of importance if [dynamic template fields](#dynamic-template-fields) are used.

#### `api.AddFormattedText()`

Takes two arguments:

* `parentElement`: MEI element that the formatted text nodes should be appended to.
* `textObj`: A `Text` or `SystemTextItem` object. Its `TextWithFormatting` property is converted to MEI markup.

### Handling built-in and user-defined objects

Built-in text, line and symbol styles should always be registered under their `StyleId` or `Index` property. This is because Sibelius localizes the `StyleAsText` and `Name` properties of built-in styles in different languages, but `StyleId` and `Index` remain the same in all languages.

User-defined text, line and symbol styles on the other hand should always be registered under their `StyleAsText` or `Name` properties because the `StyleId` and `Index` values Sibelius will assign can not be controlled by the user, and the numeric postfix Sibelius assigns these properties will vary from document to document.

If a Handler is registered under a `StyleId` or `Index` property, this will always supersede any Handlers registered under `StyleAsText` or `Name` properties for the same object.

> [!NOTE]
>
> ### Internals: Template Actions
>
> Template Actions are an internal Sibmei concept for attaching hooks to template nodes that require special treatment. When `api.MeiFactory()` comes across a child template node that has a Template Action attached, it will give control to the Template Action for processing that node.
>
> Template Actions can be attached to element template nodes (like to `<syl>` elements), or they can be placeholder nodes, like `api.FormattedText`.
>
> Template Action methods receive the following arguments:
>
> - A reference to the Template Action object (similar to how Python or Lua methods receive `self` as first parameter). This object has a `templateNode` field that references the template node the Template Action is attached to.
>
> - The parent element of the output MEI tree. The Template Action method is responsible for attaching any created text or element nodes to that parent element using `api.libmei.AddChild()`, `api.libmei.SetText()` or the like.
>
> - The handled Sibelius BarObject, like a `LyricItem`.
>
> Especially if a template action is attached to an element template, it should do something like this:
>
> ```js
> function SomeElementAction (self, parent, bobj) {
>     element = api.MeiFactory(self.templateNode, bobj);
>     api.libmei.AddAttribute(element, 'label', 'do something with the element');
>     api.libmei.AddChild(parent, element);
> } //$end
> ```

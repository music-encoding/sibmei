function RegisterHandlers(handlers, handlerDefinitions, plugin) {
    //$module(Initialize.mss)
    // `handlers` is either of the global dictionaries `LineHandlers`,
    // `TextHandlers` and `SymbolHandlers`. (See ExportHandlers.md for more
    // information.)  RegisterHandlers() will create new entries in `handlers`
    // based on `handlerDefinitions`.
    //
    // The `handlerDefinitions` Dictionary describes all the object styles and
    // their handlers that will be registered in `handlers`.
    // Pseudo-code that results in the `handlers` entries illustrated above:
    // {
    //     StyleId: {
    //         'line.staff.slur.down': ['Slur', {endid: 'PreciseMatch'}]
    //     },
    //     StyleAsText: {
    //         // For non-template based handlers, the value is the handler
    //         // method name.  A method of this name must exists in the plugin
    //         // that is passed as parameter `plugin`.
    //         'My Line', 'HandleMyLine',
    //         // For template-based styles, a template that is suitable for
    //         // passing to `MeiFactory()`
    //         'My template based line': ['Line', {type: 'My other line'}]
    //     }
    // }
    //
    // `plugin` is either sibmei itself (`Self`) or an extension plugin. Any
    // handler method names found in `handlerDefinitions` will be looked up in
    // this plugin.

    for each Name id in handlerDefinitions
    {
        // handlerDefinition is either the name of the handler function
        // or a template SparseArray
        handlerDefinition = handlerDefinitions[id];
        handler = CreateDictionary();
        handlers[id] = handler;
        if (not IsObject(handlerDefinition))
        {
            handler.SetMethod('HandleObject', plugin, handlerDefinition);
        }
        else
        {
            // We have a template. Use the default handler.
            handler['template'] = handlerDefinition;
            if (handlerDefinition._property:createModifier)
            {
                handler.SetMethod('HandleObject', Self, 'ModifierTemplateHandler');
            }
            else
            {
                handler.SetMethod('HandleObject', Self, 'ControlEventTemplateHandler');
            }
        }
    }
}   //$end


function ModifierTemplateHandler (this, bobj) {
    return GenerateModifier(bobj, MeiFactory(this.template, bobj));
}  //$end


function ControlEventTemplateHandler (this, bobj) {
    return GenerateControlEvent(bobj, MeiFactory(this.template, bobj));
}  //$end


function HandleStyle (handlers, bobj) {
    // bobj must be an object with StyleId and StyleAsText properties (i.e. a
    // Line or Text object).  A matching handler for the style is looked up and
    // and applied.
    handler = handlers.StyleId[bobj.StyleId];
    if (null = handler)
    {
        handler = handlers.StyleAsText[bobj.StyleAsText];
    }
    if (null != handler)
    {
        return handler.HandleObject(bobj);
    }
} //$end


function AsModifier (template) {
    // Flags the template so that RegisterHandlers() will register the
    // ModifierTemplateHandler for it.
    template._property:createModifier = true;
    return template;
}  //$end

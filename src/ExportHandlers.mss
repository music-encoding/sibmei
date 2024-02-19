function RegisterHandlers(handlers, handlerDefinitions, plugin) {
    //$module(Initialize.mss)
    // `handlers` is either of the global dictionaries `LineHandlers`,
    // `TextHandlers` and `SymbolHandlers`. (See ExportHandlers.md for more
    // information.)  RegisterHandlers() will create new entries in `handlers`
    // based on `handlerDefinitions`.
    //
    // `plugin` is either sibmei itself (`Self`) or an extension plugin. Any
    // handler method names found in `handlerDefinitions` will be looked up in
    // this plugin.

    for each Name id in handlerDefinitions
    {
        // handlerDefinition is either the name of the handler function
        // or a template SparseArray
        handlerDefinition = handlerDefinitions[id];
        if (not IsObject(handlerDefinition))
        {
            if (Self = plugin)
            {
                handler = CreateDictionary();
            }
            else
            {
                // Extension handlers get the API object as first argument,
                // basically the `this` argument.
                extensionApiVersion = SplitString(plugin.SibmeiExtensionAPIVersion, '.')[0] + 0;
                handler = CreateApiObject(extensionApiVersion);
            }
            handler.SetMethod('HandleObject', plugin, handlerDefinition);
        }
        else
        {
            // We have a template. Use the default handler.
            handler = CreateDictionary('template', handlerDefinition);
            if (handlerDefinition._property:createModifier)
            {
                handler.SetMethod('HandleObject', Self, 'ModifierTemplateHandler');
            }
            else
            {
                handler.SetMethod('HandleObject', Self, 'ControlEventTemplateHandler');
            }
        }
        handlers[id] = handler;
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
    // applied.
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

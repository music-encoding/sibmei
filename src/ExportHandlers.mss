function InitHandlers () {
    Self._property:IsHandlerMethodThatExtensionsMayUse = CreateDictionary(
        'ControlEventTemplateHandler', true,
        'ModifierTemplateHandler', true,
        'LyricTemplateHandler', true
    );

    InitSymbolHandlers();
    InitLineHandlers();
    InitTextHandlers();
    InitLyricHandlers();
}  //$end

function RegisterHandlers(pluginInfo, handlers, idProperty, handlerMethod, templatesById) {
    // `pluginInfo` is either Self if RegisterHandlers() is
    // called from the Sibmei core, or an extension API object (that has a field
    // `_extensionInfo`) if RegisterHandlers() is called from an extension.
    //
    // `handlers` is either of the global dictionaries `LineHandlers`,
    // `TextHandlers`, `SymbolHandlers` or `LyricHandlers`. (See
    // ExportHandlers.md for more information.) RegisterHandlers() creates new
    // entries in `handlers` based on `handlerMethod` and `templatesById`.
    //
    // `idProperty` is either of `StyleId`, `StyleAsText`, `Name` or `Index`.
    //
    // `handlerMethod` is the name of the handler method, such as
    // `HandleControlEvent`, `HandleModifier` or `HandleLyricItem`.
    //
    // `templatesById` is a Dictionary that lists all the IDs that are handled
    // by `handlerMethod` as keys and templates as values. If `handlerMethod`
    // does not rely on a template, the value is ignored and can be set to
    // `null`.

    AssertIdType(pluginInfo, handlers, idProperty, handlerMethod);
    pluginThatDefinesHandler = FindPluginThatDefinesHandler(pluginInfo, handlerMethod);
    if (
        pluginThatDefinesHandler = Self
        and pluginInfo != Self
        and not IsHandlerMethodThatExtensionsMayUse[handlerMethod]
    ) {
        StopPlugin(
            'Sibmei\'s method \''
            & handlerMethod
            & '\' is not is not allowed to be registered as Handler method by extension \''
            & pluginInfo._extensionInfo.plugin.Name & '\''
        );
    }

    for each Name id in templatesById
    {
        if (Self = pluginInfo)
        {
            handler = CreateDictionary();
        }
        else
        {
            // Extension handlers get the API object as first argument,
            // basically the `this` argument.
            handler = CreateApiObject(pluginInfo._extensionInfo);
        }
        handler['template'] = templatesById[id];
        handler.SetMethod('HandleObject', pluginThatDefinesHandler, handlerMethod);
        handlers.@idProperty[id] = handler;
    }
}   //$end


function FindPluginThatDefinesHandler (pluginInfo, handlerMethod) {
    // Check whether the handler method is defined in either the extension or
    // Sibmei itself. Returns the plugin where the method was found. If a method
    // of that name is found in both, the extension is returned. If the method
    // was not found at all, aborts with an error.

    if (pluginInfo != Self and pluginInfo._extensionInfo.plugin.MethodExists(handlerMethod))
    {
        // It's a bit confusing. We have two classes of objects that represent
        // a Sibelius plugin. The one that can be referenced by Self or a plugin
        // name (like `libmei4` if libmei4.plg is the plugin file) is needed for
        // `SetMethod()`, the other one (that is listed in Siblius.Plugins) is
        // needed for MethodExists().
        // We can retrieve the former kind of plugin by its name:
        extensionPlgName = pluginInfo._extensionInfo.plgName;
        return @extensionPlgName;
    }

    if (SibmeiPlugin.MethodExists(handlerMethod))
    {
        return Self;
    }

    message = '`' & handlerMethod & '()` is not defined.';

    // We didn't find the method
    if (pluginInfo = Self)
    {
        StopPlugin('Internal Sibmei error: ' & message);
    }

    StopPlugin('Error in extension plugin:\n\n  ' & pluginInfo._extensionInfo.plugin.Name & '\n\n' & message);
}  //$end


function AssertIdType (pluginInfo, handlers, idProperty, functionName) {
    if (null = handlers[idProperty])
    {
        validIdProperties = CreateSparseArray();
        for each Name validIdProperty in handlers
        {
            validIdProperties.Push(validIdProperty);
        }
        Sibelius.MessageBox(
            'Error in extension plugin \''
            & pluginInfo._extensionInfo.plugin.Name
            & '\': Expected either of \''
            & validIdProperties.Join('\' or \'')
            & ' as first paramter of registration function, but found \''
            & idProperty
            & '\'.\n\nPlugin execution is aborted. To continue, deactivate or fix \''
            & pluginInfo._extensionInfo.plugin.Name
            & '\'.'
        );
    }
}  //$end


function ModifierTemplateHandler (this, bobj) {
    return GenerateModifier(bobj, MeiFactory(this.template, bobj));
}  //$end


function ControlEventTemplateHandler (this, bobj) {
    return GenerateControlEvent(bobj, MeiFactory(this.template, bobj));
}  //$end


function HandleStyle (handlers, bobj) {
    // bobj must be an object with StyleId and StyleAsText properties (i.e. a
    // Line or Text object). A matching handler for the style is looked up and
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

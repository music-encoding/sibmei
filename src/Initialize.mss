function Initialize() {
    //$module(Initialize.mss)
    Self._property:Logfile = GetTempDir() & LOGFILE;

    AddToPluginsMenu(PluginName,'Run');
}  //$end


function InitGlobals (extensions) {
    //$module(Initialize.mss)

    // `extensions` can be null or a SparseArray. See `InitExtensions()` for
    // more detailed information.

    // initialize libmei as soon as possible
    Self._property:libmei = libmei5;

    if (Sibelius.FileExists(Self._property:Logfile) = False)
    {
        Sibelius.CreateTextFile(Self._property:Logfile);
    }

    Self._property:TypeHasEndBarNumberProperty = CreateDictionary(
        // We omit 'ArpeggioLine'. It technically has an EndBarNumber property,
        // but Sibelius does not allow creating an Arpeggio with a Duration
        // other than 0, which means the EndBarNumber is always the same as the
        // start bar number.
        'BeamLine', true,
        'Bend', true,
        'Box', true,
        'CrescendoLine', true,
        'DiminuendoLine', true,
        'GlissandoLine', true,
        'Line', true,
        'OctavaLine', true,
        'PedalLine', true,
        'RepeatTimeLine', true,
        'RitardLine', true,
        'Slur', true,
        'Trill', true
    );

    Self._property:MeterSymMap = CreateDictionary(
        CommonTimeString, 'common',
        AllaBreveTimeString, 'cut',
        'c', 'common',
        'C', 'cut'
    );

    // Initialize symbol styles
    Self._property:SymbolHandlers = InitSymbolHandlers();
    Self._property:SymbolMap = InitSymbolMap();
    Self._property:LineHandlers = InitLineHandlers();
    Self._property:TextHandlers = InitTextHandlers();
    Self._property:TextSubstituteMap = InitTextSubstituteMap();

    if (not InitExtensions(extensions))
    {
        return false;
    }

    Self._property:_Initialized = true;

    return true;
}  //$end

function RegisterHandlers(handlers, handlerDefinitions, plugin, defaultTemplateHandler) {
    //$module(Initialize.mss)
    // `handlers` is a Dictionary that registers handler methods which transform
    // Sibelius objects to MEI elements.  RegisterHandlers() will create new
    // entries in `handlers` based on `handlerDefinitions`.
    // For the structure of a `handlers` Dictionary, see the following
    // pseudo-code example for lines.  Lines use the `StyleId` and `StyleAsText`
    // properties of the handled object for registering the handler methods.
    // Text handlers use the same properties, while symbol handlers use `Index`
    // and `Name`.
    // {
    //     StyleId: {
    //         // the ID is mapped to the handler method
    //         method 'line.staff.slur.down': HandleLineTemplate,
    //         // ...as well as to the template (if the handler is template-based).
    //         'line.staff.slur.down': ['Slur', {endid: 'PreciseMatch'}],
    //         // Dictionaries allow values and methods to live under the same
    //         // name, which means:
    //         //   dictionary.SetMethod('key', Self, 'method');
    //         // ... will not be overriden by:
    //         //   dictionary['key'] = 'value';
    //         // ... (and vice versa), and we can both do:
    //         //   Trace(dictionary.key); // => 'value'
    //         // ... and
    //         //   Trace(dictionary.key()); // => whatever value the method returns
    //     },
    //     StyleAsText: {
    //         // A line style that is handled with a custom, non-template based
    //         // handler method:
    //         method 'My Line': HandleMyLine,
    //         // And another one that uses a template:
    //         method 'My template based line': HandleLineTemplate,
    //         'My template based line': ['Line', {type: 'My other line'}]
    //     },
    // }
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
    //
    // `defaultTemplateHandler` is the name of the default template handler for
    // the type of objects that `handlers` works with.  This handler must be
    // supplied by Sibmei itself.  Currently, only `HandleLineTemplate` is
    // available.  For the other types (Text and Symbols) and if there are no
    // templates in `handlerDefinitions`, this paramter can be omitted.

    for each Name idType in handlers
    {
        if (null != handlerDefinitions[idType])
        {
            handlerDefinitionsForIdType = handlerDefinitions[idType];
            handlersForIdType = handlers[idType];
            for each Name id in handlerDefinitions[idType]
            {
                // handlerDefinition is either the name of the handler function
                // or a template Dictionary
                handlerDefinition = handlerDefinitionsForIdType[id];
                if (IsObject(handlerDefinition))
                {
                    handlersForIdType[id] = handlerDefinition;
                    // We have a template. Use the default handler.
                    handlersForIdType.SetMethod(id, Self, defaultTemplateHandler);
                }
                else
                {
                    handlersForIdType.SetMethod(id, plugin, handlerDefinition);
                }
            }
        }
    }
}   //$end

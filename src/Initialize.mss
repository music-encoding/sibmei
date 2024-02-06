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
    Self._property:libmei = libmei4;

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

    Self._property:SymbolHandlers = InitSymbolHandlers();
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

function RegisterHandlers(handlers, handlerDefinitions, plugin) {
    //$module(Initialize.mss)
    // `handlers` is a Dictionary that registers handler methods which transform
    // Sibelius objects to MEI elements.  RegisterHandlers() will create new
    // entries in `handlers` based on `handlerDefinitions`.
    // For the structure of a `handlers` Dictionary, see the following
    // pseudo-code example.  For Lines and Textm the `StyleId` and `StyleAsText`
    // properties of the handled object are used for registering the handler
    // methods.  For Symbols, the `Index` and `Name` properties are used.
    // {
    //     StyleId: {
    //         'line.staff.slur.down': {
    //              HandleObject: func() ControlEventTemplateHandler(this, bobj){...},
    //              template: ['Slur', {endid: 'PreciseMatch'}],
    //         }
    //     },
    //     StyleAsText: {
    //         // A line style that is handled with a custom, non-template based
    //         // handler method:
    //         'My Line': {HandleObject: func HandleMyLine(this, bobj){...}},
    //         // And another one that uses a template:
    //         'My template based line': {
    //              template: ['Line', {type: 'My other line'}],
    //              HandleObject: func ControlEventTemplateHandler(this, bobj){...},
    //         },
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

    for each Name idType in handlers
    {
        if (null != handlerDefinitions[idType])
        {
            handlerDefinitionsForIdType = handlerDefinitions[idType];
            handlersForIdType = handlers[idType];
            for each Name id in handlerDefinitions[idType]
            {
                // handlerDefinition is either the name of the handler function
                // or a template SparseArray
                handlerDefinition = handlerDefinitionsForIdType[id];
                handler = CreateDictionary();
                handlersForIdType[id] = handler;
                if (not IsObject(handlerDefinition))
                {
                    handler.SetMethod('HandleObject', plugin, handlerDefinition);
                } else {
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
        }
    }
}   //$end


function AsModifier (template) {
    // Flags the template so that RegisterHandlers() will register the
    // ModifierTemplateHandler for it.
    template._property:createModifier = true;
    return template;
}  //$end

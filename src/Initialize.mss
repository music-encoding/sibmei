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

    // Initialize symbol styles
    Self._property:SymbolHandlers = InitSymbolHandlers();
    Self._property:SymbolMap = InitSymbolMap();
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
    // Text handlers can be registered by 'idType' StyleId or StyleAsText
    // Symbol handlers can be registered by 'idType' Index or Name

    for each Name idType in handlers
    {
        if (null != handlerDefinitions[idType])
        {
            handle = handlers[idType];
            for each Name id in handlerDefinitions[idType]
            {
                handle.SetMethod(id, plugin, handlerDefinitions[idType].@id);
            }
        }
    }

}   //$end

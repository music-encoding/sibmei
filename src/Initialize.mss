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

    Self._property:FormattedText = CreateDictionary('AddFormattedText', true);
    Self._property:UnformattedText = CreateDictionary('AddUnformattedText', true);

    InitGlobalAliases(Self);

    InitSymbolHandlers();
    InitLineHandlers();
    InitTextHandlers();
    Self._property:TextSubstituteMap = InitTextSubstituteMap();

    Self._property:IsStyleIdType = CreateDictionary('StyleId', true, 'StyleAsText', true);
    Self._property:IsSymbolIdType = CreateDictionary('Index', true, 'Name', true);

    if (not InitExtensions(extensions))
    {
        return false;
    }

    Self._property:_Initialized = true;

    return true;
}  //$end


function InitGlobalAliases (plugin) {
    // Aliases that make writing/reading templates clearer
    plugin._property:Element = 'CreateSparseArray';
    plugin._property:Attrs = 'CreateDictionary';
}  //$end

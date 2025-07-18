function Initialize() {
    //$module(Initialize.mss)
    Self._property:Logfile = GetTempDir() & LOGFILE;
    Self._property:PluginName = 'Sibelius to MEI ' & MeiVersion & ' Exporter'; 

    AddToPluginsMenu(PluginName, 'Run');
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

    Self._property:BarlineTypeMap = CreateSparseArray();
    BarlineTypeMap[SpecialBarlineStartRepeat] = 'rptstart';
    BarlineTypeMap[SpecialBarlineEndRepeat] = 'rptend';
    BarlineTypeMap[SpecialBarlineDashed] = 'dashed';
    BarlineTypeMap[SpecialBarlineDouble] = 'dbl';
    BarlineTypeMap[SpecialBarlineFinal] = 'end';
    BarlineTypeMap[SpecialBarlineInvisible] = 'invis';
    BarlineTypeMap[SpecialBarlineNormal] = 'single';
    BarlineTypeMap[SpecialBarlineDotted] = 'dotted';
    BarlineTypeMap[SpecialBarlineThick] = 'heavy';
    // no MEI equiv:
    // BarlineTypeMap[SpecialBarlineBetweenStaves] = ' ';
    // BarlineTypeMap[SpecialBarlineTick] = ' ';
    // BarlineTypeMap[SpecialBarlineShort] = ' ';
    // BarlineTypeMap[SpecialBarlineTriple] = ' ';

    InitGlobalAliases(Self);

    // Sibelius apparently has a garbage collector issue with references to
    // Plugin objects. We have to keep a persistent reference to the PluginList
    // object (Sibelius.Plugins), otherwise Sibelius will crash immediately
    // whenever we use a Plugin object we retrieved from it.
    Self._property:_PluginList = Sibelius.Plugins;
    for each plugin in _PluginList
    {
        if (plugin.Name = PluginName)
        {
            Self._property:SibmeiPlugin = plugin;
        }
    }
    if (null = Self._property:SibmeiPlugin)
    {
        StopPlugin('Internal Sibmei error: Could not initialize global variable SibmeiPlugin');
    }

    InitHandlers();
    Self._property:TextSubstituteMap = InitTextSubstituteMap();

    if (not InitExtensions(extensions, _PluginList))
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

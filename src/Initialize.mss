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

    InitGlobalAliases(Self);

    Self._property:BarlineAttributes = CreateSparseArray();
    BarlineAttributes[SpecialBarlineStartRepeat] = @Attrs('left', 'rptstart');
    BarlineAttributes[SpecialBarlineEndRepeat] = @Attrs('right', 'rptend');
    BarlineAttributes[SpecialBarlineDashed] = @Attrs('right', 'dashed');
    BarlineAttributes[SpecialBarlineDouble] = @Attrs('right', 'dbl');
    BarlineAttributes[SpecialBarlineFinal] = @Attrs('right', 'end');
    BarlineAttributes[SpecialBarlineInvisible] = @Attrs('right', 'invis');
    BarlineAttributes[SpecialBarlineNormal] = @Attrs('right', 'single');
    BarlineAttributes[SpecialBarlineBetweenStaves] = @Attrs('bar.method', 'mensur');
    BarlineAttributes[SpecialBarlineTick] = @Attrs('bar.method', 'takt');
    BarlineAttributes[SpecialBarlineShort] = @Attrs('bar.len', '4', 'bar.place', '2');
    if (Sibelius.ProgramVersion >= 20201200)
    {
        BarlineAttributes[SpecialBarlineDotted] = @Attrs('right', 'dotted');
        BarlineAttributes[SpecialBarlineThick] = @Attrs('right', 'heavy');
        // no MEI equiv:
        // BarlineTypeMap[SpecialBarlineTriple] = ' ';
    }

    Self._property:ClefTemplates = CreateDictionary(
        'clef.alto',                    @Element('clef', @Attrs('shape', 'C', 'line', '3')),
        'clef.baritone.c',              @Element('clef', @Attrs('shape', 'C', 'line', '5')),
        'clef.baritone.f',              @Element('clef', @Attrs('shape', 'F', 'line', '3')),
        'clef.bass',                    @Element('clef', @Attrs('shape', 'F', 'line', '4')),
        'clef.bass.down.8',             @Element('clef', @Attrs('shape', 'F', 'line', '4', 'dis', '8',  'dis.place', 'below')),
        'clef.bass.up.15',              @Element('clef', @Attrs('shape', 'F', 'line', '4', 'dis', '15', 'dis.place', 'above')),
        'clef.bass.up.8',               @Element('clef', @Attrs('shape', 'F', 'line', '4', 'dis', '8',  'dis.place', 'above')),
        // Sibelius categorizes clef.null as percussion clef. It effectively
        // works like a hidden percussion clef.
        'clef.null',                    @Element('clef', @Attrs('shape', 'perc', 'visible', 'false')),
        'clef.percussion',              @Element('clef', @Attrs('shape', 'perc')),
        'clef.percussion_2',            @Element('clef', @Attrs('shape', 'perc', 'glyph.auth', 'smufl', 'glyph.num', 'U+E06A')),
        'clef.soprano',                 @Element('clef', @Attrs('shape', 'C', 'line', '1')),
        'clef.soprano.mezzo',           @Element('clef', @Attrs('shape', 'C', 'line', '2')),
        'clef.tab',                     @Element('clef', @Attrs('shape', 'TAB')),
        'clef.tab.small',               @Element('clef', @Attrs('shape', 'TAB', 'fontsize', 'small')),
        // There is not a huge visual difference between 'clef.tab.small' and
        // 'clef.tab.small.taller' with Sibelius' built-in fonts
        'clef.tab.small.taller',        @Element('clef', @Attrs('shape', 'TAB', 'fontsize', 'small')),
        'clef.tab.taller',              @Element('clef', @Attrs('shape', 'TAB', 'fontsize', 'large')),
        'clef.tenor',                   @Element('clef', @Attrs('shape', 'C', 'line', '4')),
        'clef.tenor.down.8',            @Element('clef', @Attrs('shape', 'C', 'line', '4', 'dis', '8', 'dis.place', 'below')),
        'clef.treble',                  @Element('clef', @Attrs('shape', 'G', 'line', '2')),
        'clef.treble.down.8',           @Element('clef', @Attrs('shape', 'G', 'line', '2', 'dis', '8', 'dis.place', 'below')),
        'clef.treble.down.8.bracketed', @Element('clef', @Attrs('shape', 'G', 'line', '2', 'dis', '8', 'dis.place', 'below', 'glyph.auth', 'smufl', 'glyph.num', 'U+E057')),
        'clef.treble.down.8.old',       @Element('clef', @Attrs('shape', 'GG', 'line', '2')),
        'clef.treble.up.15',            @Element('clef', @Attrs('shape', 'G', 'line', '2', 'dis', '15', 'dis.place', 'above')),
        'clef.treble.up.8',             @Element('clef', @Attrs('shape', 'G', 'line', '2', 'dis', '8', 'dis.place', 'above')),
        'clef.violin.french',           @Element('clef', @Attrs('shape', 'G', 'line', '1')),
        'clef.sub-bass.f',              @Element('clef', @Attrs('shape', 'F', 'line', '5'))
    );

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

    Self._property:SchemaLocation = DefaultSchemaLocation;
    Self._property:ApiSemver = SplitString(ExtensionAPIVersion, '.');
    if (not InitExtensions(extensions, _PluginList))
    {
        return false;
    }

    InitXmlGlobals();

    // The Voices property of BarObjects is a bitmask.  The lookup table
    // VoiceNumbers provides lists of all the voices in a bitmask, LayerNumbers
    // the appropriate value for @layer attributes and VoicesMaskToVoiceFlags
    // allows to check if a voice number is included in a Voices bitmask.
    Self._property:VoiceNumbers = CreateSparseArray();
    Self._property:LayerNumbers = CreateSparseArray();
    // Keys are voice bitmasks, values are lookup SparseArrays where keys are
    // voice numbers are true if the bitmask includes the voice number.
    Self._property:VoicesMaskToVoiceFlags = CreateSparseArray();
    // We start with bitmask value 0, although this value might not be in use
    for voicesBitmask = 0 to 16
    {
        voiceNumbersOfBitmask = CreateSparseArray();
        VoiceNumbers[voicesBitmask] = voiceNumbersOfBitmask;
        voiceFlags = CreateSparseArray();
        VoicesMaskToVoiceFlags[voicesBitmask] = voiceFlags;
        bitshiftedVoicesValue = voicesBitmask;
        for voiceNumber = 1 to 5
        {
            voiceFlags[voiceNumber] = bitshiftedVoicesValue % 2 = 1;
            if (voiceFlags[voiceNumber])
            {
                VoiceNumbers[voicesBitmask].Push(voiceNumber);
            }
            bitshiftedVoicesValue = bitshiftedVoicesValue / 2;
        }
        LayerNumbers[voicesBitmask] = VoiceNumbers[voicesBitmask].Join(' ');
    }

    Self._property:_Initialized = true;

    return true;
}  //$end


function InitGlobalAliases (plugin) {
    // Aliases that make writing/reading templates clearer
    plugin._property:Element = 'CreateSparseArray';
    plugin._property:Attrs = 'CreateDictionary';
}  //$end

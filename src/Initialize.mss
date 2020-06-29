function Initialize() {
    Self._property:Logfile = GetTempDir() & LOGFILE;

    AddToPluginsMenu(PluginName,'Run');
}  //$end


function InitGlobals () {
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
    InitSymbolHandlers();

}  //$end

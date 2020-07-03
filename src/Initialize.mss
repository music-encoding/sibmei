function Initialize() {
    //$module(Initialize.mss)
    Self._property:Logfile = GetTempDir() & LOGFILE;

    AddToPluginsMenu(PluginName,'Run');
}  //$end


function InitGlobals () {
    //$module(Initialize.mss)
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


function RegisterExtensions () {
    // Stores any found extensions in the global AvailableExtensions TreeDict
    // Hash object. Keys are the names by which they can be be referenced in
    // ManuScript, e.g. like `@name.SibmeiExtensionAPIVersion`. Values are
    // the full name that is displayed to the user.

    apiSemver = SplitString(ExtensionAPIVersion, '.');
    errors = '';

    for each pluginObject in Sibelius.Plugins
    {
        if (pluginObject.DataExists('SibmeiExtensionAPIVersion'))
        {
            plgName = pluginObject.File.NameNoPath;
            extensionSemver = SplitString(@plgName.SibmeiExtensionAPIVersion, '.');

            switch (true)
            {
                case (extensionSemver.NumChildren != 3)
                {
                    error = 'Extension %s must have a valid semantic versioning string in field `ExtensionAPIVersion`';
                }
                case ((apiSemver[0] = extensionSemver[0]) and (apiSemver[1] >= extensionSemver[1]))
                {
                    error = null;
                }
                case ((apiSemver[0] < extensionSemver[0]) or (apiSemver[1] < extensionSemver[1]))
                {
                    error = 'Extension %s requires Sibmei to be updated to a newer version';
                }
                default
                {
                    error = 'Extension %s needs to be updated to be compatible with the current Sibmei version';
                }
            }

            if (null = error)
            {
                // Storing key/value pairs in old-style Hash TreeNodes needs @-indirection
                AvailableExtensions.@plgName = pluginObject.Name;
            }
            else
            {
                errors = errors & utils.Format(error, plgName) & '\n';
            }
        }
    }

    return errors;
}  //$end

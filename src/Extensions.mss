function RegisterAvailableExtensions (availableExtensions) {
    //$module(Initialize.mss)
    // Expects and empty TreeNode Hash map object as argument.
    // Looks for existing extensions and registers them in this Hash map.
    // Keys in the Hash map are the names by which the extension plugins can be
    // referenced in ManuScript, e.g. like `@name.SibmeiExtensionAPIVersion`.
    // Values are the full names that are displayed to the user.

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
                availableExtensions.@plgName = pluginObject.Name;
            }
            else
            {
                errors = errors & utils.Format(error, plgName) & '\n';
            }
        }
    }

    return errors;
}  //$end


function ChooseExtensions (availableExtensions, chosenExtensions) {
    // Expects an empty Dictionary as second argument.
    // Runs the ExtensionDialog and stores all extensions the user chose in the
    // Dictionary. Adds key/value pairs in the same way as
    // RegisterAvailableExtensions()
    // Returns true on success, false if the user canceled the dialog.

    if (not Sibelius.ShowDialog(ExtensionDialog, Self))
    {
        return false;
    }
    // Unfortunately, SelectedExtensions only has the selected values from the
    // AvailableExtensions object, i.e. the extension plugin's full user facing
    // name, not the PLG name that we need to reference it in ManuScript.
    extensionIsSelected = CreateDictionary();
    for each fullExtensionName in SelectedExtensions
    {
        extensionIsSelected[fullExtensionName] = true;
    }
    for each extension in AvailableExtensions
    {
        // Cast TreeNode Hash object to its string value
        fullExtensionName = extension & '';
        if (extensionIsSelected[extension])
        {
            plgName = extension.Label;
            chosenExtensions[plgName] = fullExtensionName;
        }
    }

    return true;
}  //$end


function SelectAllExtensions () {
    SelectedExtensions = AvailableExtensions;
    Sibelius.RefreshDialog();
}  //$end


function DeselectAllExtensions () {
    SelectedExtensions = CreateHash();
    Sibelius.RefreshDialog();
}  //$end


function InitExtensions (extensions) {
    // To let the user choose extensions via dialog, pass `null` as argument.
    // If extensions should be activated without showing the  dialog, pass a
    // SparseArray with the 'PLG names' of the extensions, i.e. the names that
    // `RegisterAvailableExtensions()` will use as keys. This is useful e.g.
    // for running tests without requiring user interaction.
    //
    // Returns false if the user aborted the selection of extensions or if there
    // are any errors, otherwise returns true.

    AvailableExtensions = CreateHash();
    errors = RegisterAvailableExtensions(AvailableExtensions);
    if (null != errors)
    {
        Sibelius.MessageBox(errors);
        return false;
    }

    chosenExtensions = CreateDictionary();
    if (null = extensions)
    {
        if (not ChooseExtensions(AvailableExtensions, chosenExtensions))
        {
            return false;
        }
    } else {
        for each plgName in extensions
        {
            chosenExtensions[plgName] = AvailableExtensions[plgName];
        }
    }

    apiObject = CreateApiObject();

    for each Name plgName in chosenExtensions
    {
        @plgName.InitSibmeiExtension(apiObject);
    }

    return true;
}  //$end


function CreateApiObject () {
    apiObject = CreateDictionary('libmei', libmei);
    apiObject.SetMethod('RegisterSymbolHandlers', Self, 'ExtensionAPI_RegisterSymbolHandlers');
    apiObject.SetMethod('RegisterTextHandlers', Self, 'ExtensionAPI_RegisterTextHandlers');
    apiObject.SetMethod('MeiFactory', Self, 'ExtensionAPI_MeiFactory');
    apiObject.SetMethod('HandleControlEvent', Self, 'HandleControlEvent');
    apiObject.SetMethod('HandleModifier', Self, 'HandleModifier');
    apiObject.SetMethod('AddFormattedText', Self, 'ExtensionAPI_AddFormattedText');
    return apiObject;
}  //$end

function ExtensionAPI_RegisterSymbolHandlers (this, symbolHandlerDict, plugin) {
    RegisterHandlers(Self._property:SymbolHandlers, symbolHandlerDict, plugin);
}  //$end

function ExtensionAPI_RegisterTextHandlers (this, textHandlerDict, plugin) {
    RegisterHandlers(Self._property:TextHandlers, textHandlerDict, plugin);
}  //$end

function ExtensionAPI_MeiFactory (this, templateObject) {
    MeiFactory(templateObject);
}  //$end

function ExtensionAPI_AddFormattedText (this, parentElement, textObj) {
    AddFormattedText (parentElement, textObj);
}   //$end

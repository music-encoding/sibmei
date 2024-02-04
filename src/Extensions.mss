function RegisterAvailableExtensions (availableExtensions, apiVersionByPlgName) {
    //$module(Initialize.mss)
    // Expects and empty TreeNode Hash map object as argument.
    // Looks for existing extensions and registers them in this Hash map.
    // Keys in the Hash map are the names by which the extension plugins can be
    // referenced in ManuScript, e.g. like `@name.SibmeiExtensionAPIVersion`.
    // Values are the full names that are displayed to the user.

    apiSemver = SplitString(ExtensionAPIVersion, '.');
    errors = CreateSparseArray();

    for each pluginObject in Sibelius.Plugins
    {
        if (pluginObject.DataExists('SibmeiExtensionAPIVersion'))
        {

            plgName = pluginObject.File.NameNoPath;
            extensionSemverString = @plgName.SibmeiExtensionAPIVersion;
            extensionSemver = SplitString(extensionSemverString, '.');
            apiVersion = apiSemver[0];

            switch (true)
            {
                case (extensionSemver.NumChildren != 3)
                {
                    error = 'Extension %s must have a valid semantic versioning string in field `ExtensionAPIVersion`. \'%s\' is not a valid version string.';
                }
                case ((apiSemver[0] = extensionSemver[0]) and (apiSemver[1] >= extensionSemver[1]))
                {
                    error = null;
                }
                case (
                    (apiSemver[0] < extensionSemver[0])
                    or (apiSemver[0] = extensionSemver[0] and apiSemver[1] < extensionSemver[1])
                )
                {
                    error = 'Extension %s requires extension API version %s, but Sibmei %s only supports extension API version %s. Check for Sibmei updates supporting that extension API version.';
                }
                default
                {
                    error = 'Extension %s needs to be updated to be compatible with the current Sibmei version';
                }
            }

            apiVersionByPlgName[plgName] = extensionSemver[0] + 0;

            if (null = error)
            {
                // Storing key/value pairs in old-style Hash TreeNodes needs @-indirection
                availableExtensions.@plgName = pluginObject.Name;
            }
            else
            {
                errors.Push(utils.Format(error, plgName, extensionSemverString, Version, ExtensionAPIVersion));
            }
        }
    }

    return errors.Join('\n\n');
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
    apiVersionByPlgName = CreateDictionary();
    errors = RegisterAvailableExtensions(AvailableExtensions, apiVersionByPlgName);
    if (null != errors)
    {
        Sibelius.MessageBox(errors);
    }

    chosenExtensions = CreateDictionary();
    if (null = extensions)
    {
        if (not ChooseExtensions(AvailableExtensions, chosenExtensions))
        {
            return false;
        }
    }
    else
    {
        for each plgName in extensions
        {
            // Attention, choose AvailableExtensions with .@
            chosenExtensions[plgName] = AvailableExtensions.@plgName;
        }
    }

    apiObjects = CreateSparseArray();
    apiObjects[1] = CreateApiObject(1);
    apiObjects[2] = CreateApiObject(2);

    for each Name plgName in chosenExtensions
    {
        @plgName.InitSibmeiExtension(apiObjects[apiVersionByPlgName[plgName]]);
    }

    // store chosenExtensions as global to add application info
    Self._property:ChosenExtensions = chosenExtensions;

    return true;
}  //$end


function CreateApiObject (apiVersion) {
    apiObject = CreateDictionary(
        'libmei', libmei,
        'AddFormattedText', CreateDictionary('AddFormattedText', true),
        'AddUnformattedText', CreateDictionary('AddUnformattedText', true)
    );
    apiObject.SetMethod('RegisterSymbolHandlers', Self, 'ExtensionAPI_RegisterSymbolHandlers');
    apiObject.SetMethod('RegisterTextHandlers', Self, 'ExtensionAPI_RegisterTextHandlers');
    apiObject.SetMethod('RegisterLineHandlers', Self, 'ExtensionAPI_RegisterLineHandlers');
    switch (apiVersion)
    {
        case (1)
        {
            apiObject.SetMethod('MeiFactory', Self, 'ExtensionAPI_MeiFactory_LegacyApiVersion1');
            apiObject.SetMethod('HandleLineTemplate', Self, 'HandleControlEvent');
        }
        case (2) {
            apiObject.SetMethod('MeiFactory', Self, 'ExtensionAPI_MeiFactory');
        }
        default
        {
            ExitPlugin('Unsupported extension API version: ' & apiVersion);
        }
    }
    apiObject.SetMethod('HandleControlEvent', Self, 'HandleControlEvent');
    apiObject.SetMethod('HandleModifier', Self, 'HandleModifier');
    apiObject.SetMethod('AddFormattedText', Self, 'ExtensionAPI_AddFormattedText');
    apiObject.SetMethod('GenerateControlEvent', Self, 'ExtensionAPI_GenerateControlEvent');
    apiObject.SetMethod('AddControlEventAttributes', Self, 'ExtensionAPI_AddControlEventAttributes');
    // TODO: Deprecate HandleLineTemplate and replace with HandleControlEvent?
    apiObject.SetMethod('HandleLineTemplate', Self, 'HandleControlEvent');
    return apiObject;
}  //$end

function ExtensionAPI_RegisterSymbolHandlers (this, symbolHandlerDict, plugin) {
    RegisterHandlers(Self._property:SymbolHandlers, symbolHandlerDict, plugin, 'HandleTemplate');
}  //$end

function ExtensionAPI_RegisterTextHandlers (this, textHandlerDict, plugin) {
    RegisterHandlers(Self._property:TextHandlers, textHandlerDict, plugin, 'HandleControlEvent');
}  //$end

function ExtensionAPI_RegisterLineHandlers (this, lineHandlerDict, plugin) {
    RegisterHandlers(Self._property:LineHandlers, lineHandlerDict, plugin, 'HandleControlEvent');
}  //$end

function ExtensionAPI_MeiFactory (this, templateObject, bobj) {
    MeiFactory(templateObject, bobj);
}  //$end

function ExtensionAPI_MeiFactory_LegacyApiVersion1 (this, templateObject) {
    MeiFactory(templateObject, null);
}  //$end

function ExtensionAPI_AddFormattedText (this, parentElement, textObj) {
    AddFormattedText (parentElement, textObj);
}   //$end

function ExtensionAPI_GenerateControlEvent (this, bobj, elementName) {
    GenerateControlEvent(bobj, elementName);
}   //$end

function ExtensionAPI_AddControlEventAttributes (this, bobj, element) {
    AddControlEventAttributes(bobj, element);
}   //$end


function HandleTemplate (this, bobj, template) {
    element = MeiFactory(template, bobj);
    AddControlEventAttributes(bobj, element);
    return element;
}   //$end

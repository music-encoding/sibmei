function RegisterAvailableExtensions (availableExtensions, extensionsInfo, pluginList) {
    // `availableExtensions` must be an empty TreeNode Hash map object.
    // Looks for existing extensions and registers them in this Hash map.
    // Keys in the Hash map are the names by which the extension plugins can be
    // referenced in ManuScript, e.g. like `@name.SibmeiExtensionAPIVersion`.
    // Values are the full names that are displayed to the user.
    //
    // `extensionsInfo` must be an empty Dictionary. For each extension plugin,
    // a sub-Dictionary with some information about the extension plugin is
    // registered under its PLG name as key. Fields in the sub-Dictionary are:
    //   * `plgName`: Same value that is used as the key in `extensionsInfo`
    //   * `plugin`: The extension's Plugin object (from Sibelius.Plugins)
    //   * `apiVersion`: The major version number of the used extension API
    //
    // `pluginList` is a persistent reference to `Sibelius.Plugins`.

    apiSemver = SplitString(ExtensionAPIVersion, '.');
    errors = CreateSparseArray();

    for each pluginObject in pluginList
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

            extensionsInfo[plgName] = CreateDictionary(
                'plgName', plgName,
                'plugin', pluginObject,
                'apiVersion', extensionSemver[0] + 0
            );

            if (null = error)
            {
                // Storing key/value pairs in old-style Hash TreeNodes needs @-indirection
                availableExtensions.@plgName = pluginObject.Name;
            }
            else
            {
                errors.Push(utils.Format(error, plgName, extensionSemverString, PluginVersion, ExtensionAPIVersion));
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


function InitExtensions (extensions, pluginList) {
    // To let the user choose extensions via dialog, pass `null` as `extensions`
    // argument. If extensions should be activated without showing the dialog,
    // pass a SparseArray with the 'PLG names' of the extensions, i.e. the
    // names that `RegisterAvailableExtensions()` will use as keys. This is
    // useful, e.g., for running tests without requiring user interaction.
    //
    // `pluginList` is the list of all installed Sibelius plugins.
    //
    // Returns false if the user aborted the selection of extensions or if there
    // are any errors, otherwise returns true.

    AvailableExtensions = CreateHash();
    extensionsInfo = CreateDictionary();
    errors = RegisterAvailableExtensions(AvailableExtensions, extensionsInfo, pluginList);
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

    for each Name plgName in chosenExtensions
    {
        if (extensionsInfo[plgName].apiVersion >= 2)
        {
            InitGlobalAliases(@plgName);
        }
        @plgName.InitSibmeiExtension(CreateApiObject(extensionsInfo[plgName]));
    }

    // store chosenExtensions as global to add application info
    Self._property:ChosenExtensions = chosenExtensions;

    return true;
}  //$end


function CreateApiObject (extensionInfo) {
    apiObject = CreateDictionary(
        '_extensionInfo', extensionInfo,
        'FormattedText', FormattedText,
        'UnformattedText', UnformattedText,
        'LyricText', LyricText
    );

    if (extensionInfo.apiVersion != 2)
    {
        StopPlugin('Unsupported extension API version: ' & extensionInfo.apiVersion);
    }

    apiObject.SetMethod('RegisterSymbolHandlers', Self, 'ExtensionAPI_RegisterSymbolHandlers');
    apiObject.SetMethod('RegisterTextHandlers', Self, 'ExtensionAPI_RegisterTextHandlers');
    apiObject.SetMethod('RegisterLineHandlers', Self, 'ExtensionAPI_RegisterLineHandlers');
    apiObject.SetMethod('RegisterLyricHandlers', Self, 'ExtensionAPI_RegisterLyricHandlers');
    apiObject.SetMethod('MeiFactory', Self, 'ExtensionAPI_MeiFactory');
    apiObject.SetMethod('AddFormattedText', Self, 'AddFormattedText');
    apiObject.SetMethod('GenerateControlEvent', Self, 'ExtensionAPI_GenerateControlEvent');
    apiObject.SetMethod('GenerateModifier', Self, 'ExtensionAPI_GenerateModifier');
    apiObject.SetMethod('AppendToMeasure', Self, 'ExtensionAPI_AppendToMeasure');
    apiObject.SetMethod('XMLComment', Self, 'ExtensionAPI_XMLComment');
    apiObject.SetMethod('CreateElement', Self, 'ExtensionAPI_CreateElement');
    apiObject.SetMethod('GetChildren', Self, 'ExtensionAPI_GetChildren');
    apiObject.SetMethod('AddChild', Self, 'ExtensionAPI_AddChild');
    apiObject.SetMethod('AddChildAtPosition', Self, 'ExtensionAPI_AddChildAtPosition');
    apiObject.SetMethod('RemoveChild', Self, 'ExtensionAPI_RemoveChild');
    apiObject.SetMethod('GetAttribute', Self, 'ExtensionAPI_GetAttribute');
    apiObject.SetMethod('GetAttributes', Self, 'ExtensionAPI_GetAttributes');
    apiObject.SetMethod('AddAttribute', Self, 'ExtensionAPI_AddAttribute');
    apiObject.SetMethod('RemoveAttribute', Self, 'ExtensionAPI_RemoveAttribute');
    apiObject.SetMethod('GetId', Self, 'ExtensionAPI_GetId');
    apiObject.SetMethod('SetId', Self, 'ExtensionAPI_SetId');
    apiObject.SetMethod('GetName', Self, 'ExtensionAPI_GetName');
    apiObject.SetMethod('SetText', Self, 'ExtensionAPI_SetText');
    apiObject.SetMethod('GetText', Self, 'ExtensionAPI_GetText');
    apiObject.SetMethod('SetTail', Self, 'ExtensionAPI_SetTail');
    apiObject.SetMethod('GetTail', Self, 'ExtensionAPI_GetTail');
    apiObject.SetMethod('GetElementById', Self, 'ExtensionAPI_GetElementById');

    return apiObject;
}  //$end

function ExtensionAPI_RegisterSymbolHandlers (this, idProperty, handlerMethod, templatesById) {
    RegisterHandlers(this, SymbolHandlers, idProperty, handlerMethod, templatesById);
}  //$end

function ExtensionAPI_RegisterTextHandlers (this, idProperty, handlerMethod, templatesById) {
    RegisterHandlers(this, TextHandlers, idProperty, handlerMethod, templatesById);
}  //$end

function ExtensionAPI_RegisterLineHandlers (this, idProperty, handlerMethod, templatesById) {
    RegisterHandlers(this, LineHandlers, idProperty, handlerMethod, templatesById);
}  //$end

function ExtensionAPI_RegisterLyricHandlers (this, idProperty, handlerMethod, templatesById) {
    PreprocessLyricTemplates(templatesById);
    RegisterHandlers(this, LyricHandlers, idProperty, handlerMethod, templatesById);
}  //$end

function ExtensionAPI_MeiFactory (this, templateObject, bobj) {
    MeiFactory(templateObject, bobj);
}  //$end

function ExtensionAPI_MeiFactory_LegacyApiVersion1 (this, templateObject) {
    MeiFactory(templateObject, null);
}  //$end

function ExtensionAPI_GenerateControlEvent (this, bobj, element) {
    GenerateControlEvent(bobj, element);
}   //$end

function ExtensionAPI_GenerateModifier (this, bobj, element) {
    GenerateModifier(bobj, element);
}   //$end

function ExtensionAPI_AppendToMeasure (this, element) {
    MeasureObjects.Push(element._id);
    return element;
}   //$end

function ExtensionAPI_XMLComment (this, comment) {
    return XMLComment(comment);
} // $end

function ExtensionAPI_CreateElement (this, tagname) {
    return CreateElement(tagname);
} // $end

function ExtensionAPI_GetChildren (this, element) {
    return GetChildren(element);
} // $end

function ExtensionAPI_AddChild (this, element, child) {
    return AddChild(element, child);
} // $end

function ExtensionAPI_AddChildAtPosition (this, element, child, position) {
    return AddChildAtPosition(element, child, position);
} // $end

function ExtensionAPI_RemoveChild (this, element, child) {
    return RemoveChild(element, child);
} // $end

function ExtensionAPI_GetAttribute (this, element, attrname) {
    return GetAttribute(element, attrname);
} // $end

function ExtensionAPI_GetAttributes (this, element) {
    return GetAttributes(element);
} // $end

function ExtensionAPI_AddAttribute (this, element, attrname, attrval) {
    return AddAttribute(element, attrname, attrval);
} // $end

function ExtensionAPI_RemoveAttribute (this, element, attrname) {
    return RemoveAttribute(element, attrname);
} // $end

function ExtensionAPI_GetId (this, element) {
    return GetId(element);
} // $end

function ExtensionAPI_SetId (this, element, newId) {
    return SetId(element, newId);
} // $end

function ExtensionAPI_GetName (this, element) {
    return GetName(element);
} // $end

function ExtensionAPI_SetText (this, ) {
    return SetText();
} // $end

function ExtensionAPI_GetText (this, element) {
    return GetText(element);
} // $end

function ExtensionAPI_SetTail (this, element, val) {
    return SetTail(element, val);
} // $end

function ExtensionAPI_GetTail (this, element) {
    return GetTail(element);
} // $end

function ExtensionAPI_GetElementById (this, id) {
    return GetElementById(id);
} // $end

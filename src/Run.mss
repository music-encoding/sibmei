function Run() {
    //$module(Run.mss)

    // do some preliminary checks
    if (Sibelius.ProgramVersion < 7000)
    {
        Sibelius.MessageBox(_VersionNotSupported);
        return False;
    }

    if (Sibelius.ScoreCount = 0)
    {
        Sibelius.MessageBox(_ScoreError);
        return False;
    }

    // get the active score object
    activeScore = Sibelius.ActiveScore;

    // it does not seem possible to get the current folder for the file
    // so we will default to the user's documents folder.
    // NB: it seems that if we don't specify a folder name, the filename
    // is not properly set.
    activeFileNameFull = activeScore.FileName;
    activeFileName = utils.ExtractFileName(activeFileNameFull);
    activePath = Sibelius.GetDocumentsFolder();

    ChooseExtensions();

    // Ask to the file to be saved somewhere
    filename = Sibelius.SelectFileToSave('Save as...', activeFileName, activePath, 'mei', 'TEXT', 'Music Encoding Initiative');

    if (filename = null)
    {
        Sibelius.MessageBox(_ExportFileIsNull);
        return False;
    }

    DoExport(filename);

}  //$end

function DoExport (filename) {
    //$module(Run.mss)

    // first, ensure we're running with a clean slate.
    Self._property:libmei = libmei4;
    libmei.destroy();

    InitGlobals();

    // set the active score here so we can refer to it throughout the plugin
    Self._property:ActiveScore = Sibelius.ActiveScore;
    if (Self._property:ActiveScore = null)
    {
        Sibelius.MessageBox('Could not find an active score. Cannot export to ' & filename);
        return false;
    }

    // Set up the warnings tracker
    Self._property:warnings = CreateSparseArray();

    // Deal with the Progress GUI
    progCount = Sibelius.ActiveScore.SystemStaff.BarCount;
    fn = utils.ExtractFileName(filename);
    progressTitle = utils.Format(_InitialProgressTitle, fn);
    Sibelius.CreateProgressDialog(progressTitle, 0, progCount - 1);

    // finally, process the score.
    ProcessScore();

    doc = libmei.getDocument();
    // save the file
    export_status = libmei.meiDocumentToFile(doc, filename);

    // start cleaning up.
    Sibelius.DestroyProgressDialog();

    // display the warnings that were registered during the export process
    for each warning in Self._property:warnings
    {
        trace('Warning: ' & warning);
    }

    if (export_status = False)
    {
        Sibelius.MessageBox(_ExportFailure);
    }

    // clean up after ourself
    libmei.destroy();
}  //$end


function ChooseExtensions () {
    AvailableExtensions = CreateHash();
    extensionErrors = RegisterExtensions();
    if (extensionErrors != '')
    {
        Sibelius.MessageBox(extensionErrors);
    }
    if (not Sibelius.ShowDialog(ExtensionDialog, Self))
    {
        return null;
    }
    // Unfortunately, SelectedExtensions only has the values from the AvailableExtensions
    // object.
    extensionIsSelected = CreateDictionary();
    for each extension in SelectedExtensions
    {
        extensionIsSelected[extension] = true;
    }
    for each extension in AvailableExtensions
    {
        // Cast TreeNode Hash object to its string value
        fullExtensionName = extension & '';
        if (extensionIsSelected[extension])
        {
            plgName = extension.Label;
            // TODO: Register all symbol and text handlers provided by this
            // plugin
            Trace(plgName);
        }
    }
}  //$end


function ActivateAllExtensions () {
    SelectedExtensions = AvailableExtensions;
    Sibelius.RefreshDialog();
}  //$end


function DeactivateAllExtensions () {
    SelectedExtensions = CreateHash();
    Sibelius.RefreshDialog();
}  //$end

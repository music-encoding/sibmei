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

    if (Sibelius.FileExists(activeScore.FileName)) {
        scoreFile = Sibelius.GetFile(activeScore.FileName);
        activeFileName = scoreFile.NameNoPath & '.mei';
        activePath = scoreFile.Path;
    } else {
        activeFileName = 'untitled.mei';
        activePath = Sibelius.GetDocumentsFolder();
    }

    if (not InitGlobals(null))
    {
        return false;
    }

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

    if (not Self._property:_Initialized)
    {
        Trace('InitGlobals() must be called before running DoExport()');
        return null;
    }

    // first, ensure we're running with a clean slate.
    // (initialization of libmei has moved to InitGlobals())
    libmei.destroy();

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

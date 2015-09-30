function Run() {
    //$module(Run.mss)

    // first, ensure we're running with a clean slate.
    libmei.destroy();

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

    // Set up the warnings tracker
    Self._property:warnings = CreateSparseArray();

    // Ask to the file to be saved somewhere
    filename = Sibelius.SelectFileToSave('Save as...', False, False, 'mei', 'TEXT', 'Music Encoding Initiative');

    if (filename = null)
    {
        Sibelius.MessageBox(_ExportFileIsNull);
        return False;
    }

    // Deal with the Progress GUI
    // set the active score here so we can refer to it throughout the plugin
    Self._property:ActiveScore = Sibelius.ActiveScore;

    progCount = Sibelius.ActiveScore.SystemStaff.BarCount;
    fn = utils.ExtractFileName(filename);
    progressTitle = utils.Format(_InitialProgressTitle, fn);
    Sibelius.CreateProgressDialog(progressTitle, 0, progCount - 1);

    // finally, process the score.
    sibmei2.ProcessScore();

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

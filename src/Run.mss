function Run() {
    //$module(Run.mss)

    if (not InitGlobals(null))
    {
        return null;
    }

    error = DoExport(Sibelius.ActiveScore, null);

    if (null != error)
    {
        Sibelius.MessageBox(error);
    }

}  //$end


function GetExportFileName (score) {
    if (Sibelius.FileExists(score.FileName)) {
        scoreFile = Sibelius.GetFile(score.FileName);
        activeFileName = scoreFile.NameNoPath & '.mei';
        activePath = scoreFile.Path;
    } else {
        activeFileName = 'untitled.mei';
        activePath = Sibelius.GetDocumentsFolder();
    }

    filename = Sibelius.SelectFileToSave('Save as...', activeFileName, activePath, 'mei', 'TEXT', 'Music Encoding Initiative');

    return filename;
} //$end


function DoExport (score, filename) {
    //$module(Run.mss)

    // Argument filename is optional and will be determined automatically if
    // `null` is passed in instead. The filename is also returned so the
    // caller can then work with.

    // do some preliminary checks
    if (Sibelius.ProgramVersion < 7000)
    {
        return _VersionNotSupported;
    }

    if (Sibelius.ScoreCount = 0)
    {
        return _ScoreError;
    }

    if (null = filename)
    {
        filename = GetExportFileName(score);
        if (null = filename)
        {
            Sibelius.MessageBox(_ExportFileIsNull);
            return null;
        }
    }

    if (not Self._property:_Initialized)
    {
        return 'InitGlobals() must be called before running DoExport()';
    }

    // first, ensure we're running with a clean slate.
    // (initialization of libmei has moved to InitGlobals())
    libmei.destroy();

    // set the active score here so we can refer to it throughout the plugin
    Self._property:ActiveScore = score;
    if (Self._property:ActiveScore = null)
    {
        return 'Could not find an active score. Cannot export to ' & filename;
    }

    // Set up the warnings tracker
    Self._property:warnings = CreateSparseArray();

    // Deal with the Progress GUI
    progCount = score.SystemStaff.BarCount;
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

    // clean up after ourself
    libmei.destroy();

    if (export_status = False)
    {
        return 'The file was not exported. File:\n\n' & filename & '\n\ncould not be written.';
    }
}  //$end


function ExportBatch (files, extensions) {
    if (not InitGlobals(extensions))
    {
        return null;
    }

    utils.SortArray(files, false);

    numFiles = files.Length;
    exportCount = 0;

    for index = 0 to numFiles
    {
        file = Sibelius.GetFile(files[index]);

        score = GetScore(file);

        if (null = score)
        {
            continue = Sibelius.YesNoMessageBox('File could not be opened:\n\n' & file & '\n\nContinue anyway?');
            if (not continue)
            {
                return false;
            }
        }
        else
        {
            // NB: DO NOT CHANGE THIS EXTENSION PLEASE.
            error = DoExport(score, file.Name & '.mei');
            if (Sibelius.ProgramVersion >= 20201200)
            {
                Sibelius.CloseAllWindowsForScore(score, false);
            }
            else
            {
                Sibelius.CloseWindow(False);
            }
            if (null = error)
            {
                exportCount = exportCount + 1;
            }
            else
            {
                if (not Sibelius.YesNoMessageBox(error & '\n\nContinue anyway?'))
                {
                    return false;
                }
            }
        }
    }

    Sibelius.DestroyProgressDialog();

    Sibelius.MessageBox(exportCount & ' of ' & numFiles & ' files were exported.');

    return true;
}  //$end


function GetScore (file) {
    Sibelius.Open(file, true);

    // If the score was already open, it can happen that it is not made the
    // ActiveScore by Sibelius.Open(). So we can't rely on Sibelius.ActiveScore
    // and loop over all the scores to fetch the score.
    for each score in Sibelius
    {
        // As FileName and file are objects, cast them to strings,
        // otherwise the comparison does not work
        if ((score.FileName & '') = (file & ''))
        {
            return score;
        }
    }

    return null;
}  //$end

function Run() {
    //$module(Run.mss)

    if (not InitGlobals(null))
    {
        return null;
    }

    InitWarningsTracker();
    error = DoExport(Sibelius.ActiveScore, null);

    if (null != error)
    {
        InformAboutResults(error, false);
    }
    else
    {
        InformAboutResults('Done', false);
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
            return _ExportFileIsNull;
        }
    }

    if (not Self._property:_Initialized)
    {
        return 'InitGlobals() must be called before running DoExport()';
    }

    // first, ensure we're running with a clean slate.
    ResetXml();
    SetGlobalsForScore(score);

    // Deal with the Progress GUI
    progCount = SystemStaff.BarCount;
    fn = utils.ExtractFileName(filename);
    progressTitle = utils.Format(_InitialProgressTitle, fn);
    Sibelius.CreateProgressDialog(progressTitle, 0, progCount - 1);

    // finally, process the score.
    ProcessScore();

    doc = GetDocument();
    // save the file
    export_status = MeiDocumentToFile(doc, filename);

    // start cleaning up.
    Sibelius.DestroyProgressDialog();

    // clean up after ourself
    ResetXml();

    if (export_status = False)
    {
        return 'The file was not exported. File:\n\n' & filename & '\n\ncould not be written.';
    }
}  //$end


function SetGlobalsForScore (score) {
    // Sets some globals with information about the currently processed score.
    // Some functions get a significant performance boost when we're caching
    // properties of the Score object rather than passing it around or
    // accessing its properties.

    Self._property:ActiveScore = score;
    if (ActiveScore = null)
    {
        return 'Could not find an active score. Cannot export to ' & filename;
    }
    Self._property:ActiveScoreFileName = ActiveScore.FileName & '';

    Self._property:StaffHeight = score.StaffHeight;
    Self._property:SystemStaff = score.SystemStaff;
    Self._property:Staves = CreateSparseArray();
    for each staff in score
    {
        Staves.Push(staff);
    }
}  //$end


function ExportBatch (files, extensions, showFinalMessage) {
    if (not InitGlobals(extensions))
    {
        return null;
    }
    InitWarningsTracker();

    utils.SortArray(files, false);

    numFiles = files.Length;
    exportCount = 0;

    for index = 0 to numFiles
    {
        file = Sibelius.GetFile(files[index]);

        score = GetScore(file);

        if (null = score)
        {
            RegisterWarning(null, 'File could not be opened', '');
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
                RegisterWarning(null, 'Export failed', error);
            }
        }
    }


    Sibelius.DestroyProgressDialog();

    if (showFinalMessage)
    {
        InformAboutResults(exportCount & ' of ' & numFiles & ' files were exported.', true);
    }

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


function InformAboutResults (message, batchMode) {
    // Displays a final dialog and in case warnings have been registered, gives
    // the option to save the warnings as CSV file.
    if (Self._property:Warnings = 0)
    {
        return Sibelius.MessageBox(message);
    }
    message = message & '\n\nExport finished with ' & Warnings.Length & ' warnings of the the following categories:\n';
    for each Name warningType in FoundWarningTypes
    {
        warningCount = FoundWarningTypes[warningType];
        message = message & '\n' & warningCount & 'x ' & warningType;
    }
    csvPath = '';
    if (not Sibelius.YesNoMessageBox(message & '\n\nWrite warnings to a CSV file?'))
    {
        return '';
    }

    defaultFolder = '';
    defaultName = 'warnings.csv';
    if (IsValid(ActiveScore))
    {
        defaultFolder = ActiveScore.FileName.Name & '.csv';
    }
    if (defaultFolder != '' and not batchMode)
    {
        defaultName = ActiveScore.FileName.NameNoPath & '_warnings.csv';
    }

    while (true)
    {
        csvPath = Sibelius.SelectFileToSave(
            'Save warnings as CSV', defaultName, defaultFolder, 'csv', 'TEXT', 'CSV file'
        );
        error = '';
        if ('' = csvPath)
        {
            error = 'No CSV file for saving warnings was selected.';
        }
        else
        {
            error = WriteWarningsAsCsv(csvPath);
        }
        if ('' = error or not Sibelius.MessageBox(error & '\n\nTry again? Otherwise the information collected during export will be lost.'))
        {
            return '';
        }
    }
}  //$end

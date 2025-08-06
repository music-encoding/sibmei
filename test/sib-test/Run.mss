function RunTests() {
    Self._property:libmei = libmei4;
    Self._property:sibmei = @MainPlgBaseName;
    sibmei._property:libmei = libmei;
    sibmei.InitGlobals(CreateSparseArray(MainPlgBaseName & '_extension_test'));
    sibmei.InitGlobalAliases(Self);

    plugins = Sibelius.Plugins;

    if (not (plugins.Contains('Test')))
    {
        Sibelius.MessageBox('Please install the Test plugin!');
        ExitPlugin();
    }

    // In an attempt to minimize the chance of Sibelius crashing randomly, close
    // all scores before running the tests.
    if (not Sibelius.YesNoMessageBox(
        'All open scores will be closed without saving before running the tests. Continue?'
    ))
    {
        ExitPlugin();
    }

    CloseAllWindows();

    Self._property:pluginDir = GetPluginFolder(MainPlgBaseName & '.plg');
    Self._property:tempDir = CreateNewTempDir();
    Self._property:_SibTestFileDirectory = pluginDir & 'sibmeiTestSibs' & Sibelius.PathSeparator;

    suite = Test.Suite('Sibelius MEI Exporter', Self, sibmei);

    suite
        .AddModule('TestExportConverters')
        .AddModule('TestLibmei')
        .AddModule('TestExportGenerators')
        .AddModule('TestUtilities')
        .AddModule('TestHierarchyBuilders')
    ;

    suite.Run();

    CloseAllWindows();

    testFolder = Sibelius.GetFolder(_SibTestFileDirectory);
    testFiles = CreateSparseArray();
    for each SIB file in testFolder
    {
        testFiles.Push(file);
    }
    sibmei4.ExportBatch(testFiles, CreateSparseArray('sibmei4_extension_test'));

    if (Sibelius.PathSeparator = '/') {
        nodeTestScript = pluginDir & 'test.sh';
    } else {
        nodeTestScript = pluginDir & 'test.bat';
    }
    if (not (Sibelius.FileExists(nodeTestScript) and Sibelius.LaunchApplication(nodeTestScript))) {
        Sibelius.MessageBox('Run `npm test` to test output written to ' & _SibTestFileDirectory);
    }
}  //$end


function GetPluginFolder(plgName) {
    //$module(Run.mss)
    plgNameLength = Length(plgName);

    for each plugin in Sibelius.Plugins
    {
        path = plugin.File;
        i = Length(path) - 2;
        while (i >= 0 and CharAt(path, i) != Sibelius.PathSeparator) {
            i = i - 1;
        }

        if (Substring(path, i + 1) = plgName) {
            return Substring(path, 0, i + 1);
        }
    }

    Sibelius.MessageBox(plgName & ' was not found');
    ExitPlugin();
}  //$end


function CreateEmptyTestScore(staffs, bars) {
    //$module(Run.mss)
    score = Sibelius.New();
    while (score.StaffCount < staffs) {
        score.CreateInstrumentAtBottom('instrument.other.trebleclef');
    }
    while (score.SystemStaff.BarCount > bars) {
        score.SystemStaff.NthBar(1).Delete();
    }
    score.AddBars(bars - score.SystemStaff.BarCount);
    return score;
}  //$end


function OpenSibFile(filePath, okIfAlreadyOpen) {
    //$module(Run.mss)

    alreadyOpenFile = GetOpenSibFile(filePath);

    if (null != alreadyOpenFile) {
        if (okIfAlreadyOpen) {
            return alreadyOpenFile;
        } else {
            return null;
        }
    }

    if (Sibelius.FileExists(filePath)) {
        Sibelius.Open(filePath);
        return GetOpenSibFile(filePath);
    }
}  //$end


function GetOpenSibFile(filePath) {
    //$module(Run.mss)

    filePath = '' & filePath;

    // Sibelius.ScoreCount does not seem to be working reliably (at least when
    // scores have just been opened programatically), so instead of a for loop
    // we do the following:

    i = 0;
    while (true) {
        score = Sibelius.NthScore(i);
        if ((score = null) or (score.FileName = filePath)) {
            return score;
        }
        i = i + 1;
    }
}  //$end


function EnsureActiveScoreExists() {
    //$module(Run.mss)

    // Sometimes, Sibelius.ActiveScore is null.
    if (null = Sibelius.ActiveScore) {
        Sibelius.ActiveScore = Sibelius.New();
    }
}  //$end


function CreateNewTempDir() {
    //$module(Run.mss)

    // In a test, we might create multiple temp directories in one second, so
    // the date string is not unique enough. So we also add a running number
    // that is reset to 0 for the next second.
    if (Self._property:lastTempFolderCreationTime = Sibelius.CurrentTime) {
        Self._property:tempFolderCount = Self._property:tempFolderCount + 1;
    } else {
        Self._property:lastTempFolderCreationTime = Sibelius.CurrentTime;
        Self._property:tempFolderCount = 0;
    }

    return Sibelius.CreateFolder(
        GetTempDir() & DateTimeString(Sibelius.CurrentDate) & '-' & Self._property:tempFolderCount
    );
}  //$end


function DateTimeString(date) {
    //$module(Run.mss)
    dateComponents = CreateSparseArray(
        date.Year,
        date.Month,
        date.DayOfMonth,
        date.Hours,
        date.Minutes,
        date.Seconds
    );
    return dateComponents.Join('-');
}  //$end


function CloseAllWindows () {
    scores = CreateSparseArray();
    for each score in Sibelius
    {
        scores.Push(score);
    }
    for each score in score
    {
        if (Sibelius.ScoreCount <= 1)
        {
            // Make sure we have an open window so Sibelius will not crash
            Sibelius.New();
        }
        Sibelius.CloseAllWindowsForScore(score, false);
    }
    if (Sibelius.ScoreCount > 1)
    {
        // Closing did not work. Try a different approach.
        Sibelius.CloseAllWindows(false);
        Sibelius.New();
    }
}  //$end

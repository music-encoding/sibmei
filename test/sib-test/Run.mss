function Run() {
    Self._property:libmei = libmei4;
    Self._property:sibmei = sibmei4;
    sibmei4._property:libmei = libmei;
    sibmei.InitGlobals(CreateSparseArray('sibmei4_extension_test'));

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

    Sibelius.CloseAllWindows(false);
    Sibelius.New();

    Self._property:pluginDir = GetPluginFolder('sibmei4.plg');
    Self._property:tempDir = CreateNewTempDir();
    Self._property:_SibTestFileDirectory = pluginDir & 'sibmeiTestSibs' & Sibelius.PathSeparator;

    suite = Test.Suite('Sibelius MEI Exporter', Self, sibmei);

    suite
        .AddModule('TestExportConverters')
        .AddModule('TestLibmei')
        .AddModule('TestExportGenerators')
        .AddModule('TestUtilities')
    ;

    suite.Run();

    Sibelius.CloseAllWindows(false);

    sibmei4_batch_sib.ConvertFolder(
        Sibelius.GetFolder(_SibTestFileDirectory),
        CreateSparseArray('sibmei4_extension_test')
    );

    // Make sure we have an open window so Sibelius will neither crash nor
    // decide to open a new window later that will force the mocha test results
    // into the background.
    Sibelius.New();

    if (Sibelius.PathSeparator = '/') {
        mochaScript = pluginDir & 'test.sh';
    } else {
        mochaScript = pluginDir & 'test.bat';
    }
    if (not (Sibelius.FileExists(mochaScript) and Sibelius.LaunchApplication(mochaScript))) {
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


function GetTempDir() {
    //$module(Run.mss)
    if (Sibelius.PathSeparator = '/') {
        tempFolder = '/tmp/';
    } else {
        appDataFolder = Sibelius.GetUserApplicationDataFolder();
        // appDataFolder usually looks like C:\Users\{username}\AppData\Roaming\
        // We strip the trailing bit until the second to last backslash
        i = Length(appDataFolder) - 2;
        while (i >= 0 and CharAt(appDataFolder, i) != '\\') {
            i = i - 1;
        }
        // tempFolder usually looks like C:\Users\USERNAME\AppData\Local\Temp\
        // So we replace the trailing 'Roaming' with 'Local\Temp'
        tempFolder = Substring(appDataFolder, 0, i) & '\\Local\\Temp\\';
    }
    if (Sibelius.FolderExists(tempFolder)) {
        return Sibelius.GetFolder(tempFolder);
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

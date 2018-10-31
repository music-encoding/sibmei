function Run() {
  plugins = Sibelius.Plugins;

  if (not (plugins.Contains('Test'))) {
    Sibelius.MessageBox('Please install the Test plugin!');
    ExitPlugin();
  }

  Self._property:pluginDir = GetPluginFolder('sibmei2.plg');
  Self._property:_SibTestFileDirectory = pluginDir & 'sibmeiTestSibs'
      & Sibelius.PathSeparator;

  suite = Test.Suite('Sibelius MEI Exporter', Self, sibmei2);

  suite
    .AddModule('TestExportConverters')
    .AddModule('TestLibmei')
    .AddModule('TestExportGenerators')
    .AddModule('TestUtilities')
  // suite
  //   .AddModule('TestExportGenerators')
    ;

  suite.Run();

  sibmei_batch_sib.ConvertFolder(Sibelius.GetFolder(_SibTestFileDirectory));
  Trace('Run `npm test` to test output written to ' & _SibTestFileDirectory);
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


function CloseActiveScore() {
    //$module(Run.mss)
    filePath = Sibelius.ActiveScore.FileName;
    pathComponents = SplitString(filePath, Sibelius.PathSeparator);
    if (pathComponents.NumChildren = 1)
    {
      // If there's no path separator in the file name, we have a new file that
      // has not been saved yet. In that case, Sibelius.CloseWindow() will not
      // close the file properly, so we have to save it first.
      Sibelius.ActiveScore.Save(pluginDir & '_tmp.sib');
    }
    Sibelius.CloseWindow(False);
}  //$end


function RunLibmeiTests () {
  suite = Test.Suite('Sibelius MEI Exporter', Self, sibmei2);

  suite
    .AddModule('TestLibmei')
    ;

  suite.Run();
}  //$end


function RunGeneratorTests () {
  suite = Test.Suite('Sibelius MEI Exporter', Self, sibmei2);

  suite
    .AddModule('TestExportGenerators')
    ;

  suite.Run();

}  //$end

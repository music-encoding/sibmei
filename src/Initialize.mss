function Initialize() {
    Self._property:Logfile = GetTempDir() & LOGFILE;
    Self._property:libmei = libmei4;

    if (Sibelius.FileExists(Self._property:Logfile) = False)
    {
        Sibelius.CreateTextFile(Self._property:Logfile);
    }

    AddToPluginsMenu(PluginName,'Run');
}  //$end

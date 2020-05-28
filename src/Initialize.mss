function Initialize() {
    Self._property:Logfile = GetTempDir() & LOGFILE;

    if (Sibelius.FileExists(Self._property:Logfile) = False)
    {
        Sibelius.CreateTextFile(Self._property:Logfile);
    }

    AddToPluginsMenu(PluginName,'Run');
}  //$end

function Initialize() {
    if (Sibelius.FileExists(LOGFILE) = False)
    {
        Sibelius.CreateTextFile(LOGFILE);
    }

    AddToPluginsMenu(PluginName,'Run');
}  //$end

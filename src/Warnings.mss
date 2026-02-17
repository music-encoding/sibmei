function InitWarningsTracker () {
    Self._property:ReportableStaffNameProperties = CreateSparseArray(
        'FullInstrumentName',
        'FullStaffName',
        'InstrumentName',
        'ShortInstrumentName',
        'ShortStaffName'
    );
    Self._property:Warnings = CreateSparseArray();
    Self._property:FoundWarningTypes = CreateDictionary();
}  //$end


function RegisterWarning (barObject, warningType, message) {
    FoundWarningTypes[warningType] = FoundWarningTypes[warningType] + 1;
    if (null = barObject)
    {
        Warnings.Push(CreateSparseArray(
            CsvEscape(ActiveScoreFileName), '', '', '', '', CsvEscape(warningType), CsvEscape(message)
        ));
        return '';
    }
    bar = barObject.ParentBar;
    staff = bar.ParentStaff;
    barNumber = bar.ExternalBarNumberString;
    if (barNumber != bar.BarNumber)
    {
        // In the status bar, Sibelius shows '1 (24)' if logical bar 24
        // is selected and bar counting re-starts from 1 there. For the
        // user, the printed bar numbers are often more helpful than
        // the logical ones, so report both using Sibelius' style.
        barNumber = barNumber & ' (' & bar.BarNumber & ')';
    }

    staffName = '';
    for each staffNameProperty in ReportableStaffNameProperties
    {
        if (('' = staffName or ' ' = staffName) and '' != staff.@staffNameProperty)
        {
            staffName = staff.@staffNameProperty;
        }
    }

    Warnings.Push(CreateSparseArray(
        CsvEscape(ActiveScoreFileName),
        CsvEscape(staffName),
        staff.StaffNum,
        CsvEscape(barNumber),
        CsvEscape(LayerNumbers[barObject.Voices]),
        CsvEscape(warningType),
        CsvEscape(message)
    ));
}  //$end


function WriteWarningsAsCsv (csvPath) {
    if (not Sibelius.CreateTextFile(csvPath))
    {
        return 'Could not create file:\n\n' & csvPath;
    }

    Sibelius.AppendLineToFile(csvPath, 'file,staff name,staff number,bar,voices,warning type,message');

    timerId = 1;
    Sibelius.ResetStopWatch(timerId);
    Sibelius.CreateProgressDialog('Writing CSV file', 0, Warnings.Length);

    for i = 0 to Warnings.Length
    {
        warning = Warnings[i];
        if (Sibelius.GetElapsedMilliSeconds(timerId) > 200)
        {
            Sibelius.ResetStopWatch(timerId);
            if (not Sibelius.UpdateProgressDialog(i, 'Warning ' & i & '/' & Warnings.Length))
            {
                return 'You aborted writing warnings to CSV.';
            }
        }
        Sibelius.AppendLineToFile(csvPath, JoinStrings(Warnings[i], ','));
    }

    Sibelius.DestroyProgressDialog();
    return '';
}  //$end


function CsvEscape (string) {
    splitAtQuotes = SplitString(string, '""');
    if (splitAtQuotes.NumChildren > 1)
    {
        return '""' & JoinStrings(splitAtQuotes, '""""') & '""""';
    }
    if (SplitString(string, ',').NumChildren > 1)
    {
        return '""' & string & '""';
    }
    return string;
}  //$end

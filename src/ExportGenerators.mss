function GenerateMEIHeader () {
    //$module(ExportGenerators.mss)
    // takes in a Sibelius Score object
    // returns a libmei tree (i.e., nested objects and arrays) with a MEI header with metadata
    score = Self._property:ActiveScore;


    header = CreateElement('meiHead');
    Self._property:HeaderElement = header;

    fileD = CreateElement('fileDesc');
    titleS = CreateElement('titleStmt');
    AddChild(header, fileD);
    AddChild(fileD, titleS);

    //encodingDesc must preceed workList in MEI 4.0
    encodingD = CreateElement('encodingDesc');
    AddChild(header, encodingD);
    appI = GenerateApplicationInfo();
    AddChild(encodingD, appI);

    //generate workList
    workList = CreateElement('workList');
    Self._property:WorkListElement = workList;

    wd_work = CreateElement('work');
    wd_title = CreateElement('title');
    AddChild(wd_work, wd_title);
    AddChild(workList, wd_work);
    AddChild(header, workList);

    title = CreateElement('title');
    AddChild(titleS, title);

    if (score.Title != '')
    {
        SetText(title, score.Title);
        SetText(wd_title, score.Title);
    }
    if (score.Subtitle != '')
    {
        subtitle = CreateElement('title');
        AddChild(titleS, subtitle);
        SetText(subtitle, score.Subtitle);
        AddAttribute(subtitle, 'type', 'subtitle');
    }
    if (score.Composer != '')
    {
        composer = CreateElement('composer');
        AddChild(titleS, composer);
        SetText(composer, score.Composer);
        wd_composer = CreateElement('composer');
        SetText(wd_composer, score.Composer);
        AddChild(wd_work, wd_composer);
    }
    if (score.Lyricist != '')
    {
        lyricist = CreateElement('lyricist');
        AddChild(titleS, lyricist);
        SetText(lyricist, score.Lyricist);
        wd_lyricist = CreateElement('lyricist');
        SetText(wd_lyricist, score.Lyricist);
        AddChild(wd_work, wd_lyricist);
    }
    if (score.Arranger != '')
    {
        arranger = CreateElement('arranger');
        AddChild(titleS, arranger);
        SetText(arranger, score.Arranger);
        wd_arranger = CreateElement('arranger');
        SetText(wd_arranger, score.Arranger);
        AddChild(wd_work, wd_arranger);
    }
    if (score.OtherInformation != '')
    {
        wd_notesStmt = CreateElement('notesStmt');
        ns_annot = CreateElement('annot');
        AddChild(wd_work, wd_notesStmt);
        AddChild(wd_notesStmt, ns_annot);
        SetText(ns_annot, score.OtherInformation);
    }

    respS = CreateElement('respStmt');
    AddChild(titleS, respS);
    persN = CreateElement('persName');
    AddChild(respS, persN);
    pubS = CreateElement('pubStmt');
    AddChild(fileD, pubS);

    avail = CreateElement('availability');
    ur = CreateElement('useRestrict');
    AddChild(avail, ur);
    AddChild(pubS, avail);
    SetText(ur, score.Copyright);

    return header;
}  //$end

function GenerateApplicationInfo () {
    //$module(ExportGenerators.mss)

    appI = CreateElement('appInfo');

    applic = CreateElement('application');
    SetId(applic, 'sibelius');
    AddChild(appI, applic);
    AddAttribute(applic, 'version', Sibelius.ProgramVersion);
    isodate = ConvertDate(Sibelius.CurrentDate);
    AddAttribute(applic, 'isodate', isodate);
    osname = CreateElement('name');
    SetText(osname, Sibelius.OSVersionString);
    AddAttribute(osname, 'type', 'operating-system');
    AddChild(applic, osname);

    plgapp = CreateElement('application');
    plgname = CreateElement('name');
    SetText(plgname, PluginName & ' (' & PluginVersion & ')');
    AddAttribute(plgapp, 'type', 'plugin');
    AddAttribute(plgapp, 'version', PluginVersion);
    SetId(plgapp, 'sibmei');
    AddChild(plgapp, plgname);
    AddChild(appI, plgapp);

    if (Self._property:ChosenExtensions)
    {
        for each Pair ext in Self._property:ChosenExtensions
        {
            extapp = CreateElement('application');
            SetId(extapp, ext.Name);
            AddAttribute(extapp, 'type', 'extension');
            extName = CreateElement('name');
            SetText(extName, ext.Value);
            AddChild(extapp, extName);
            AddChild(appI,extapp);
        }
    }

    return appI;

}   //$end

function GenerateMEIMusic () {
    Self._property:TieResolver = CreateDictionary();
    Self._property:LineEndResolver = CreateSparseArray();
    Self._property:LyricWords = CreateDictionary();
    Self._property:NoteRestIdsByLocation = CreateSparseArray();

    Self._property:ActiveVolta = null;

    Self._property:BodyElement = null;
    Self._property:MDivElement = null;
    Self._property:SectionElement = null;

    // track page numbers
    Self._property:CurrentPageNumber = null;
    // We start the first page with a <pb> (good practice and helps Verovio)
    Self._property:PageBreak = CreateElement('pb');
    Self._property:SystemBreak = null;

    music = CreateElement('music');

    ProcessFrontMatter(music);

    body = CreateElement('body');
    AddChild(music, body);
    Self._property:BodyElement = body;

    // start with the first bar.
    FIRST_BAR = 1;
    mdiv = GenerateMDiv(FIRST_BAR);
    AddChild(body, mdiv);

    numbars = SystemStaff.BarCount;
    currentScoreDef = null;

    timerId = 1;
    Sibelius.ResetStopWatch(timerId);

    for j = 1 to numbars + 1
    {
        // Surprisingly, the progress dialog slows down processing tremendously,
        // so only update it at most 5 times a second
        // http://sibelius-manuscript-plug-in-developers.3224780.n2.nabble.com/Performance-notes-for-Plug-in-Developers-td7573341.html
        if (Sibelius.GetElapsedMilliSeconds(timerId) > 200)
        {
            Sibelius.ResetStopWatch(timerId);
            progressMsg = utils.Format(_ExportingBars, j, numbars);
            if (not Sibelius.UpdateProgressDialog(j, progressMsg))
            {
                // if the user has clicked cancel, stop the plugin.
                ExitPlugin();
            }
        }
        section = Self._property:SectionElement;

        m = GenerateMeasure(j);

        if (Self._property:PageBreak != null)
        {
            pb = Self._property:PageBreak;
            AddChild(section, pb);
            Self._property:PageBreak = null;
        }

        currKeyS = SystemStaff.CurrentKeySignature(j);

        if (Self._property:SystemBreak != null)
        {
            sb = Self._property:SystemBreak;
            AddChild(section, sb);
            Self._property:SystemBreak = null;
        }

        // Do not try to get the signatures for bar 0 -- will not work
        if (j > 1)
        {
            prevKeyS = SystemStaff.CurrentKeySignature(j - 1);
        }
        else
        {
            prevKeyS = SystemStaff.CurrentKeySignature(j);
        }

        if (j > 1)
        {
            currentScoreDef = GenerateMeterAttributes(currentScoreDef, j);
        }

        if (currKeyS.Sharps != prevKeyS.Sharps)
        {
            if (currentScoreDef = null)
            {
                currentScoreDef = CreateElement('scoreDef');
            }

            AddAttribute(currentScoreDef, 'keysig', ConvertKeySignature(currKeyS.Sharps));
        }

        if (currentScoreDef != null)
        {
            // The sig changes must be added just before we add the measure to keep
            // the proper order.
            if (ActiveVolta != null)
            {
                AddChild(ActiveVolta, currentScoreDef);
            }
            else
            {
                AddChild(section, currentScoreDef);
            }
            currentScoreDef = null;
        }

        if (ActiveVolta != null)
        {
            AddChild(ActiveVolta, m);
        }
        else
        {
            AddChild(section, m);
        }
    }

    return music;
}  //$end

function GenerateMDiv (barnum) {
    //$module(ExportGenerators.mss)
    // Add the first mdiv; Movements will add new ones.
    mdiv = CreateElement('mdiv');
    Self._property:MDivElement = mdiv;

    ano = CreateElement('annot');
    AddAttribute(ano, 'type', 'duration');
    SetText(ano, ConvertTimeStamp(ActiveScore.ScoreDuration));

    sco = CreateElement('score');
    AddChild(mdiv, sco);

    scd = GenerateScoreDef(ActiveScore, barnum);
    Self._property:MainScoreDef = scd;
    AddChild(sco, scd);

    section = CreateElement('section');
    Self._property:SectionElement = section;
    AddChild(sco, section);

    //annot is valid as a child of score
    AddChild(sco, ano);

    return mdiv;
} //$end

function GenerateMeasure (num) {
    Self._property:MeasureTies = CreateSparseArray();
    Self._property:MeasureObjects = CreateSparseArray();

    m = CreateElement('measure');
    AddAttribute(m, 'n', num);

    children = CreateSparseArray();

    // since so much metadata about the staff and other context
    // is available on the bar that should now be on the measure, go through the bars
    // and try to extract it.
    currTimeS = SystemStaff.CurrentTimeSignature(num);
    sysBar = SystemStaff[num];

    if (sysBar.Length != (currTimeS.Numerator * 1024 / currTimeS.Denominator))
    {
        AddAttribute(m, 'metcon', 'false');
    }

    if (sysBar.NthBarInSystem = 0)
    {
        Self._property:SystemBreak = CreateElement('sb');
    }

    for each this_staff in Staves
    {
        bar = this_staff[num];

        curr_pn = bar.OnNthPage;
        if (curr_pn != Self._property:CurrentPageNumber)
        {
            Self._property:CurrentPageNumber = curr_pn;
            pb = CreateElement('pb');

            // pages are stored internally as 0-based, so increment by one for the 'human' representation.
            AddAttribute(pb, 'n', curr_pn + 1);
            Self._property:PageBreak = pb;
        }

        if (bar.ExternalBarNumberString != bar.BarNumber and GetAttribute(m, 'label') = False)
        {
            AddAttribute(m, 'label', bar.ExternalBarNumberString);
        }

        s = GenerateStaff(this_staff, num);
        AddChild(m, s);
        for each beamSpan in s.beamSpans
        {
            AddChild(m, beamSpan);
            startid = GetMeiNoteRestAtPosition(beamSpan.startNoteRest, false)._id;
            AddAttribute(beamSpan, 'startid', '#' & startid);
            endid = GetMeiNoteRestAtPosition(beamSpan.endNoteRest, false)._id;
            AddAttribute(beamSpan, 'endid', '#' & endid);
        }

        ProcessBarObjects(bar);
        ProcessEndingLines(bar);
    }

    mties = Self._property:MeasureTies;

    for each tie in mties
    {
        m.children.Push(tie);
    }

    for each mobj in MeasureObjects
    {
        m.children.Push(mobj);
    }

    for each bobj in sysBar
    {
        switch (bobj.Type)
        {
            case ('SpecialBarline')
            {
                attributes = BarlineAttributes[bobj.BarlineInternalType];
                if (null != attributes)
                {
                    for each Name attName in attributes
                    {
                        AddAttribute(m, attName, attributes[attName]);
                    }
                }
            }
            case ('SystemTextItem')
            {
                if (bobj.OnNthBlankPage = 0)
                {
                    text = HandleStyle(TextHandlers, bobj);
                    if (text != null)
                    {
                        AddChild(m, text);
                    }
                }
            }
            case ('RepeatTimeLine')
            {
                voltaTemplate = VoltaTemplates[bobj.StyleId];
                if (null != voltaTemplate)
                {
                    ActiveVolta = MeiFactory(voltaTemplate);
                    ActiveVolta._property:endBarNumber = bobj.EndBarNumber;
                    AddChild(SectionElement, ActiveVolta);
                }
            }
            case ('Graphic')
            {
                Log('Found a graphic!');
                Log('is object? ' & IsObject(bobj));
            }
        }
    }

    if (null != ActiveVolta and ActiveVolta.endBarNumber < num)
    {
        ActiveVolta = null;
    }

    // If we've reached the end of the section, swap out the mdiv to a new one.
    if (sysBar.SectionEnd and sysBar.BarNumber < SystemStaff.BarCount)
    {
        body = Self._property:BodyElement;
        // create the mdiv for the next bar.
        newMdiv = GenerateMDiv(num + 1);
        AddChild(body, newMdiv);
    }

    return m;
}  //$end


function GenerateStaff (staff, measurenum) {
    bar = staff[measurenum];

    stf = CreateElement('staff');

    if (bar.OnHiddenStave)
    {
        AddAttribute(stf, 'visible', 'false');
    }

    AddAttribute(stf, 'n', staff.StaffNum);

    layers = BuildLayerHierarchy(staff, measurenum);
    stf['beamSpans'] = layers.beamSpans;
    // NB: Completely resets any previous children!
    SetChildren(stf, layers);

    return stf;
}  //$end


function GenerateClef (bobj) {
    //$module(ExportGenerators.mss)
    clefinfo = ConvertClef(bobj.StyleId);
    clef_el = CreateElement('clef');

    AddAttribute(clef_el, 'shape', clefinfo[0]);
    AddAttribute(clef_el, 'line', clefinfo[1]);
    AddAttribute(clef_el, 'dis', clefinfo[2]);
    AddAttribute(clef_el, 'dis.place', clefinfo[3]);
    AddAttribute(clef_el, 'tstamp', ConvertPositionToTimestamp(bobj.Position, bobj.ParentBar));
    AddAttribute(clef_el, 'staff', bobj.ParentBar.ParentStaff.StaffNum);

    if (bobj.Color != 0)
    {
        AddAttribute(clef_el, 'color', ConvertColor(bobj));
    }

    if (bobj.Hidden = true)
    {
        AddAttribute(clef_el, 'visible', 'false');
    }

    return clef_el;
}  //$end

function GenerateNoteRest (bobj, layer) {
    //$module(ExportGenerators.mss)
    nr = null;

    // the previous object will tell us if it was a grace note, appogiature, or acciaccatura.
    prev_object = bobj.PreviousItem(bobj.VoiceNumber, 'NoteRest');

    switch(bobj.NoteCount)
    {
        case(0)
        {
            nr = GenerateRest(bobj);
        }
        case(1)
        {
            nobj = bobj[0];
            nr = GenerateNote(nobj);
        }
        default
        {
            nr = GenerateChord(bobj);
        }
    }

    if (bobj.NoteCount > 0)
    {
        // notes and chords, not rests.
        // If the stemweight is less than zero, the stem will point up, otherwise it will point down.
        if (bobj.Stemweight < 0)
        {
            AddAttribute(nr, 'stem.dir', 'up');
        }
        else
        {
            AddAttribute(nr, 'stem.dir', 'down');
        }
    }

    if (bobj.Dx != 0)
    {
        AddAttribute(nr, 'ho', ConvertOffsetsToMEI(bobj.Dx));
    }

    if (bobj.CueSize = true and GetName(nr) != 'space')
    {
        AddAttribute(nr, 'fontsize', 'small');
    }

    if (bobj.Hidden = true and GetName(nr) != 'space')
    {
        AddAttribute(nr, 'visible', 'false');
    }

    if (bobj.Color != 0)
    {
        AddAttribute(nr, 'color', ConvertColor(bobj));
    }

    /* NB: If there is a problem with grace notes, look here first.
        I think most of these cases should be covered by appog. and acciacc.
        but possibly not...

    if (bobj.GraceNote = True)
    {
        AddAttribute(nr, 'grace', 'acc');
    }
    */

    if (bobj.IsAppoggiatura = True)
    {
        AddAttribute(nr, 'grace', 'acc');
    }

    if (bobj.IsAcciaccatura = True)
    {
        AddAttribute(nr, 'grace', 'unacc');
        AddAttribute(nr, 'stem.mod', '1slash');
    }

    if (bobj.GetArticulation(PauseArtic))
    {
        GenerateFermata(bobj, 'curved', ConvertFermataForm(bobj));
    }

    if (bobj.GetArticulation(SquarePauseArtic))
    {
        GenerateFermata(bobj, 'square', ConvertFermataForm(bobj));
    }

    if (bobj.GetArticulation(TriPauseArtic))
    {
        GenerateFermata(bobj, 'angular', ConvertFermataForm(bobj));
    }

    if (bobj.GetArticulation(StaccatoArtic))
    {
        AddAttributeValue(nr, 'artic', 'stacc');
    }

    if (bobj.GetArticulation(TenutoArtic))
    {
        AddAttributeValue(nr, 'artic', 'ten');
    }

    if (bobj.GetArticulation(MarcatoArtic))
    {
        AddAttributeValue(nr, 'artic', 'marc');
    }

    if (bobj.GetArticulation(DownBowArtic))
    {
        AddAttributeValue(nr, 'artic', 'dnbow');
    }

    if (bobj.GetArticulation(UpBowArtic))
    {
        AddAttributeValue(nr, 'artic', 'upbow');
    }

    if (bobj.GetArticulation(AccentArtic))
    {
        AddAttributeValue(nr, 'artic', 'acc');
    }

    if (bobj.GetArticulation(StaccatissimoArtic))
    {
        AddAttributeValue(nr, 'artic', 'stacciss');
    }

    if (bobj.GetArticulation(WedgeArtic))
    {
        AddAttributeValue(nr, 'artic', 'spicc');
    }

    if (bobj.GetArticulation(PlusArtic))
    {
        AddAttributeValue(nr, 'artic', 'stop');
    }

    if (bobj.GetArticulation(HarmonicArtic))
    {
        AddAttributeValue(nr, 'artic', 'harm');
    }

    if (bobj.FallType = FallTypeDoit)
    {
        AddAttributeValue(nr, 'artic', 'doit');
    }

    if (bobj.FallType = FallTypeNormal)
    {
        AddAttributeValue(nr, 'artic', 'fall');
    }

    if (bobj.ScoopType = ScoopTypePlop)
    {
        AddAttributeValue(nr, 'artic', 'plop');
    }

    if ((bobj.SingleTremolos > 0) or (bobj.SingleTremolos = ZOnStem))
    {
        // btrem = CreateElement('bTrem');
        // AddChild(btrem, nr);

        if (bobj.SingleTremolos = ZOnStem)
        {
            stemmod = 'z';
        }
        else
        {
            stemmod = bobj.SingleTremolos & 'slash';
        }

        AddAttribute(nr, 'stem.mod', stemmod);
    }

    AddAttribute(nr, 'tstamp.real', ConvertTimeStamp(bobj.Time));

    return nr;
}  //$end

function GenerateRest (bobj) {
    //$module(ExportGenerators.mss)
    // check if it's a rest
    // check if it's hidden, in which case make MEI <space> instead of <rest>
    dur = bobj.Duration;
    meidur = ConvertDuration(dur);

    if (bobj.Hidden)
    {
        r = CreateElement('space');
    }
    else
    {
        r = CreateElement('rest');
    }

    name = GetName(r);
    AddAttribute(r, 'dur', meidur[0]);
    AddAttribute(r, 'dur.ppq', dur);
    AddAttribute(r, 'dots', meidur[1]);

    if (bobj.Dx != 0 and name != 'space')
    {
        AddAttribute(r, 'ho', ConvertOffsetsToMEI(bobj.Dx));
    }

    if (bobj.Dy != 0 and name != 'space')
    {
        AddAttribute(r, 'vo', ConvertOffsetsToMEI(bobj.Dy));
    }

    if (bobj.CueSize = true and name != 'space')
    {
        AddAttribute(r, 'fontsize', 'small');
    }

    if (bobj.Color != 0 and name != 'space')
    {
        AddAttribute(r, 'color', ConvertColor(bobj));
    }

    return r;
}  //$end

function GenerateNote (nobj) {
    //$module(ExportGenerators.mss)

    // handle modifications to the gestural duration
    // if this particular note is a member of a tuplet.
    gesdur = null;
    if (nobj.ParentNoteRest.ParentTupletIfAny != null)
    {
        dur = nobj.ParentNoteRest.Duration;
        ptuplet = nobj.ParentNoteRest.ParentTupletIfAny;
        pnum = ptuplet.Left;
        pden = ptuplet.Right;
        floatgesdur = (pden * 1.0 / pnum) * dur;
        gesdur = Round(floatgesdur);
    }
    else
    {
        gesdur = nobj.ParentNoteRest.Duration;
    }

    dur = nobj.ParentNoteRest.Duration;
    meidur = ConvertDuration(dur);
    pos = nobj.ParentNoteRest.Position;
    parent_bar = nobj.ParentNoteRest.ParentBar;
    keysig = nobj.ParentNoteRest.ParentBar.GetKeySignatureAt(pos);
    clef = nobj.ParentNoteRest.ParentBar.GetClefAt(pos);
    // SparseArray(shape, line, dis, dir);
    clefinfo = ConvertClef(clef.StyleId);

    n = CreateElement('note');
    //hash = SimpleNoteHash(nobj);
    //n._property:hash = hash;

    ntinfo = ConvertDiatonicPitch(nobj.DiatonicPitch);
    pnum = nobj.Pitch;
    vel = nobj.OriginalVelocity;

    dis = clefinfo[2];
    dir = clefinfo[3];

    if (dis != ' ')
    {
        octges = ' ';
        // there is a transposing clef in action, so we need to adjust the
        // performed octave.
        if (dis = '8' and dir = 'below')
        {
            octges = ntinfo[1] - 1;
            pnum = pnum - 12;  // subtract an octave from the MIDI number
        }

        if (dis = '8' and dir = 'above')
        {
            octges = ntinfo[1] + 1;
            pnum = pnum + 12;
        }

        if (dis = '15' and dir = 'below')
        {
            octges = ntinfo[1] - 2;
            pnum = pnum - 24;  // subtract two octaves from the MIDI number
        }

        if (dis = '15' and dir = 'above')
        {
            octges = ntinfo[1] + 2;
            pnum = pnum + 24;
        }

        AddAttribute(n, 'oct.ges', octges);
    }

    if (vel != 0)  // filter default value for manually entered notes
    {
        AddAttribute(n, 'vel', vel);
    }

    AddAttribute(n, 'pnum', pnum);
    AddAttribute(n, 'pname', ntinfo[0]);
    AddAttribute(n, 'oct', ntinfo[1]);
    AddAttribute(n, 'dur', meidur[0]);
    AddAttribute(n, 'dur.ppq', gesdur);
    AddAttribute(n, 'dots', meidur[1]);

    if (nobj.Dx != 0)
    {
        AddAttribute(n, 'ho', ConvertOffsetsToMEI(nobj.Dx));
    }

    if (nobj.Color != nobj.ParentNoteRest.Color)
    {
        AddAttribute(n, 'color', ConvertColor(nobj));
    }

    staff = nobj.ParentNoteRest.ParentBar.ParentStaff.StaffNum;
    layer = nobj.ParentNoteRest.VoiceNumber;

    //AddAttribute(n, 'staff', staff);
    //AddAttribute(n, 'layer', layer);

    if (nobj.NoteStyle != NormalNoteStyle)
    {
        nstyle = ConvertNoteStyle(nobj.NoteStyle);
        AddAttribute(n, 'head.shape', nstyle);
    }

    accid = ConvertAccidental(nobj, keysig.Sharps);
    accVal = accid[0];
    isVisible = accid[1];

    if (accVal != ' ')
    {
        child = CreateElement('accid');
        AddChild(n, child);

        if (isVisible = True)
        {
            AddAttribute(child, 'accid', accVal);
        }
        else
        {
            AddAttribute(child, 'accid.ges', accVal);
        }

        switch (nobj.AccidentalStyle)
        {
            case (CautionaryAcc)
            {
                AddAttribute(child, 'func', 'caution');
            }
            case (BracketedAcc)
            {
                AddAttribute(child, 'enclose', 'paren');
            }
        }
    }

    tie_resolver = Self._property:TieResolver;

    // construct an index that will be used to open a tie, or check if a tie is open.
    // this may be modified below if the tie extends to the next bar
    tie_idx = parent_bar.BarNumber & '-' & staff & '-' & nobj.ParentNoteRest.VoiceNumber & '-' & pnum;

    if (tie_resolver.PropertyExists(tie_idx) and tie_resolver[tie_idx] != null)
    {
        // get the tie
        tie_id = tie_resolver[tie_idx];
        tie_el = GetElementById(tie_id);
        AddAttribute(tie_el, 'endid', '#' & n._id);

        // null it in case we get another one in this measure.
        tie_resolver[tie_idx] = null;
    }

    /*
        If we have an unresolved tie with the same pitch number from the previous bar,
        assume that it stretches to this bar. Look backwards to see if this is the case
        and set it as the end of the tie.
    */
    prev_tie_idx = (parent_bar.BarNumber - 1) & '-' & staff & '-' & nobj.ParentNoteRest.VoiceNumber & '-' & pnum;

    if (tie_resolver.PropertyExists(prev_tie_idx) and tie_resolver[prev_tie_idx] != null)
    {
        tie_id = tie_resolver[prev_tie_idx];
        tie_el = GetElementById(tie_id);
        AddAttribute(tie_el, 'endid', '#' & n._id);

        tie_resolver[prev_tie_idx] = null;
    }

    if (nobj.Tied = True)
    {
        measure_ties = Self._property:MeasureTies;

        tie = CreateElement('tie');
        AddAttribute(tie, 'startid', '#' & n._id);
        measure_ties.Push(tie._id);
        tie_dur = pos + dur;

        // if the tie extends beyond the length of the bar, increment the
        // bar by one so that we can pick up on it later...
        if (tie_dur >= parent_bar.Length)
        {
            tie_idx = (parent_bar.BarNumber + 1) & '-' & staff & '-' & nobj.ParentNoteRest.VoiceNumber & '-' & pnum;
        }

        tie_resolver[tie_idx] = tie._id;
    }

    return n;
}  //$end

function GenerateChord (bobj) {
    //$module(ExportGenerators.mss)
    n = CreateElement('chord');
    dur = bobj.Duration;
    meidur = ConvertDuration(dur);

    AddAttribute(n, 'dur', meidur[0]);
    AddAttribute(n, 'dur.ppq', dur);
    AddAttribute(n, 'dots', meidur[1]);

    for each note in bobj
    {
        sn = GenerateNote(note);
        AddChild(n, sn);
    }

    return n;
}  //$end

function GenerateBarRest (bobj) {
    //$module(ExportGenerators.mss)
    switch (bobj.RestType)
    {
        case(BreveBarRest)
        {
            obj = CreateElement('mRest');
            AddAttribute(obj, 'dur', 'breve');
        }
        case (WholeBarRest)
        {
            obj = CreateElement('mRest');
        }
        case (OneBarRepeat)
        {
            obj = CreateElement('mRpt');
        }
        case (TwoBarRepeat)
        {
            obj = CreateElement('mRpt2');
        }
        case (FourBarRepeat)
        {
            // MEI now supports a four-bar repeat
            obj = CreateElement('multiRpt');
            AddAttribute(obj, 'num', '4');
        }
    }

    switch (bobj.PauseType) {
        case(PauseTypeRound)
        {
            GenerateFermata(bobj, 'curved', ConvertFermataForm(bobj));
        }
        case(PauseTypeTriangular)
        {
            GenerateFermata(bobj, 'angular', ConvertFermataForm(bobj));
        }
        case(PauseTypeSquare)
        {
            GenerateFermata(bobj, 'square', ConvertFermataForm(bobj));
        }
    }

    if (bobj.Hidden = true)
    {
        AddAttribute(obj, 'visible', 'false');
    }

    AddAttribute(obj, 'tstamp.real', ConvertTimeStamp(bobj.Time));

    return obj;
}  //$end

function GenerateScoreDef (score, barnum) {
    //$module(ExportGenerators.mss)
    scoredef = CreateElement('scoreDef');
    docSettings = score.DocumentSetup;

    // this will ensure that the units specified by the user is the one that is
    // represented in the output.
    sibUnits = docSettings.UnitsInDocumentSetupDialog;
    unit = '';

    switch(sibUnits)
    {
        case(DocumentSetupUnitsInches)
        {
            unit = 'in';
        }
        case(DocumentSetupUnitsPoints)
        {
            unit = 'pt';
        }
        default
        {
            // Millimeters is the default for Sibelius
            unit = 'mm';
        }
    }

    vuval = docSettings.StaffSize / 8;

    AddAttribute(scoredef, 'page.width', docSettings.PageWidth & unit);
    AddAttribute(scoredef, 'page.height', docSettings.PageHeight & unit);
    AddAttribute(scoredef, 'page.leftmar', docSettings.PageLeftMargin & unit);
    AddAttribute(scoredef, 'page.rightmar', docSettings.PageRightMargin & unit);
    AddAttribute(scoredef, 'page.topmar', docSettings.PageTopMargin & unit);
    AddAttribute(scoredef, 'page.botmar', docSettings.PageBottomMargin & unit);
    AddAttribute(scoredef, 'vu.height', vuval & unit);

    showCautionaryAccidentals = score.EngravingRules.CautionaryNaturalsInKeySignatures;
    if (showCautionaryAccidentals = true)
    {
        AddAttribute(scoredef, 'keysig.cancelaccid', 'before');
    }

    AddAttribute(scoredef, 'music.name', score.MainMusicFontName);
    AddAttribute(scoredef, 'text.name', score.MainTextFontName);
    // We should read out the lyrics font styles here (e.g. `text.staff.space.hypen.lyrics.verse1`),
    // but the styles properties don't seem to be easily accessible.
    AddAttribute(scoredef, 'lyric.name', score.MainTextFontName);

    AddAttribute(scoredef, 'spacing.staff', score.EngravingRules.SpacesBetweenStaves * 2);
    AddAttribute(scoredef, 'spacing.system', score.EngravingRules.SpacesBetweenSystems * 2);

    GenerateMeterAttributes(scoredef, 1);
    AddAttribute(scoredef, 'ppq', '256'); // sibelius' internal ppq.

    if (score.StaffCount > 0)
    {
        AddChild(scoredef, BuildStaffGrpHierarchy(score, barnum));
    }

    return scoredef;
}  //$end

function GenerateMeterAttributes (scoredef, barNumber) {
    // If a timesignature is found in the bar, adds meter attributes to
    // `scoredef`. If `scoredef` is null, will create a new <scoreDef> that is
    // returned.
    // If there is no time signature in bar 1, an invisible initial meter is
    // added.

    if (SystemStaff.BarCount < barNumber)
    {
        return scoredef;
    }

    timesig = null;
    for each TimeSignature t in SystemStaff.NthBar(barNumber)
    {
        // This loop will find at max one time signature
        timesig = t;
    }

    if (null = timesig and barNumber > 1)
    {
        // There is no meter we have to add
        return scoredef;
    }

    if (null = scoredef)
    {
        scoredef = CreateElement('scoreDef');
    }
    if (null = timesig or timesig.Hidden)
    {
        AddAttribute(scoredef, 'meter.visible', 'false');
    }
    if (null = timesig)
    {
        // We're in bar 1 and there is no explicit time signature
        timesig = SystemStaff.CurrentTimeSignature(barNumber);
    }

    // TimeSignature.Text is either the cut or common time signature character
    // or a two-line string (with line separator `\n\`), where the first line
    // is a number or a sum of numbers (e.g. 3+2) and the second line is a
    // number.
    meterFraction = SplitString(timesig.Text, '\\n', true);
    if (meterFraction.NumChildren = 2)
    {
        // SplitString() returns TreeNodes. `& ''` casts them to strings.
        AddAttribute(scoredef, 'meter.count', meterFraction[0] & '');
        AddAttribute(scoredef, 'meter.unit', meterFraction[1] & '');
        return scoredef;
    }

    meterSym = MeterSymMap[timesig.Text];
    if (meterSym != '')
    {
        AddAttribute(scoredef, 'meter.sym', meterSym);
    }

    AddAttribute(scoredef, 'meter.count', timesig.Numerator);
    AddAttribute(scoredef, 'meter.unit', timesig.Denominator);

    return scoredef;
}  //$end


function GenerateControlEvent (bobj, element) {
    // @endid can not yet be set. Register the line until the layer where it
    // ends is processed
    if (bobj.IsALine and element.attrs.PropertyExists('endid'))
    {
        bobj._property:mobj = element;
        PushToHashedLayer(Self._property:LineEndResolver, bobj.EndBarNumber, bobj);
    }

    AddControlEventAttributes(bobj, element);
    // add element to the measure objects so that they get added to the measure
    // later in the processing cycle.
    MeasureObjects.Push(element._id);
    return element;
}  //$end


function GenerateModifier (bobj, element) {
    if (bobj.Color != 0)
    {
        AddAttribute(element, 'color', ConvertColor(bobj));
    }

    nobj = GetNoteObjectAtPosition(bobj, 'Closest');

    if (nobj != null)
    {
        AddChild(nobj, element);
    }
    else
    {
        warnings = Self._property:warnings;
        barNum = bobj.ParentBar.BarNumber;
        voiceNum = bobj.VoiceNumber;
        if (bobj.Type = 'SymbolItem' or bobj.Type = 'SystemSymbolitem')
        {
            name = bobj.Name;
        }
        else
        {
            name = bobj.StyleAsText;
        }
        warnings.Push(utils.Format(_ObjectCouldNotFindAttachment, barNum, voiceNum, name));
    }
}  //$end


function GenerateTuplet(tupletObj) {
    //$module(ExportGenerators.mss)
    tuplet = CreateElement('tuplet');
    dur = tupletObj.PlayedDuration;

    AddAttribute(tuplet, 'dur.ppq', dur);
    AddAttribute(tuplet, 'num', tupletObj.Left);
    AddAttribute(tuplet, 'numbase', tupletObj.Right);

    tupletStyle = tupletObj.Style;

    switch (tupletStyle)
    {
        case(TupletNoNumber)
        {
            AddAttribute(tuplet, 'num.visible', 'false');
        }
        case(TupletLeft)
        {
            AddAttribute(tuplet, 'num.format', 'count');
        }
        case(TupletLeftRight)
        {
            AddAttribute(tuplet, 'num.format', 'ratio');
            AddAttribute(tuplet, 'num.visible', 'true');
        }
    }

    tupletBracket = tupletObj.Bracket;

    switch(tupletBracket)
    {
        case(TupletBracketOn)
        {
            AddAttribute(tuplet, 'bracket.visible', 'true');
        }
        case(TupletBracketOff)
        {
            AddAttribute(tuplet, 'bracket.visible', 'false');
        }
    }

    tuplet._property:SibTuplet = tupletObj;

    return tuplet;
}  //$end


function GenerateArpeggio (bobj) {
    //$module(ExportGenerators.mss)
    orientation = null;

    switch (bobj.Type)
    {
        case ('NoteRest')
        {
            switch (bobj.ArpeggioType)
            {
                case (ArpeggioTypeUp)
                {
                    orientation = 1;
                }
                case (ArpeggioTypeDown)
                {
                    orientation = -1;
                }
            }
            if (bobj.ArpeggioBottomDy > bobj.ArpeggioTopDy)
            {
                // Arpeggio was manipulated to be upside down
                orientation = -1 * orientation;
            }
        }
        case ('ArpeggioLine')
        {
            if (bobj.StyleId != 'line.staff.arpeggio') {
                // This means: Line style is line.staff.arpeggio.up or
                // line.staff.arpeggio.down.
                // Strangely, the line style does not really matter for the
                // visual orientation of the arpeggio. As long as RhDy and
                // and Dy properties are identical, arpeggios look the same,
                // independant of the two line styles with arrowheads.
                orientation = bobj.RhDy - bobj.Dy;
            }
        }
    }

    arpeg = GenerateControlEvent(bobj, CreateElement('arpeg'));

    if (orientation = null)
    {
        AddAttribute(arpeg, 'arrow', 'false');
    }
    else
    {
        AddAttribute(arpeg, 'arrow', 'true');

        if (orientation > 0)
        {
            AddAttribute(arpeg, 'order', 'up');
        }
        else
        {
            AddAttribute(arpeg, 'order', 'down');
        }
    }

    return arpeg;
}  //$end


function GenerateFermata (bobj, shape, form) {
    //$module(ExportGenerators.mss)
    fermata = GenerateControlEvent(bobj, CreateElement('fermata'));

    AddAttribute(fermata, 'form', form);
    AddAttribute(fermata, 'shape', shape);

    return fermata;
}  //$end

function GenerateChordSymbol (bobj) {
    //$module(ExportGenerators.mss)
    /*
        Generates a <harm> element containing chord symbol information
    */
    harm = GenerateControlEvent(bobj, CreateElement('harm'));
    SetText(harm, bobj.ChordNameAsPlainText);

    return harm;
}  //$end

function GenerateSmuflAltsym (glyphnum, glyphname) {
    //$module(ExportGenerators.mss)
    if (Self._property:SmuflSymbolIds = null)
    {
        Self._property:SmuflSymbolIds = CreateDictionary();
    }
    symbolIds = Self._property:SmuflSymbolIds;

    if (symbolIds[glyphnum] = null)
    {
        if (Self._property:SymbolTable = null)
        {
            symbolTable = CreateElement('symbolTable');
            scoreDef = Self._property:MainScoreDef;
            AddChildAtPosition(scoreDef, symbolTable, 0);
            Self._property:SymbolTable = symbolTable;
        }
        symbolTable = Self._property:SymbolTable;

        symbolDef = CreateElement('symbolDef');
        AddChild(symbolTable, symbolDef);
        anchoredText = CreateElement('anchoredText');
        AddChild(symbolDef, anchoredText);
        symbol = CreateElement('symbol');
        AddChild(anchoredText, symbol);
        AddAttribute(symbol, 'glyph.auth', 'smufl');
        AddAttribute(symbol, 'glyph.num', glyphnum);
        AddAttribute(symbol, 'glyph.name', glyphname);
        // Add x/y attributes to satisfy some Schematron rules
        AddAttribute(symbol, 'x', '0');
        AddAttribute(symbol, 'y', '0');


        symbolIds[glyphnum] = symbolDef._id;
    }

    return '#' & symbolIds[glyphnum];
}  //$end

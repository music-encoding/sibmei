function GenerateMEIHeader () {
    //$module(ExportGenerators.mss)
    // takes in a Sibelius Score object
    // returns a libmei tree (i.e., nested objects and arrays) with a MEI header with metadata
    score = Self._property:ActiveScore;


    header = libmei.MeiHead();
    Self._property:HeaderElement = header;

    fileD = libmei.FileDesc();
    titleS = libmei.TitleStmt();
    libmei.AddChild(header, fileD);
    libmei.AddChild(fileD, titleS);

    //encodingDesc must preceed workList in MEI 4.0
    encodingD = libmei.EncodingDesc();
    libmei.AddChild(header, encodingD);
    appI = GenerateApplicationInfo();
    libmei.AddChild(encodingD, appI);

    //generate workList
    workList = libmei.WorkList();
    Self._property:WorkListElement = workList;

    wd_work = libmei.Work();
    wd_title = libmei.Title();
    libmei.AddChild(wd_work, wd_title);
    libmei.AddChild(workList, wd_work);
    libmei.AddChild(header, workList);

    title = libmei.Title();
    libmei.AddChild(titleS, title);

    if (score.Title != '')
    {
        libmei.SetText(title, score.Title);
        libmei.SetText(wd_title, score.Title);
    }
    if (score.Subtitle != '')
    {
        subtitle = libmei.Title();
        libmei.AddChild(titleS, subtitle);
        libmei.SetText(subtitle, score.Subtitle);
        libmei.AddAttribute(subtitle, 'type', 'subtitle');
    }
    if (score.Composer != '')
    {
        composer = libmei.Composer();
        libmei.AddChild(titleS, composer);
        libmei.SetText(composer, score.Composer);
        wd_composer = libmei.Composer();
        libmei.SetText(wd_composer, score.Composer);
        libmei.AddChild(wd_work, wd_composer);
    }
    if (score.Lyricist != '')
    {
        lyricist = libmei.Lyricist();
        libmei.AddChild(titleS, lyricist);
        libmei.SetText(lyricist, score.Lyricist);
        wd_lyricist = libmei.Lyricist();
        libmei.SetText(wd_lyricist, score.Lyricist);
        libmei.AddChild(wd_work, wd_lyricist);
    }
    if (score.Arranger != '')
    {
        arranger = libmei.Arranger();
        libmei.AddChild(titleS, arranger);
        libmei.SetText(arranger, score.Arranger);
        wd_arranger = libmei.Arranger();
        libmei.SetText(wd_arranger, score.Arranger);
        libmei.AddChild(wd_work, wd_arranger);
    }
    if (score.OtherInformation != '')
    {
        wd_notesStmt = libmei.NotesStmt();
        ns_annot = libmei.Annot();
        libmei.AddChild(wd_work, wd_notesStmt);
        libmei.AddChild(wd_notesStmt, ns_annot);
        libmei.SetText(ns_annot, score.OtherInformation);
    }

    respS = libmei.RespStmt();
    libmei.AddChild(titleS, respS);
    persN = libmei.PersName();
    libmei.AddChild(respS, persN);
    pubS = libmei.PubStmt();
    libmei.AddChild(fileD, pubS);

    avail = libmei.Availability();
    ur = libmei.UseRestrict();
    libmei.AddChild(avail, ur);
    libmei.AddChild(pubS, avail);
    libmei.SetText(ur, score.Copyright);

    return header;
}  //$end

function GenerateApplicationInfo () {
    //$module(ExportGenerators.mss)

    appI = libmei.AppInfo();

    applic = libmei.Application();
    libmei.SetId(applic, 'sibelius');
    libmei.AddChild(appI, applic);
    libmei.AddAttribute(applic, 'version', Sibelius.ProgramVersion);
    isodate = ConvertDate(Sibelius.CurrentDate);
    libmei.AddAttribute(applic, 'isodate', isodate);
    osname = libmei.Name();
    libmei.SetText(osname, Sibelius.OSVersionString);
    libmei.AddAttribute(osname, 'type', 'operating-system');
    libmei.AddChild(applic, osname);

    plgapp = libmei.Application();
    plgname = libmei.Name();
    libmei.SetText(plgname, PluginName & ' (' & Version & ')');
    libmei.AddAttribute(plgapp, 'type', 'plugin');
    libmei.AddAttribute(plgapp, 'version', Version);
    libmei.SetId(plgapp, 'sibmei');
    libmei.AddChild(plgapp, plgname);
    libmei.AddChild(appI, plgapp);

    return appI;

}   //$end

function GenerateMEIMusic () {
    //$module(ExportGenerators.mss)
    score = Self._property:ActiveScore;

    Self._property:TieResolver = CreateDictionary();
    Self._property:SlurResolver = CreateSparseArray();
    Self._property:LyricWords = CreateDictionary();
    Self._property:SpecialBarlines = CreateDictionary();
    Self._property:SystemText = CreateDictionary();
    Self._property:LayerObjectPositions = null;
    Self._property:ObjectPositions = CreateDictionary();

    Self._property:VoltaBars = CreateDictionary();
    Self._property:ActiveVolta = null;
    Self._property:VoltaElement = null;

    Self._property:BodyElement = null;
    Self._property:MDivElement = null;
    Self._property:SectionElement = null;

    // track page numbers
    Self._property:CurrentPageNumber = null;
    // We start the first page with a <pb> (good practice and helps Verovio)
    Self._property:PageBreak = libmei.Pb();
    Self._property:SystemBreak = null;
    Self._property:FrontMatter = CreateDictionary();

    // grab some global markers from the system staff
    // This will store it for later use.
    ProcessSystemStaff(score);

    music = libmei.Music();

    frontmatter = Self._property:FrontMatter;
    frontpages = frontmatter.GetPropertyNames();

    if (frontpages.Length > 0)
    {
        // sort the front pages
        // Log('front: ' & frontmatter);
        sorted_front = utils.SortArray(frontpages, False);
        frontEl = libmei.Front();
        for each pnum in sorted_front
        {
            pgels = frontmatter[pnum];

            for each el in pgels
            {
                libmei.AddChild(frontEl, el);
            }
        }

        libmei.AddChild(music, frontEl);
    }

    body = libmei.Body();
    libmei.AddChild(music, body);
    Self._property:BodyElement = body;

    // start with the first bar.
    FIRST_BAR = 1;
    mdiv = GenerateMDiv(FIRST_BAR);
    libmei.AddChild(body, mdiv);

    barmap = ConvertSibeliusStructure(score);
    numbars = barmap.GetPropertyNames();
    numbars = numbars.Length;
    Self._property:BarMap = barmap;

    systf = score.SystemStaff;

    currentScoreDef = null;

    for j = 1 to numbars + 1
    {
        // this value may get changed by the volta processor
        // to inject a new parent in the hierarchy.
        progressMsg = utils.Format(_ExportingBars, j, numbars);
        cont = Sibelius.UpdateProgressDialog(j, progressMsg);
        section = Self._property:SectionElement;

        // if the user has clicked cancel, stop the plugin.
        if (cont = 0)
        {
            ExitPlugin();
        }

        m = GenerateMeasure(j);
        ending = ProcessVolta(j);

        if (Self._property:PageBreak != null)
        {
            pb = Self._property:PageBreak;
            libmei.AddChild(section, pb);
            Self._property:PageBreak = null;
        }

        currTimeS = systf.CurrentTimeSignature(j);
        currKeyS = systf.CurrentKeySignature(j);

        if (Self._property:SystemBreak != null)
        {
            sb = Self._property:SystemBreak;
            libmei.AddChild(section, sb);
            Self._property:SystemBreak = null;
        }

        // Do not try to get the signatures for bar 0 -- will not work
        if (j > 1)
        {
            prevTimeS = systf.CurrentTimeSignature(j - 1);
            prevKeyS = systf.CurrentKeySignature(j - 1);
        }
        else
        {
            prevTimeS = systf.CurrentTimeSignature(j);
            prevKeyS = systf.CurrentKeySignature(j);
        }

        /*
            This will check for a change in the current time signature and create a new
            scoredef element if it's changed. The key signature will always be processed later,
            so by then we will either have a new scoredef with a timesig change, or we'll need
            to create one just for the keysig change.
        */
        if ((currTimeS.Numerator != prevTimeS.Numerator) or (currTimeS.Denominator != prevTimeS.Denominator))
        {
            currentScoreDef = libmei.ScoreDef();
            // Log('Time Signature Change in Bar ' & j);
            libmei.AddAttribute(currentScoreDef, 'meter.count', currTimeS.Numerator);
            libmei.AddAttribute(currentScoreDef, 'meter.unit', currTimeS.Denominator);
            libmei.AddAttribute(currentScoreDef, 'meter.sym', ConvertNamedTimeSignature(currTimeS.Text));
        }

        if (currKeyS.Sharps != prevKeyS.Sharps)
        {
            if (currentScoreDef = null)
            {
                currentScoreDef = libmei.ScoreDef();
            }

            libmei.AddAttribute(currentScoreDef, 'key.sig', ConvertKeySignature(currKeyS.Sharps));
        }

        if (currentScoreDef != null)
        {
            // The sig changes must be added just before we add the measure to keep
            // the proper order.
            if (ending != null)
            {
                libmei.AddChild(ending, currentScoreDef);
            }
            else
            {
                libmei.AddChild(section, currentScoreDef);
            }
            currentScoreDef = null;
        }

        if (ending != null)
        {
            libmei.AddChild(section, ending);
            libmei.AddChild(ending, m);
        }
        else
        {
            libmei.AddChild(section, m);
        }
    }

    return music;
}  //$end

function GenerateMDiv (barnum) {
    //$module(ExportGenerators.mss)
    // Add the first mdiv; Movements will add new ones.
    score = Self._property:ActiveScore;

    mdiv = libmei.Mdiv();
    Self._property:MDivElement = mdiv;

    ano = libmei.Annot();
    libmei.AddAttribute(ano, 'type', 'duration');
    libmei.SetText(ano, ConvertTimeStamp(score.ScoreDuration));

    sco = libmei.Score();
    libmei.AddChild(mdiv, sco);

    scd = GenerateScoreDef(score, barnum);
    Self._property:MainScoreDef = scd;
    libmei.AddChild(sco, scd);

    section = libmei.Section();
    Self._property:SectionElement = section;
    libmei.AddChild(sco, section);

    //annot is valid as a child of score
    libmei.AddChild(sco, ano);

    return mdiv;
} //$end

function GenerateMeasure (num) {
    //$module(ExportGenerators.mss)

    score = Self._property:ActiveScore;
    // measureties
    Self._property:MeasureTies = CreateSparseArray();
    Self._property:MeasureObjects = CreateSparseArray();

    m = libmei.Measure();
    libmei.AddAttribute(m, 'n', num);

    barmap = Self._property:BarMap;
    staves = barmap[num];
    children = CreateSparseArray();

    // since so much metadata about the staff and other context
    // is available on the bar that should now be on the measure, go through the bars
    // and try to extract it.
    systf = score.SystemStaff;
    currTimeS = systf.CurrentTimeSignature(num);
    sysBar = systf[num];

    if (sysBar.Length != (currTimeS.Numerator * 1024 / currTimeS.Denominator))
    {
        libmei.AddAttribute(m, 'metcon', 'false');
    }

    if (sysBar.NthBarInSystem = 0)
    {
        Self._property:SystemBreak = libmei.Sb();
    }

    for i = 1 to staves.Length + 1
    {
        this_staff = score.NthStaff(i);
        bar = this_staff[num];

        curr_pn = bar.OnNthPage;
        if (curr_pn != Self._property:CurrentPageNumber)
        {
            Self._property:CurrentPageNumber = curr_pn;
            pb = libmei.Pb();

            // pages are stored internally as 0-based, so increment by one for the 'human' representation.
            libmei.AddAttribute(pb, 'n', curr_pn + 1);
            Self._property:PageBreak = pb;
        }

        if (bar.ExternalBarNumberString and libmei.GetAttribute(m, 'label') = False)
        {
            libmei.AddAttribute(m, 'label', bar.ExternalBarNumberString);
        }

        s = GenerateStaff(i, num);
        libmei.AddChild(m, s);
    }

    mties = Self._property:MeasureTies;

    for each tie in mties
    {
        m.children.Push(tie);
    }

    mlines = Self._property:MeasureObjects;

    for each line in mlines
    {
        m.children.Push(line);
    }

    specialbarlines = Self._property:SpecialBarlines;

    if (specialbarlines.PropertyExists(num))
    {
        // an array of bar lines for this measure
        blines = specialbarlines[num];

        for each bline in blines
        {
            if (bline = 'rptstart')
            {
                libmei.AddAttribute(m, 'left', bline);
            }
            else
            {
                libmei.AddAttribute(m, 'right', bline);
            }
        }
    }

    systemtext = Self._property:SystemText;

    if (systemtext.PropertyExists(num))
    {
        textobjs = systemtext[num];
        for each textobj in textobjs
        {
            text = HandleText(textobj);

            if (text != null)
            {
                libmei.AddChild(m, text);
            }
        }
    }

    // If we've reached the end of the section, swap out the mdiv to a new one.
    if (sysBar.SectionEnd = true)
    {
        body = Self._property:BodyElement;
        // create the mdiv for the next bar.
        newMdiv = GenerateMDiv(num + 1);
        libmei.AddChild(body, newMdiv);
        // a new section end means a new entry in the header.
        workList = Self._property:WorkListElement;
        workEl = libmei.Work();
        libmei.AddChild(workList, workEl);
    }

    return m;
}  //$end


function GenerateStaff (staffnum, measurenum) {
    //$module(ExportGenerators.mss)
    score = Self._property:ActiveScore;
    this_staff = score.NthStaff(staffnum);
    bar = this_staff[measurenum];

    stf = libmei.Staff();

    if (bar.OnHiddenStave)
    {
        libmei.AddAttribute(stf, 'visible', 'false');
    }

    libmei.AddAttribute(stf, 'n', staffnum);

    layers = GenerateLayers(staffnum, measurenum);
    // NB: Completely resets any previous children!
    libmei.SetChildren(stf, layers);

    return stf;
}  //$end

function GenerateLayers (staffnum, measurenum) {
    //$module(ExportGenerators.mss)
    layerdict = CreateDictionary();
    layers = CreateSparseArray();

    objectPositions = Self._property:ObjectPositions;

    if (objectPositions.PropertyExists(staffnum) = False)
    {
        objectPositions[staffnum] = CreateDictionary();
    }

    staffObjectPositions = objectPositions[staffnum];

    score = Self._property:ActiveScore;
    this_staff = score.NthStaff(staffnum);
    bar = this_staff[measurenum];
    l = null;

    mobjs = Self._property:MeasureObjects;

    for each bobj in bar
    {
        voicenumber = bobj.VoiceNumber;

        if (staffObjectPositions.PropertyExists(bar.BarNumber) = False)
        {
            staffObjectPositions[bar.BarNumber] = CreateDictionary();
        }

        barObjectPositions = staffObjectPositions[bar.BarNumber];

        if (layerdict.PropertyExists(voicenumber))
        {
            l = layerdict[voicenumber];
        }
        else
        {
            if (voicenumber != 0 or (l = null and bobj.Type = 'Clef'))
            {
                l = libmei.Layer();
                layers.Push(l._id);

                if (barObjectPositions.PropertyExists(voicenumber) = False)
                {
                    barObjectPositions[voicenumber] = CreateDictionary();
                }

                layerdict[voicenumber] = l;
                libmei.AddAttribute(l, 'n', voicenumber);

                l._property:CurrentPos = 0;
            }
        }

        obj = null;
        mobj = null;
        parent = null;
        beam = null;
        tuplet = null;

        switch (bobj.Type)
        {
            case('Clef')
            {
                // Clefs are placed inside the musical flow like notes.  Hence we also need to find
                // out whether they are part of beams or tuplets.
                clef = GenerateClef(bobj);

                prevNoteRest = PrevNormalOrGrace(bobj, false);

                if (prevNoteRest != null)
                {
                    prevBeamProp = NormalizedBeamProp(prevNoteRest);

                    switch (prevBeamProp)
                    {
                        case ('StartBeam')
                        {
                            beam = l._property:ActiveBeam;
                        }
                        case ('NoBeam')
                        {
                            beam = null;
                        }
                        default
                        {
                            // ContinueBeam and SingleBeam
                            nextNoteRest = NextNormalOrGrace(bobj, false);
                            if (nextNoteRest != null)
                            {
                                nextBeamProp = NormalizedBeamProp(nextNoteRest);
                                if ((nextBeamProp = ContinueBeam) or (nextBeamProp = SingleBeam))
                                {
                                    beam = l._property:ActiveBeam;
                                }
                            }
                        }
                    }

                    tuplet = l._property:ActiveMeiTuplet;
                    while (tuplet != null and tuplet._property:ParentTuplet != null)
                    {
                        tuplet = tuplet._property:ParentTuplet;
                    }
                }

                AppendToLayer(clef, l, beam, tuplet);
            }
            case('NoteRest')
            {
                note = GenerateNoteRest(bobj, l);

                if (note != null)
                {
                    // record the position of this element
                    objVoice = barObjectPositions[voicenumber];
                    objVoice[bobj.Position] = note._id;

                    normalizedBeamProp = NormalizedBeamProp(bobj);

                    if (normalizedBeamProp = SingleBeam)
                    {
                        if (bobj.GraceNote)
                        {
                            prevNote = l._property:PrevGraceNote;
                        }
                        else
                        {
                            prevNote = l._property:PrevNote;
                        }
                        // prevNote is not null here - unless we have a bug in NormalizeBeamProp()
                        // or the registration of previous notes.
                        libmei.AddAttribute(prevNote, 'breaksec', '1');
                    }

                    // fetch or create the active beam object (if any)
                    beam = ProcessBeam(bobj, l, normalizedBeamProp);

                    // fetch or create the active tuplet object (if any)
                    tuplet = ProcessTuplet(bobj, note, l);

                    if (bobj.GraceNote)
                    {
                        l._property:PrevGraceNote = note;
                    }
                    else
                    {
                        l._property:PrevNote = note;
                    }

                    AppendToLayer(note, l, beam, tuplet);
                }

                if (bobj.ArpeggioType != ArpeggioTypeNone) {
                    arpeg = GenerateArpeggio(bobj);
                    mobjs = Self._property:MeasureObjects;
                    mobjs.Push(arpeg._id);
                    Self._property:MeasureObjects = mobjs;
                }
            }
            case('BarRest')
            {
                brest = GenerateBarRest(bobj);

                if (brest != null)
                {
                    libmei.AddChild(l, brest);
                }
            }
        }
    }

    for each bobj in bar
    {
        obj = null;
        mobj = null;
        chordsym = null;

        switch (bobj.Type)
        {
            case('GuitarFrame')
            {
                chordsym = GenerateChordSymbol(bobj);
            }
            case('Slur')
            {
                mobj = GenerateLine(bobj);
                bobj._property:mobj = mobj;
                PushToHashedLayer(Self._property:SlurResolver, bobj.EndBarNumber, bobj);
            }
            case('CrescendoLine')
            {
                mobj = GenerateLine(bobj);
            }
            case('DiminuendoLine')
            {
                mobj = GenerateLine(bobj);
            }
            case('OctavaLine')
            {
                mobj = GenerateLine(bobj);
            }
            case('GlissandoLine')
            {
                mobj = GenerateLine(bobj);
            }
            case('Trill')
            {
                mobj = GenerateLine(bobj);
            }
            case('ArpeggioLine')
            {
                mobj = GenerateArpeggio(bobj);
            }
            case('RepeatTimeLine')
            {
                RegisterVolta(bobj);
            }
            case('Line')
            {
                mobj = GenerateLine(bobj);
            }
            case('Text')
            {
                mobj = HandleText(bobj);
            }
        }

        if (mobj != null)
        {
            mobjs = Self._property:MeasureObjects;
            mobjs.Push(mobj._id);
            Self._property:MeasureObjects = mobjs;
        }

        // add chord symbols to the measure objects
        // so that they get added to the measure later in the processing cycle.
        if (chordsym != null)
        {
            mlines = Self._property:MeasureObjects;
            mlines.Push(chordsym._id);
            Self._property:MeasureObjects = mlines;
        }
    }

    Self._property:MeasureObjects = mobjs;

    for each LyricItem lobj in bar
    {
        ProcessLyric(lobj, objectPositions);
    }

    for each SymbolItem sobj in bar
    {
        HandleSymbol(sobj);
    }

    ProcessEndingSlurs(bar);

    return layers;
}  //$end

function GenerateClef (bobj) {
    //$module(ExportGenerators.mss)
    clefinfo = ConvertClef(bobj.StyleId);
    clef_el = libmei.Clef();

    libmei.AddAttribute(clef_el, 'shape', clefinfo[0]);
    libmei.AddAttribute(clef_el, 'line', clefinfo[1]);
    libmei.AddAttribute(clef_el, 'dis', clefinfo[2]);
    libmei.AddAttribute(clef_el, 'dis.place', clefinfo[3]);
    libmei.AddAttribute(clef_el, 'tstamp', ConvertPositionToTimestamp(bobj.Position, bobj.ParentBar));
    libmei.AddAttribute(clef_el, 'staff', bobj.ParentBar.ParentStaff.StaffNum);

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
            libmei.AddAttribute(nr, 'stem.dir', 'up');
        }
        else
        {
            libmei.AddAttribute(nr, 'stem.dir', 'down');
        }
    }

    if (bobj.Dx != 0)
    {
        libmei.AddAttribute(nr, 'ho', ConvertOffsetsToMEI(bobj.Dx));
    }

    if (bobj.CueSize = true and libmei.GetName(nr) != 'space')
    {
        libmei.AddAttribute(nr, 'fontsize', 'small');
    }

    if (bobj.Hidden = true and libmei.GetName(nr) != 'space')
    {
        libmei.AddAttribute(nr, 'visible', 'false');
    }

    if (bobj.Color != 0)
    {
        nrest_color = ConvertColor(bobj);
        libmei.AddAttribute(nr, 'color', nrest_color);
    }

    /* NB: If there is a problem with grace notes, look here first.
        I think most of these cases should be covered by appog. and acciacc.
        but possibly not...

    if (bobj.GraceNote = True)
    {
        libmei.AddAttribute(nr, 'grace', 'acc');
    }
    */

    if (bobj.IsAppoggiatura = True)
    {
        libmei.AddAttribute(nr, 'grace', 'acc');
    }

    if (bobj.IsAcciaccatura = True)
    {
        libmei.AddAttribute(nr, 'grace', 'unacc');
        libmei.AddAttribute(nr, 'stem.mod', '1slash');
    }

    if (bobj.GetArticulation(PauseArtic) or bobj.GetArticulation(TriPauseArtic) or bobj.GetArticulation(SquarePauseArtic))
    {
        fermata = GenerateFermata(bobj);
        if (fermata != null)
        {
            libmei.AddAttribute(fermata, 'startid', '#' & nr._id);
            measureObjs = Self._property:MeasureObjects;
            measureObjs.Push(fermata._id);
        }
    }

    if (bobj.GetArticulation(StaccatoArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'stacc');
    }

    if (bobj.GetArticulation(TenutoArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'ten');
    }

    if (bobj.GetArticulation(MarcatoArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'marc');
    }

    if (bobj.GetArticulation(DownBowArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'dnbow');
    }

    if (bobj.GetArticulation(UpBowArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'upbow');
    }

    if (bobj.GetArticulation(AccentArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'acc');
    }

    if (bobj.GetArticulation(StaccatissimoArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'stacciss');
    }

    if (bobj.GetArticulation(PlusArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'stop');
    }

    if (bobj.GetArticulation(HarmonicArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'harm');
    }

    if (bobj.FallType = FallTypeDoit)
    {
        libmei.AddAttributeValue(nr, 'artic', 'doit');
    }

    if (bobj.FallType = FallTypeNormal)
    {
        libmei.AddAttributeValue(nr, 'artic', 'fall');
    }

    if (bobj.ScoopType = ScoopTypePlop)
    {
        libmei.AddAttributeValue(nr, 'artic', 'plop');
    }

    if ((bobj.SingleTremolos > 0) or (bobj.SingleTremolos = ZOnStem))
    {
        // btrem = libmei.BTrem();
        // libmei.AddChild(btrem, nr);

        if (bobj.SingleTremolos = ZOnStem)
        {
            stemmod = 'z';
        }
        else
        {
            stemmod = bobj.SingleTremolos & 'slash';
        }

        libmei.AddAttribute(nr, 'stem.mod', stemmod);
    }

    libmei.AddAttribute(nr, 'tstamp.real', ConvertTimeStamp(bobj.Time));

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
        r = libmei.Space();
    }
    else
    {
        r = libmei.Rest();
    }

    name = libmei.GetName(r);
    libmei.AddAttribute(r, 'dur', meidur[0]);
    libmei.AddAttribute(r, 'dur.ppq', dur);
    libmei.AddAttribute(r, 'dots', meidur[1]);

    if (bobj.Dx != 0 and name != 'space')
    {
        libmei.AddAttribute(r, 'ho', ConvertOffsetsToMEI(bobj.Dx));
    }

    if (bobj.Dy != 0 and name != 'space')
    {
        libmei.AddAttribute(r, 'vo', ConvertOffsetsToMEI(bobj.Dy));
    }

    if (bobj.CueSize = true and name != 'space')
    {
        libmei.AddAttribute(r, 'fontsize', 'small');
    }

    if (bobj.Color != 0 and name != 'space')
    {
        nrest_color = ConvertColor(bobj);
        libmei.AddAttribute(r, 'color', nrest_color);
    }

    if (bobj.GetArticulation(PauseArtic))
    {
        libmei.AddAttribute(r, 'fermata', 'above');
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

    n = libmei.Note();
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

        libmei.AddAttribute(n, 'oct.ges', octges);
    }

    libmei.AddAttribute(n, 'vel', vel);
    libmei.AddAttribute(n, 'pnum', pnum);
    libmei.AddAttribute(n, 'pname', ntinfo[0]);
    libmei.AddAttribute(n, 'oct', ntinfo[1]);
    libmei.AddAttribute(n, 'dur', meidur[0]);
    libmei.AddAttribute(n, 'dur.ppq', gesdur);
    libmei.AddAttribute(n, 'dots', meidur[1]);

    if (nobj.Dx != 0)
    {
        libmei.AddAttribute(n, 'ho', ConvertOffsetsToMEI(nobj.Dx));
    }

    if (nobj.Color != nobj.ParentNoteRest.Color)
    {
        note_color = ConvertColor(nobj);
        libmei.AddAttribute(n, 'color', note_color);
    }

    staff = nobj.ParentNoteRest.ParentBar.ParentStaff.StaffNum;
    layer = nobj.ParentNoteRest.VoiceNumber;

    //libmei.AddAttribute(n, 'staff', staff);
    //libmei.AddAttribute(n, 'layer', layer);

    if (nobj.NoteStyle != NormalNoteStyle)
    {
        nstyle = ConvertNoteStyle(nobj.NoteStyle);
        libmei.AddAttribute(n, 'head.shape', nstyle);
    }

    accid = ConvertAccidental(nobj, keysig.Sharps);
    accVal = accid[0];
    isVisible = accid[1];

    if (accVal != ' ')
    {
        child = libmei.Accid();
        libmei.AddChild(n, child);

        if (isVisible = True)
        {
            libmei.AddAttribute(child, 'accid', accVal);
        }
        else
        {
            libmei.AddAttribute(child, 'accid.ges', accVal);
        }

        switch (nobj.AccidentalStyle)
        {
            case (CautionaryAcc)
            {
                libmei.AddAttribute(child, 'func', 'caution');
            }
            case (BracketedAcc)
            {
                libmei.AddAttribute(child, 'enclose', 'paren');
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
        tie_el = libmei.getElementById(tie_id);
        libmei.AddAttribute(tie_el, 'endid', '#' & n._id);

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
        tie_el = libmei.getElementById(tie_id);
        libmei.AddAttribute(tie_el, 'endid', '#' & n._id);

        tie_resolver[prev_tie_idx] = null;
    }

    if (nobj.Tied = True)
    {
        measure_ties = Self._property:MeasureTies;

        tie = libmei.Tie();
        libmei.AddAttribute(tie, 'startid', '#' & n._id);
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
    n = libmei.Chord();
    dur = bobj.Duration;
    meidur = ConvertDuration(dur);

    libmei.AddAttribute(n, 'dur', meidur[0]);
    libmei.AddAttribute(n, 'dur.ppq', dur);
    libmei.AddAttribute(n, 'dots', meidur[1]);

    for each note in bobj
    {
        sn = GenerateNote(note);
        libmei.AddChild(n, sn);
    }

    return n;
}  //$end

function GenerateBarRest (bobj) {
    //$module(ExportGenerators.mss)
    switch (bobj.RestType)
    {
        case(BreveBarRest)
        {
            obj = libmei.MRest();
            libmei.AddAttribute(obj, 'dur', 'breve');
        }
        case (WholeBarRest)
        {
            obj = libmei.MRest();
        }
        case (OneBarRepeat)
        {
            obj = libmei.MRpt();
        }
        case (TwoBarRepeat)
        {
            obj = libmei.MRpt2();
        }
        case (FourBarRepeat)
        {
            // MEI now supports a four-bar repeat
            obj = libmei.MultiRpt();
            libmei.AddAttribute(obj, 'num', '4');
        }
    }

    fermata = GenerateFermata(bobj);
    if (fermata != null)
    {
        libmei.AddAttribute(fermata, 'startid', '#' & obj._id);
        measureObjs = Self._property:MeasureObjects;
        measureObjs.Push(fermata._id);
    }

    if (bobj.Hidden = true)
    {
        libmei.AddAttribute(obj, 'visible', 'false');
    }

    libmei.AddAttribute(obj, 'tstamp.real', ConvertTimeStamp(bobj.Time));

    return obj;
}  //$end

function GenerateScoreDef (score, barnum) {
    //$module(ExportGenerators.mss)
    scoredef = libmei.ScoreDef();
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

    libmei.AddAttribute(scoredef, 'page.width', docSettings.PageWidth & unit);
    libmei.AddAttribute(scoredef, 'page.height', docSettings.PageHeight & unit);
    libmei.AddAttribute(scoredef, 'page.leftmar', docSettings.PageLeftMargin & unit);
    libmei.AddAttribute(scoredef, 'page.rightmar', docSettings.PageRightMargin & unit);
    libmei.AddAttribute(scoredef, 'page.topmar', docSettings.PageTopMargin & unit);
    libmei.AddAttribute(scoredef, 'page.botmar', docSettings.PageBottomMargin & unit);
    libmei.AddAttribute(scoredef, 'vu.height', vuval & unit);

    showCautionaryAccidentals = score.EngravingRules.CautionaryNaturalsInKeySignatures;
    if (showCautionaryAccidentals = true)
    {
        libmei.AddAttribute(scoredef, 'keysig.showchange', 'true');
    }

    libmei.AddAttribute(scoredef, 'music.name', score.MainMusicFontName);
    libmei.AddAttribute(scoredef, 'text.name', score.MainTextFontName);
    // We should read out the lyrics font styles here (e.g. `text.staff.space.hypen.lyrics.verse1`),
    // but the styles properties don't seem to be easily accessible.
    libmei.AddAttribute(scoredef, 'lyric.name', score.MainTextFontName);

    libmei.AddAttribute(scoredef, 'spacing.staff', score.EngravingRules.SpacesBetweenStaves * 2);
    libmei.AddAttribute(scoredef, 'spacing.system', score.EngravingRules.SpacesBetweenSystems * 2);

    systf = score.SystemStaff;
    timesig = systf.CurrentTimeSignature(1);

    libmei.AddAttribute(scoredef, 'meter.count', timesig.Numerator);
    libmei.AddAttribute(scoredef, 'meter.unit', timesig.Denominator);
    libmei.AddAttribute(scoredef, 'meter.sym', ConvertNamedTimeSignature(timesig.Text));
    libmei.AddAttribute(scoredef, 'ppq', '256'); // sibelius' internal ppq.

    if (score.StaffCount > 0)
    {
        staffgrp = GenerateStaffGroups(score, barnum);
        libmei.AddChild(scoredef, staffgrp);
    }

    return scoredef;
}  //$end

function GenerateStaffGroups (score, barnum) {
    //$module(ExportGenerators.mss)
    staffdict = CreateDictionary();
    parentstgrp = libmei.StaffGrp();
    numstaff = score.StaffCount;

    for each Staff s in score
    {
        std = libmei.StaffDef();
        libmei.XMLIdToObjectMap[std._id] = s;

        libmei.AddAttribute(std, 'n', s.StaffNum);
        libmei.AddAttribute(std, 'lines', s.InitialInstrumentType.NumStaveLines);

        diaTrans = s.InitialInstrumentType.DiatonicTransposition;
        semiTrans = s.InitialInstrumentType.ChromaticTransposition;
        if (diaTrans != 0 and semiTrans != 0)
        {
            libmei.AddAttribute(std, 'trans.semi', semiTrans);
            libmei.AddAttribute(std, 'trans.diat', diaTrans);
        }

        clefinfo = ConvertClef(s.InitialClefStyleId);
        libmei.AddAttribute(std, 'clef.shape', clefinfo[0]);
        libmei.AddAttribute(std, 'clef.line', clefinfo[1]);
        libmei.AddAttribute(std, 'clef.dis', clefinfo[2]);
        libmei.AddAttribute(std, 'clef.dis.place', clefinfo[3]);

        keysig = s.CurrentKeySignature(barnum);
        libmei.AddAttribute(std, 'key.sig', ConvertKeySignature(keysig.Sharps));

        if (keysig.Major)
        {
            libmei.AddAttribute(std, 'key.mode', 'major');
        }
        else
        {
            libmei.AddAttribute(std, 'key.mode', 'minor');
        }

        if (s.FullInstrumentName != null)
        {
            label = libmei.Label();
            libmei.SetText(label, s.FullInstrumentName);
            libmei.AddChild(std, label);
        }

        if (s.ShortInstrumentName != null)
        {
            labelAbbr = libmei.LabelAbbr();
            libmei.SetText(labelAbbr, s.ShortInstrumentName);
            libmei.AddChild(std, labelAbbr);
        }

        if (s.InstrumentName != null)
        {
            instrObj = s.InitialInstrumentType;
            instrComment = libmei.XMLComment(instrObj.DefaultSoundId);
            libmei.AddChild(std, instrComment);

            instrDef = libmei.InstrDef();
            // libmei.AddAttribute(instrDef, 'midi.instrname', s.InstrumentName);
            // midi pan is 0-127, Sib. pan is -127 to + 127, so this needs to be converted.
            pan = RoundUp((s.Pan + 127) / 2);
            libmei.AddAttribute(instrDef, 'midi.pan', pan);
            libmei.AddAttribute(instrDef, 'midi.volume', s.Volume);
            libmei.AddAttribute(instrDef, 'midi.channel', s.Channel);
            libmei.AddChild(std, instrDef);
        }

        staffdict[s.StaffNum] = std;
    }

    stgpdict = CreateDictionary();
    stgprevidx = CreateDictionary();
    stgpnum = 1;
    brackets = score.BracketsAndBraces;

    for each bkt in brackets
    {
        stgp = libmei.StaffGrp();
        libmei.AddAttribute(stgp, 'symbol', ConvertBracket(bkt.BracketType));
        libmei.AddAttribute(stgp, 'n', stgpnum);
        stgpdict[stgpnum] = stgp;

        if (bkt.BracketType != BracketSub)
        {
            for i = bkt.TopStaveNum to bkt.BottomStaveNum + 1
            {
                libmei.AddChild(stgp, staffdict[i]);
                stgprevidx[i] = stgpnum;
            }
        }
        stgpnum = stgpnum + 1;
    }

    // finally, we need to put them all in the right order.
    stgpnum_added = CreateSparseArray();
    for j = 1 to numstaff + 1
    {
        if (stgprevidx.PropertyExists(j))
        {
            // there is a group
            stgpnum = stgprevidx[j];
            if (utils.IsInArray(stgpnum_added, stgpnum) = false)
            {
                libmei.AddChild(parentstgrp, stgpdict[stgpnum]);
                stgpnum_added.Push(stgpnum);
            }
        }
        else
        {
            libmei.AddChild(parentstgrp, staffdict[j]);
        }

    }
    return parentstgrp;
}  //$end

function GenerateTuplet(tupletObj) {
    //$module(ExportGenerators.mss)
    tuplet = libmei.Tuplet();

    libmei.AddAttribute(tuplet, 'num', tupletObj.Left);
    libmei.AddAttribute(tuplet, 'numbase', tupletObj.Right);

    tupletStyle = tupletObj.Style;

    switch (tupletStyle)
    {
        case(TupletNoNumber)
        {
            libmei.AddAttribute(tuplet, 'dur.visible', 'false');
        }
        case(TupletLeft)
        {
            libmei.AddAttribute(tuplet, 'num.format', 'count');
        }
        case(TupletLeftRight)
        {
            libmei.AddAttribute(tuplet, 'num.format', 'ratio');
        }
    }

    tupletBracket = tupletObj.Bracket;

    switch(tupletBracket)
    {
        case(TupletBracketOff)
        {
            libmei.AddAttribute(tuplet, 'bracket.visible', 'false');
        }
    }

    tuplet._property:SibTuplet = tupletObj;

    return tuplet;
}  //$end

function GenerateLine (bobj) {
    //$module(ExportGenerators.mss)
    line = null;
    bar = bobj.ParentBar;

    switch (bobj.Type)
    {
        case ('Slur')
        {
            line = libmei.Slur();
            slurrend = ConvertSlurStyle(bobj.StyleId);
            libmei.AddAttribute(line, 'lform', slurrend[1]);
        }
        case ('CrescendoLine')
        {
            line = libmei.Hairpin();
            libmei.AddAttribute(line, 'form', 'cres');
        }
        case ('DiminuendoLine')
        {
            line = libmei.Hairpin();
            libmei.AddAttribute(line, 'form', 'dim');
        }
        case ('OctavaLine')
        {
            line = libmei.Octave();
            octrend = ConvertOctava(bobj.StyleId);
            libmei.AddAttribute(line, 'dis', octrend[0]);
            libmei.AddAttribute(line, 'dis.place', octrend[1]);
        }
        case ('GlissandoLine')
        {
            line = libmei.Gliss();
        }
        case ('Trill')
        {
            line = GenerateTrill(bobj);
            // NB: Return here since the trill already has its properties set.
            return line;
        }
        case ('Line')
        {
            // a generic line element.
            linecomps = MSplitString(bobj.StyleId, '.');
            switch(linecomps[2])
            {
                //brackets
                case ('bracket')
                {
                    line = libmei.Line();
                    bracketType = 'bracket';

                    //horizontal brackets
                    if (linecomps.Length >= 3)
                    {
                        //brackets above
                        if (linecomps[3] = 'above')
                        {
                            libmei.AddAttribute(line, 'place', 'above');

                            if (linecomps.Length > 4)
                            {
                                if (linecomps[4] = 'start')
                                {
                                    bracketType = bracketType & ' start';
                                    libmei.AddAttribute(line, 'startsym', 'angleup');
                                }

                                if (linecomps[4] = 'end')
                                {
                                    bracketType = bracketType & ' end';
                                    libmei.AddAttribute(line, 'endsym', 'angleup');
                                }
                            }
                            else
                            {
                              libmei.AddAttribute(line, 'startsym', 'angleup');
                              libmei.AddAttribute(line, 'endsym', 'angleup');
                            }
                        }
                        //brackets below
                        if (linecomps[3] = 'below')
                        {
                            libmei.AddAttribute(line, 'place', 'below');

                            if (linecomps.Length > 4)
                            {
                                if (linecomps[4] = 'start')
                                {
                                    bracketType = bracketType & ' start';
                                    libmei.AddAttribute(line, 'startsym', 'angledown');
                                }

                                if (linecomps[4] = 'end')
                                {
                                    bracketType = bracketType & ' end';
                                    libmei.AddAttribute(line, 'endsym', 'angledown');
                                }
                            }
                            else
                            {
                                libmei.AddAttribute(line, 'startsym', 'angledown');
                                libmei.AddAttribute(line, 'endsym', 'angledown');
                            }
                        }
                        //vertical bracktes
                        if (linecomps[3] = 'vertical')
                        {
                            bracketType = bracketType & ' vertical';

                            //Add direction of bracket: line.staff.bracket.vertical.2 opens to the right, line.staff.bracket.vertical opens to the left
                            if (linecomps > 4)
                            {
                                if (linecomps[4] = '2')
                                {
                                    bracketType = bracketType & ' start';
                                    libmei.AddAttribute(line, 'startsym', 'angleright');
                                    libmei.AddAttribute(line, 'endsym', 'angleright');
                                }
                            }

                            else
                            {
                                bracketType = bracketType & ' end';
                                libmei.AddAttribute(line, 'startsym', 'angleleft');
                                libmei.AddAttribute(line, 'endsym', 'angleleft');
                            }
                        }
                    }

                    //add types of bracktes
                    libmei.AddAttribute(line, 'type', bracketType);
                }
                //solid vertical line
                case ('vertical')
                {
                    line = libmei.Line();
                    libmei.AddAttribute(line,'form','solid');
                    libmei.AddAttribute(line,'type','vertical');
                }
                //dashed lines
                case ('dashed')
                {
                    //dashed vertical line
                    if (linecomps.Length > 3)
                    {
                        if (linecomps[3] = 'vertical')
                        {
                            line = libmei.Line();
                            libmei.AddAttribute(line,'form','dashed');
                            libmei.AddAttribute(line,'type','vertical');
                        }
                    }
                    //dashed horizontal line
                    else
                    {
                      line = libmei.Line();
                      libmei.AddAttribute(line,'form','dashed');
                    }
                }
                //dotted horizontal line
                case('dotted')
                {
                  line = libmei.Line();
                  libmei.AddAttribute(line,'form','dotted');
                }
                //solid horizontal line
                case('plain')
                {
                  line = libmei.Line();
                  libmei.AddAttribute(line,'form','solid');
                }
                case ('vibrato')
                {
                    line = libmei.Line();
                    libmei.AddAttribute(line, 'type', 'vibrato');
                    libmei.AddAttribute(line, 'form', 'wavy');
                    libmei.AddAttribute(line, 'place', 'above');

                }

                //To catch diverse line types, set a default
                default
                {
                    line = libmei.Line();
                }
            }
        }
    }

    if (line = null)
    {
        return null;
    }

    line = AddBarObjectInfoToElement(bobj, line);

    return line;
}  //$end


function GenerateArpeggio (bobj) {
    //$module(ExportGenerators.mss)
    arpeg = libmei.Arpeg();
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
                // This means:  Line style is line.staff.arpeggio.up or
                // line.staff.arpeggio.down.
                // Strangely, the line style does not really matter for the
                // visual orientation of the arpeggio.  As long as RhDy and
                // and Dy properties are identical, arpeggios look the same,
                // independant of the two line styles with arrowheads.
                orientation = bobj.RhDy - bobj.Dy;
            }
        }
    }

    if (orientation = null)
    {
        libmei.AddAttribute(arpeg, 'arrow', 'false');
    }
    else
    {
        libmei.AddAttribute(arpeg, 'arrow', 'true');

        if (orientation > 0)
        {
            libmei.AddAttribute(arpeg, 'order', 'up');
        }
        else
        {
            libmei.AddAttribute(arpeg, 'order', 'down');
        }
    }

    arpeg = AddBarObjectInfoToElement(bobj, arpeg);

    return arpeg;
}  //$end


function GenerateTrill (bobj) {
    //$module(ExportGenerators.mss)
    /* There are two types of trills in Sibelius: A line object and a
        symbol object. This method normalizes both of these.
    */
    trill = libmei.Trill();
    bar = bobj.ParentBar;
    obj = GetNoteObjectAtPosition(bobj);

    if (obj != null)
    {
        libmei.AddAttribute(trill, 'startid', '#' & obj._id);
    }

    trill = AddBarObjectInfoToElement(bobj, trill);

    return trill;
}  //$end


function GenerateFermata (bobj) {
    //$module(ExportGenerators.mss)
    /* Note rests can have multiple fermatas in Sibelius,
        but this is currently not supported.
        Also, fermatas added as symbols are not yet handled.
    */
    shape = null;

    switch (bobj.Type)
    {
        case('NoteRest')
        {
            if (bobj.GetArticulation(PauseArtic))
            {
                shape = 'curved';
            }
            if (bobj.GetArticulation(TriPauseArtic))
            {
                shape = 'angular';
            }
            if (bobj.GetArticulation(SquarePauseArtic))
            {
                shape = 'square';
            }
        }
        case('BarRest')
        {
            switch (bobj.PauseType)
            {
                case(PauseTypeRound)
                {
                    shape = 'curved';
                }
                case(PauseTypeTriangular)
                {
                    shape = 'angular';
                }
                case(PauseTypeSquare)
                {
                    shape = 'square';
                }
            }
        }
    }

    if (shape = null)
    {
        return null;
    }

    fermata = libmei.Fermata();

    libmei.AddAttribute(fermata, 'form', 'norm');
    libmei.AddAttribute(fermata, 'shape', shape);

    fermata = AddBarObjectInfoToElement(bobj, fermata);

    return fermata;
}  //$end

function GenerateChordSymbol (bobj) {
    //$module(ExportGenerators.mss)
    /*
        Generates a <harm> element containing chord symbol information
    */
    harm = libmei.Harm();

    libmei.AddAttribute(harm, 'staff', bobj.ParentBar.ParentStaff.StaffNum);
    libmei.AddAttribute(harm, 'tstamp', ConvertPositionToTimestamp(bobj.Position, bobj.ParentBar));
    libmei.SetText(harm, bobj.ChordNameAsPlainText);

    return harm;
}  //$end

function GenerateFormattedString (bobj) {
    //$module(ExportGenerators.mss)
    /*
        Returns an array containing at least one paragraph
        tag, formatted with the <rend> element.

        Multiple paragraph tags may be returned if the formatting string contains
        a '\n\' (new paragraph)
    */

    FORMATOPEN = 1;
    FORMATCLOSE = 2;
    FORMATTAG = 3;
    FORMATINFO = 4;
    TEXTSTR = 5;

    // initialize context as a text string, since we may not always open with a formatting tag.
    ctx = TEXTSTR;
    tag = null;
    activeinfo = '';
    activetext = '';

    ret = CreateSparseArray();
    activeDiv = libmei.Div();
    activePara = libmei.P();
    libmei.AddChild(activeDiv, activePara);
    ret.Push(activeDiv);

    text = bobj.TextWithFormattingAsString;

    if (text = '')
    {
        return ret;
    }

    for i = 0 to Length(text)
    {
        c = CharAt(text, i);

        if (c = '\\')
        {
            if (ctx = FORMATINFO or ctx = FORMATTAG)
            {
                /*
                    If we have an open format context or
                    we are looking at format info and see
                    a slash, we are closing the format context
                */
                ctx = FORMATCLOSE;
            }
            else
            {
                if (ctx = TEXTSTR or ctx = FORMATCLOSE)
                {
                    /* If we have a slash we are either switching
                        into a new formatting tag context
                        or we are opening a new formatting tag
                        immediately after closing one.
                    */
                    ctx = FORMATOPEN;
                }
            }
        }
        else
        {
            switch (ctx)
            {
                case (FORMATOPEN)
                {
                    // the previous iteration gave us an opening
                    // formatting string, so the next character is
                    // the formatting tag
                    ctx = FORMATTAG;
                }

                case (FORMATTAG)
                {
                    /*
                        After seeing a tag we will expect to find some
                        info. If there is no info, the next character will
                        be a \ and it will be caught above.
                    */
                    ctx = FORMATINFO;
                    activeinfo = activeinfo & c;
                }

                case (FORMATINFO)
                {
                    // keep appending the active info until
                    // we reach the end.
                    activeinfo = activeinfo & c;
                }

                case (FORMATCLOSE)
                {
                    // the previous context was a closing format tag,
                    // so the next character, if it is not another opening
                    // tag, is a text string. Assume it is a text string
                    // which will be corrected on the next go-round.
                    ctx = TEXTSTR;
                    activetext = activetext & c;
                }

                case (TEXTSTR)
                {
                    activetext = activetext & c;
                }
            }
        }

        // now that we have figured out what context we are in, we
        // can do something about it.
        switch (ctx)
        {
            case (FORMATTAG)
            {
                tag = c;

                if (tag = 'n')
                {
                    if (activetext != '')
                    {
                        libmei.SetText(activePara, activetext);
                        activetext = '';
                    }

                    activePara = libmei.P();
                    libmei.AddChild(activeDiv, activePara);
                }

                if (tag = 'N')
                {
                    if (activetext != '')
                    {
                        children = activePara.children;

                        if (children.Length > 0)
                        {
                            lastLbId = children[-1];
                            lastLb = libmei.getElementById(lastLbId);
                            libmei.SetTail(lastLb, activetext);
                        }
                        else
                        {
                            libmei.SetText(activePara, activetext);
                        }
                    }
                    activetext = '';

                    lb = libmei.Lb();
                    libmei.AddChild(activePara, lb);
                }
            }

            case (TEXTSTR)
            {
                ;
            }

            case (FORMATOPEN)
            {
                // if we have hit a new format opening tag and we have some previous text.
                // if (activetext != '')
                // {
                //     // we have some pending text that needs to be dealt with
                //     libmei.SetText(activePara, activetext);
                //     activetext = '';
                // }
                ;
            }

            case (FORMATCLOSE)
            {
                if (activeinfo != '')
                {
                    // tags that have info.
                    switch (tag)
                    {
                        case ('s')
                        {
                            // our info block should contain units.
                            // Log('Units: ' & activeinfo);
                            ;
                        }

                        case ('c')
                        {
                            // our info block should contain a style
                            // Log('Style: ' & activeinfo);
                            ;
                        }

                        case ('f')
                        {
                            // our info block should either contain
                            // a font name or an underscore to switch
                            // back to the default font.
                            // Log('Font: ' & activeinfo);
                            ;
                        }

                        case ('$')
                        {
                            // our info block should contain a substitution
                            // Log('Substitution: ' & activeinfo);
                            ;
                        }
                    }

                    activeinfo = '';
                    tag = '';
                }
            }
            default
            {
                // Log('default: ' & ctx);
                ;
            }
        }
    }

    //
    if (ctx = TEXTSTR and activetext != '')
    {
        // if we end the text on a text string, append it to the active paragraph element.
        children = activePara.children;
        if (children.Length > 0)
        {
            lastLbId = children[-1];
            lastLb = libmei.getElementById(lastLbId);
            libmei.SetTail(lastLb, activetext);
        }
        else
        {
            libmei.SetText(activePara, activetext);
        }
    }

    return ret;
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
            symbolTable = libmei.SymbolTable();
            libmei.AddChild(Self._property:MainScoreDef, symbolTable);
            Self._property:SymbolTable = symbolTable;
        }
        symbolTable = Self._property:SymbolTable;

        symbolDef = libmei.SymbolDef();
        libmei.AddChild(symbolTable, symbolDef);
        anchoredText = libmei.AnchoredText();
        libmei.AddChild(symbolDef, anchoredText);
        symbol = libmei.Symbol();
        libmei.AddChild(anchoredText, symbol);
        libmei.AddAttribute(symbol, 'glyph.auth', 'smufl');
        libmei.AddAttribute(symbol, 'glyph.num', glyphnum);
        libmei.AddAttribute(symbol, 'glyph.name', glyphname);

        symbolIds[glyphnum] = symbolDef._id;
    }

    return '#' & symbolIds[glyphnum];
}  //$end

function GenerateMEIHeader () {
    //$module(ExportGenerators.mss)
    // takes in a Sibelius Score object
    // returns a libmei tree (i.e., nested objects and arrays) with a MEI header with metadata
    score = Self._property:ActiveScore;
    header = libmei.MeiHead();
    fileD = libmei.FileDesc();
    titleS = libmei.TitleStmt();
    libmei.AddChild(header, fileD);
    libmei.AddChild(fileD, titleS);
    
    workDesc = libmei.WorkDesc();
    wd_work = libmei.Work();
    wd_titleStmt = libmei.TitleStmt();
    wd_title = libmei.Title();
    wd_respStmt = libmei.RespStmt();
    libmei.AddChild(wd_titleStmt, wd_title);
    libmei.AddChild(wd_titleStmt, wd_respStmt);
    libmei.AddChild(wd_work, wd_titleStmt);
    libmei.AddChild(workDesc, wd_work);
    
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
        wd_composer = libmei.PersName();
        libmei.AddAttribute(wd_composer, 'role', 'composer');
        libmei.SetText(wd_composer, score.Composer);
        libmei.AddChild(wd_respStmt, wd_composer);
    }
    if (score.Lyricist != '')
    {
        lyricist = libmei.Lyricist();
        libmei.AddChild(titleS, lyricist);
        libmei.SetText(lyricist, score.Lyricist);
        wd_lyricist = libmei.PersName();
        libmei.AddAttribute(wd_lyricist, 'role', 'lyricist');
        libmei.SetText(wd_lyricist, score.Lyricist);
        libmei.AddChild(wd_respStmt, wd_lyricist);
    }
    if (score.Arranger != '')
    {
        arranger = libmei.Arranger();
        libmei.AddChild(titleS, arranger);
        libmei.SetText(arranger, score.Arranger);
        wd_arranger = libmei.PersName();
        libmei.AddAttribute(wd_arranger, 'role', 'arranger');
        libmei.SetText(wd_arranger, score.Arranger);
        libmei.AddChild(wd_respStmt, wd_arranger);
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

    encodingD = libmei.EncodingDesc();
    libmei.AddChild(header, encodingD);
    appI = libmei.AppInfo();
    libmei.AddChild(encodingD, appI);

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
    
    libmei.AddChild(header, workDesc);

    return header;
}  //$end

function GenerateMEIMusic () {
    //$module(ExportGenerators.mss)
    score = Self._property:ActiveScore;

    Self._property:TieResolver = CreateDictionary();
    Self._property:LyricWords = CreateDictionary();
    Self._property:SpecialBarlines = CreateDictionary();
    Self._property:SystemText = CreateDictionary();
    Self._property:LayerObjectPositions = null;
    Self._property:ObjectPositions = CreateDictionary();
    
    // the section parent is used in case we need to inject
    // a new parent later (e.g., for endings)
    Self._property:SectionParent = null;
    Self._property:VoltaBars = CreateDictionary();
    Self._property:ActiveVolta = null;
    Self._property:VoltaElement = null;

    //Track SystemSymbolItems
    Self._property:SystemSymbolItems = CreateDictionary();

    // track page numbers
    Self._property:CurrentPageNumber = null;
    Self._property:PageBreak = null;
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
    mdiv = libmei.Mdiv();
    sco = libmei.Score();

    libmei.AddChild(music, body);
    libmei.AddChild(body, mdiv);
    libmei.AddChild(mdiv, sco);

    scd = sibmei2.GenerateScoreDef(score);
    libmei.AddChild(sco, scd);

    barmap = ConvertSibeliusStructure(score);
    numbars = barmap.GetPropertyNames();
    numbars = numbars.Length;
    Self._property:BarMap = barmap;

    //store current time signature to detect changes
    timesig = score.SystemStaff.CurrentTimeSignature(1);
    Self._property:TimeSignature = CreateSparseArray(timesig.Numerator, timesig.Denominator, timesig.Text);

    section = libmei.Section();
    libmei.AddChild(sco, section);

    for j = 1 to numbars + 1
    {
        // this value may get changed by the volta processor
        // to inject a new parent in the hierarchy.
        progressMsg = utils.Format(_ExportingBars, j, numbars);
        cont = Sibelius.UpdateProgressDialog(j, progressMsg);

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

        //add changes of time signature
        crntimesig = score.SystemStaff.CurrentTimeSignature(j);
        currentTimeSignature = CreateSparseArray(crntimesig.Numerator, crntimesig.Denominator, crntimesig.Text);

        if (currentTimeSignature != Self._property:TimeSignature)
        {
            newscd = GenerateUpdatedTimeSig(crntimesig,j);

            //update stored time signature
            Self._property:TimeSignature = currentTimeSignature;

            libmei.AddChild(section,newscd);
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

function GenerateMeasure (num) {
    //$module(ExportGenerators.mss)

    score = Self._property:ActiveScore;
    // measureties
    Self._property:MeasureTies = CreateSparseArray();
    Self._property:MeasureLines = CreateSparseArray();

    m = libmei.Measure();
    libmei.AddAttribute(m, 'n', num);

    barmap = Self._property:BarMap;
    staves = barmap[num];
    children = CreateSparseArray();

    // since so much metadata about the staff and other context
    // is available on the bar that should now be on the measure, go through the bars
    // and try to extract it.

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

        if (bar.ExternalBarNumberString != num)
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

    mlines = Self._property:MeasureLines;

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
            //has to insert if visible...
            if (Self._property:Hidden = False)
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
    }

    //Handle Symbols on system staff
    sysSymb = Self._property:SystemSymbolItems;

    if (sysSymb.PropertyExists(num))
    {
        symbs = sysSymb[num];

        for each symb in symbs
        {
            if (symb != null) 
            {
                libmei.AddChild(m,symb);
            }
        }
    }

    systemtext = Self._property:SystemText;

    if (systemtext.PropertyExists(num))
    {
        textobjs = systemtext[num];
        for each textobj in textobjs
        {
            text = ConvertText(textobj);

            if (text != null)
            {
                libmei.AddChild(m, text);
            }
        }
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
            if (voicenumber != 0)
            {
                l = libmei.Layer();
                layers.Push(l._id);

                if (barObjectPositions.PropertyExists(voicenumber) = False)
                {
                    barObjectPositions[voicenumber] = CreateDictionary();
                }

                layerdict[voicenumber] = l;
                libmei.AddAttribute(l, 'n', voicenumber);
            }
        }

        obj = null;
        chordsym = null;
        parent = null;
        beam = null;
        tuplet = null;

        switch (bobj.Type)
        {
            case('Clef')
            {
                clef = GenerateClef(bobj);
                libmei.AddChild(l, clef);
            }
            case('NoteRest')
            {
                note = GenerateNoteRest(bobj, l);

                if (note != null)
                {
                    // record the position of this element
                    objVoice = barObjectPositions[voicenumber];
                    objVoice[bobj.Position] = note._id;

                    // fetch or create the active beam object (if any)
                    beam = ProcessBeam(bobj, note, l);

                    // fetch or create the active tuplet object (if any)
                    tuplet = ProcessTuplet(bobj, note, l);

                    if (beam != null)
                    {
                        // libmei.AddChild(beam, note);

                        if (tuplet != null)
                        {
                            if (beam._parent = l._id)
                            {
                                /* 
                                   If the beam has been previously added to the layer but now
                                   finds itself part of a tuplet, shift the tuplet to a tupletSpan. This
                                   effectively just replaces the active tuplet with a tupletSpan element
                                */
                                if (tuplet.name != 'tupletSpan')
                                {
                                    ShiftTupletToTupletSpan(tuplet, l);
                                    tsid = l._property:ActiveTupletId;
                                    tsobj = libmei.getElementById(tsid);

                                    if (tsobj._parent = null and tsobj._property:AddedToMeasure = False)
                                    {
                                        /*
                                            The measure lines get added to the measure object
                                            so pretend this tuplet span object is a line
                                            and queue it for addition to the measure.
                                        */
                                        tsobj._property:AddedToMeasure = True;
                                        line = tsobj;
                                    }

                                }
                            }
                            else
                            {
                                if (beam._parent != tuplet._id)
                                {
                                    libmei.AddChild(tuplet, beam);
                                }

                                if (tuplet._parent != l._id)
                                {
                                    libmei.AddChild(l, tuplet);
                                }
                            }
                        }
                        else
                        {
                            if (beam._parent != l._id)
                            {
                                libmei.AddChild(l, beam);
                            }
                        }
                    }
                    else
                    {
                        if (tuplet != null)
                        {
                            tname = libmei.GetName(tuplet);

                            if (tname != 'tupletSpan')
                            {
                                libmei.AddChild(tuplet, note);
                            }
                            else
                            {
                                libmei.AddChild(l, note);
                            }

                            if (tuplet._parent != l._id)
                            {
                                libmei.AddChild(l, tuplet);
                            }
                        }
                        else
                        {
                            libmei.AddChild(l, note);
                        }
                    }
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
        switch (bobj.Type)
        {
            case('GuitarFrame')
            {
                chordsym = GenerateChordSymbol(bobj);
            }
            case('Slur')
            {
                GenerateLine(bobj);
            }
            case('CrescendoLine')
            {
                GenerateLine(bobj);
            }
            case('DimuendoLine')
            {
                GenerateLine(bobj);
            }
            case('OctavaLine')
            {
                GenerateLine(bobj);
            }
            case('Trill')
            {
                GenerateLine(bobj);
            }
            case('RepeatTimeLine')
            {
                RegisterVolta(bobj);
            }
            case('Line')
            {
                GenerateLine(bobj);
            }
        }
    }

    for each Text tobj in bar
    {
        text = ConvertText(tobj);

        if (text != null)
        {
            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(tobj);

            if (obj != null)
            {
                libmei.AddAttribute(text, 'startid', '#' & obj._id);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(text._id);
        }

        // add chord symbols to the measure lines
        // so that they get added to the measure later in the processing cycle.
        if (chordsym != null)
        {
            mlines = Self._property:MeasureLines;
            mlines.Push(chordsym._id);
            Self._property:MeasureLines = mlines;
        }
    }

    for each LyricItem lobj in bar
    {
        ProcessLyric(lobj, objectPositions);
    }

    for each SymbolItem sobj in bar
    {
        ProcessSymbol(sobj);
    }

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
        switch (bobj.Stemweight)
        {
            case (StemweightUp)
            {
                libmei.AddAttribute(nr, 'stem.dir', 'up');
            }
            case (StemweightDown)
            {
                libmei.AddAttribute(nr, 'stem.dir', 'down');
            }
            case (StemweightFlipUp)
            {
                libmei.AddAttribute(nr, 'stem.dir', 'up');
            }
            case (StemweightFlipDown)
            {
                libmei.AddAttribute(nr, 'stem.dir', 'down');
            }
            default
            {
                // Handle other values.
                // If the stemweight is less than zero, the stem will point up, otherwise it will point down.
                if (bobj.Stemweight < 0)
                {
                    libmei.AddAttribute(nr, 'stem.dir', 'up');
                }

                // it seems that 0-weight stems are assumed to be down
                if (bobj.Stemweight >= 0)
                {
                    libmei.AddAttribute(nr, 'stem.dir', 'down');
                }
            }
        }
    }

    if (bobj.Dx != 0)
    {
        libmei.AddAttribute(nr, 'ho', ConvertOffsetsToMillimeters(bobj.Dx));
    }

    if (bobj.CueSize = true and libmei.GetName(nr) != 'space')
    {
        libmei.AddAttribute(nr, 'size', 'cue');
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
        libmei.AddAttribute(nr, 'grace', 'unacc');
    }

    if (bobj.IsAcciaccatura = True)
    {
        libmei.AddAttribute(nr, 'grace', 'acc');
    }

    if (bobj.GetArticulation(PauseArtic))
    {
        fermata = libmei.Fermata();
        libmei.AddAttribute(fermata, 'form', 'norm');
        libmei.AddAttribute(fermata, 'shape', 'curved');
        libmei.AddAttribute(fermata, 'startid', '#' & nr._id);
        libmei.AddAttribute(fermata, 'layer', bobj.VoiceNumber);
        libmei.AddAttribute(fermata, 'staff', bobj.ParentBar.ParentStaff.StaffNum);

        mlines = Self._property:MeasureLines;
        mlines.Push(fermata._id);
    }

    if (bobj.GetArticulation(TriPauseArtic))
    {
        fermata = libmei.Fermata();
        libmei.AddAttribute(fermata, 'form', 'norm');
        libmei.AddAttribute(fermata, 'shape', 'angular');
        libmei.AddAttribute(fermata, 'startid', '#' & nr._id);
        libmei.AddAttribute(fermata, 'layer', bobj.VoiceNumber);
        libmei.AddAttribute(fermata, 'staff', bobj.ParentBar.ParentStaff.StaffNum);

        mlines = Self._property:MeasureLines;
        mlines.Push(fermata._id);
    }

    if (bobj.GetArticulation(SquarePauseArtic))
    {
        fermata = libmei.Fermata();
        libmei.AddAttribute(fermata, 'form', 'norm');
        libmei.AddAttribute(fermata, 'shape', 'square');
        libmei.AddAttribute(fermata, 'startid', '#' & nr._id);
        libmei.AddAttribute(fermata, 'layer', bobj.VoiceNumber);
        libmei.AddAttribute(fermata, 'staff', bobj.ParentBar.ParentStaff.StaffNum);

        mlines = Self._property:MeasureLines;
        mlines.Push(fermata._id);
    }

    if (bobj.GetArticulation(StaccatoArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'stacc');
    }

    if (bobj.GetArticulation(DownBowArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'dnbow');
    }

    if (bobj.GetArticulation(UpBowArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'upbow');
    }

    if (bobj.GetArticulation(MarcatoArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'marc');
    }

    if (bobj.GetArticulation(AccentArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'acc');
    }

    if (bobj.GetArticulation(TenutoArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'ten');
    }

    if (bobj.GetArticulation(StaccatissimoArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'stacciss');
    }

    if (bobj.GetArticulation(StaccatissimoArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'stacciss');
    }

    if (bobj.GetArticulation(PlusArtic))
    {
        libmei.AddAttributeValue(nr, 'artic', 'stop');
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

    // a tremolo is a parent of note or chord in MEI
    if ((bobj.SingleTremolos > 0) or (bobj.SingleTremolos = -1))
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
    libmei.AddAttribute(r, 'dur.ges', dur & 'p');
    libmei.AddAttribute(r, 'dots', meidur[1]);
    
    if (bobj.Dx != 0 and name != 'space')
    {
        libmei.AddAttribute(r, 'ho', ConvertOffsetsToMillimeters(bobj.Dx));
    }

    if (bobj.Dy != 0 and name != 'space')
    {
        libmei.AddAttribute(r, 'vo', ConvertOffsetsToMillimeters(bobj.Dy));
    }

    if (bobj.CueSize = true and name != 'space')
    {
        libmei.AddAttribute(r, 'size', 'cue');
    }

    if (bobj.Hidden = true and name != 'space')
    {
        libmei.AddAttribute(r, 'visible', 'false');
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

    libmei.AddAttribute(n, 'pnum', pnum);
    libmei.AddAttribute(n, 'pname', ntinfo[0]);
    libmei.AddAttribute(n, 'oct', ntinfo[1]);
    libmei.AddAttribute(n, 'dur', meidur[0]);
    libmei.AddAttribute(n, 'dur.ges', dur & 'p');
    libmei.AddAttribute(n, 'dots', meidur[1]);

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
    libmei.AddAttribute(n, 'dur.ges', dur & 'p');
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
            warnings = Self._property:warnings;
            warnings.Push(utils.Format(_ObjectHasNoMEISupport, 'A four-bar repeat'));
            return null;
        }
    }

    if (bobj.Hidden = true)
    {
        libmei.AddAttribute(obj, 'visible', 'false');
    }

    return obj;
}  //$end

function GenerateScoreDef (score) {
    //$module(ExportGenerators.mss)
    scoredef = libmei.ScoreDef();
    Self._property:_GlobalScoreDef = libmei.GetId(scoredef);

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

    libmei.AddAttribute(scoredef, 'page.width', docSettings.PageWidth & unit);
    libmei.AddAttribute(scoredef, 'page.height', docSettings.PageHeight & unit);
    libmei.AddAttribute(scoredef, 'page.leftmar', docSettings.PageLeftMargin & unit);
    libmei.AddAttribute(scoredef, 'page.rightmar', docSettings.PageRightMargin & unit);
    libmei.AddAttribute(scoredef, 'page.topmar', docSettings.PageTopMargin & unit);
    libmei.AddAttribute(scoredef, 'page.botmar', docSettings.PageBottomMargin & unit);

    showCautionaryAccidentals = score.EngravingRules.CautionaryNaturalsInKeySignatures;
    if (showCautionaryAccidentals = true)
    {
        libmei.AddAttribute(scoredef, 'key.sig.showchange', 'true');
    }

    libmei.AddAttribute(scoredef, 'music.name', score.MainMusicFontName);
    libmei.AddAttribute(scoredef, 'text.name', score.MainTextFontName);
    libmei.AddAttribute(scoredef, 'lyric.name', score.MusicTextFontName);

    systf = score.SystemStaff;
    timesig = systf.CurrentTimeSignature(1);

    libmei.AddAttribute(scoredef, 'meter.count', timesig.Numerator);
    libmei.AddAttribute(scoredef, 'meter.unit', timesig.Denominator);
    libmei.AddAttribute(scoredef, 'meter.sym', ConvertNamedTimeSignature(timesig.Text));
    libmei.AddAttribute(scoredef, 'ppq', '256'); // sibelius' internal ppq.

    staffgrp = GenerateStaffGroups(score);
    libmei.AddChild(scoredef, staffgrp);

    return scoredef;
}  //$end

function GenerateStaffGroups (score) {
    //$module(ExportGenerators.mss)
    staffdict = CreateDictionary();
    parentstgrp = libmei.StaffGrp();
    numstaff = score.StaffCount;

    for each Staff s in score
    {
        std = libmei.StaffDef();
        libmei.XMLIdToObjectMap[std._id] = s;

        libmei.AddAttribute(std, 'n', s.StaffNum);
        libmei.AddAttribute(std, 'label', s.FullInstrumentName);
        libmei.AddAttribute(std, 'lines', s.InitialInstrumentType.NumStaveLines);
        
        clefinfo = ConvertClef(s.InitialClefStyleId);
        libmei.AddAttribute(std, 'clef.shape', clefinfo[0]);
        libmei.AddAttribute(std, 'clef.line', clefinfo[1]);
        libmei.AddAttribute(std, 'clef.dis', clefinfo[2]);
        libmei.AddAttribute(std, 'clef.dis.place', clefinfo[3]);
        libmei.AddAttribute(std, 'key.sig', ConvertKeySignature(s.InitialKeySignature.Sharps));

        if (s.InitialKeySignature.Major)
        {
            libmei.AddAttribute(std, 'key.mode', 'major');
        }
        else
        {
            libmei.AddAttribute(std, 'key.mode', 'minor');
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
        case ('DimuendoLine')
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
                case ('bracket')
                {
                    line = libmei.Line();
                    libmei.AddAttribute(line, 'type', 'bracket');

                    if (linecomps.Length > 4)
                    {
                        if (linecomps[4] = 'start')
                        {
                            libmei.AddAttribute(line, 'subtype', 'start');
                        }

                        if (linecomps[4] = 'end')
                        {
                            libmei.AddAttribute(line, 'subtype', 'end');
                        }
                    }

                    if (linecomps.Length > 3)
                    {
                        if (linecomps[3] = 'vertical')
                        {
                            libmei.AddAttribute(line, 'subtype', 'vertical');

                            //Add direction of bracket
                            if (linecomps > 4) 
                            {   
                                if (linecomps[4] = '2') 
                                {
                                    libmei.AddAttribute(line, 'label', 'start');
                                }
                            }

                            else
                            {
                                libmei.AddAttribute(line, 'label', 'end');
                            }
                        }
                    }
                }

                //dashed solid line
                case ('vertical')
                {
                    line = libmei.Line();
                    libmei.AddAttribute(line,'form','solid');
                    libmei.AddAttribute(line,'type','vertical');
                }

                //dashed vertical line
                case ('dashed')
                {
                    if (linecomps.Length > 3)
                    {
                        if (linecomps[3] = 'vertical')
                        {
                            line = libmei.Line();
                            libmei.AddAttribute(line,'form','dashed');
                            libmei.AddAttribute(line,'type','vertical');
                        }
                    }
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

    //if (line = null)
    //{
    //    return null;
    //}

    if (line != null)
        {
            //store graphic offset
            if (bobj.RhDx != 0)
            {
                libmei.AddAttribute(line, 'ho', ConvertOffsetsToMillimeters(bobj.RhDx));
            }

            if (bobj.RhDy != 0)
            {
                libmei.AddAttribute(line, 'vo', ConvertOffsetsToMillimeters(bobj.RhDy));
            }

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(bobj);

            if (obj != null)
            {
                libmei.AddAttribute(line, 'startid', '#' & obj._id);

                end_obj = GetNoteObjectAtEndPosition(bobj);

                if (end_obj != null) 
                {
                    libmei.AddAttribute(line, 'endid', '#' & end_obj._id);
                }
                else
                {
                    dur = bobj.Duration;

                    if (dur > 0)
                    {
                        meidur = ConvertDuration(dur);
                        libmei.AddAttribute(line, 'dur', meidur[0]);
                        libmei.AddAttribute(line, 'dur.ges', dur & 'p');
                    }
                    else
                    {
                        libmei.AddAttribute(line, 'endid', '#' & obj._id);
                    }
                    
                }
            }
            else
            {
                line = AddBarObjectInfoToElement(bobj, line);
            }

    
            mlines = Self._property:MeasureLines;
            mlines.Push(line._id);
            Self._property:MeasureLines = mlines;
        }

    //return line;
}  //$end


function GenerateTrill (bobj) {
    //$module(ExportGenerators.mss)
    /* There are two types of trills in Sibelius: A line object and a 
        symbol object. This method normalizes both of these.
    */
    trill = libmei.Trill();
    voicenum = bobj.VoiceNumber;
    bar = bobj.ParentBar;

    if (voicenum = 0)
    {
        warnings = Self._property:warnings;
        warnings.Push(utils.Format(_ObjectAssignedToAllVoicesWarning, bar.BarNumber, voicenum, bobj.Type));
        voicenum = 1;
    }

    obj = GetNoteObjectAtPosition(bobj);

    if (obj != null)
    {
        libmei.AddAttribute(trill, 'startid', '#' & obj._id);
    }

    trill = AddBarObjectInfoToElement(bobj, trill);

    return trill;
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

function GenerateUpdatedTimeSig(timesig,beamnum) {
    //$module(ExportGenerators.mss)
    /*
        Generates a reduced scoreDef with updated time signature
    */
    newscd = libmei.ScoreDef();

    //put number of measure as @n to scoreDef for testing purposes
    libmei.AddAttribute(newscd, 'n', beamnum);

    libmei.AddAttribute(newscd, 'meter.count', timesig.Numerator);
    libmei.AddAttribute(newscd, 'meter.unit', timesig.Denominator);
    libmei.AddAttribute(newscd, 'meter.sym', ConvertNamedTimeSignature(timesig.Text));

    return newscd;
}  //$end
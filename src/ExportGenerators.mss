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

    plgname = libmei.Name();
    libmei.SetText(plgname, PluginName & ' (' & Version & ')');
    libmei.AddAttribute(plgname, 'type', 'plugin');
    libmei.AddChild(applic, plgname);

    osname = libmei.Name();
    libmei.SetText(osname, Sibelius.OSVersionString);
    libmei.AddAttribute(osname, 'type', 'operating-system');
    libmei.AddChild(applic, osname);
    
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

    // track page numbers
    Self._property:CurrentPageNumber = null;
    Self._property:PageBreak = null;

    // grab some global markers from the system staff
    // This will store it for later use.
    ProcessSystemStaff(score);

    music = libmei.Music();
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
            libmei.AddAttribute(pb, 'n', curr_pn);
            Self._property:PageBreak = pb;
        }

        if (bar.ExternalBarNumberString)
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
        bline = specialbarlines[num];

        if (bline = 'rptstart')
        {
            libmei.AddAttribute(m, 'left', bline);
        }
        else
        {
            libmei.AddAttribute(m, 'right', bline);
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
        line = null;
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

                // record the position of this element
                objVoice = barObjectPositions[voicenumber];
                objVoice[bobj.Position] = note._id;

                if (note._property:TieIds != null)
                {
                    ties = note._property:TieIds;
                    mties = Self._property:MeasureTies;
                    mties = mties.Concat(ties);
                    Self._property:MeasureTies = mties;
                }

                beam = ProcessBeam(bobj, l);
                tuplet = ProcessTuplet(bobj, note, l);

                if (beam != null)
                {
                    libmei.AddChild(beam, note);

                    if (tuplet != null)
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
                        libmei.AddChild(tuplet, note);

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
            case('BarRest')
            {
                brest = GenerateBarRest(bobj);

                if (brest != null)
                {
                    libmei.AddChild(l, brest);
                }
            }
            case('Slur')
            {
                line = GenerateLine(bobj);
            }
            case('CrescendoLine')
            {
                line = GenerateLine(bobj);
            }
            case('DimuendoLine')
            {
                line = GenerateLine(bobj);
            }
            case('OctavaLine')
            {
                line = GenerateLine(bobj);
            }
            case('Trill')
            {
                line = GenerateLine(bobj);
            }
            case('RepeatTimeLine')
            {
                RegisterVolta(bobj);
            }
            case('Line')
            {
                line = GenerateLine(bobj);
            }
        }

        if (line != null)
        {
            mlines = Self._property:MeasureLines;
            mlines.Push(line._id);
            Self._property:MeasureLines = mlines;
        }
    }

    for each LyricItem lobj in bar
    {
        ProcessLyric(lobj, objectPositions);
    }

    for each SymbolItem sobj in bar
    {
        ProcessSymbol(sobj, objectPositions);
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

    return clef_el;
}  //$end

function GenerateNoteRest (bobj, layer) {
    //$module(ExportGenerators.mss)
    nr = null;

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

    if (bobj.Dx != 0)
    {
        libmei.AddAttribute(nr, 'ho', ConvertOffsets(bobj.Dx));
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

    if (bobj.GraceNote = true)
    {
        libmei.addAttribute(nr, 'grace', 'acc');
    }

    if (bobj.IsAppoggiatura = true)
    {
        libmei.AddAttribute(nr, 'ornam', 'A');
    }

    if (bobj.IsAcciaccatura = true)
    {
        libmei.AddAttribute(nr, 'ornam', 'a');
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
        libmei.addAttributeValue(nr, 'artic', 'acc');
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

    libmei.AddAttribute(r, 'dur', meidur[0]);
    libmei.AddAttribute(r, 'dur.ges', dur & 'p');
    libmei.AddAttribute(r, 'dots', meidur[1]);
    
    if (bobj.Dx != 0)
    {
        libmei.AddAttribute(r, 'ho', ConvertOffsets(bobj.Dx));
    }

    if (bobj.Dy != 0)
    {
        libmei.AddAttribute(r, 'vo', ConvertOffsets(bobj.Dy));
    }

    if (bobj.CueSize = true and libmei.GetName(r) != 'space')
    {
        libmei.AddAttribute(r, 'size', 'cue');
    }

    if (bobj.Hidden = true and libmei.GetName(r) != 'space')
    {
        libmei.AddAttribute(r, 'visible', 'false');
    }

    if (bobj.Color != 0)
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
    ntinfo = ConvertDiatonicPitch(nobj.DiatonicPitch);
    pos = nobj.ParentNoteRest.Position;
    keysig = nobj.ParentNoteRest.ParentBar.GetKeySignatureAt(pos);

    n = libmei.Note();
    hash = SimpleNoteHash(nobj);
    n._property:hash = hash;

    libmei.AddAttribute(n, 'pnum', nobj.Pitch);
    libmei.AddAttribute(n, 'pname', ntinfo[0]);
    libmei.AddAttribute(n, 'oct', ntinfo[1]);
    libmei.AddAttribute(n, 'dur', meidur[0]);
    libmei.AddAttribute(n, 'dur.ges', dur & 'p');
    libmei.AddAttribute(n, 'dots', meidur[1]);

    // Accidentals will always be encoded as child elements, not attributes
    staff = nobj.ParentNoteRest.ParentBar.ParentStaff.StaffNum;

    if (nobj.NoteStyle != NormalNoteStyle)
    {
        nstyle = ConvertNoteStyle(nobj.NoteStyle);
        libmei.AddAttribute(n, 'headshape', nstyle);
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

    /*
        Ties
    */
    tieresolver = Self._property:TieResolver;
    if (tieresolver.PropertyExists(hash))
    {
        // this note is the end of the tie.
        tie_id = tieresolver[hash];
        tie = libmei.getElementById(tie_id);
        libmei.AddAttribute(tie, 'endid', '#' & n._id);
    }

    if (nobj.Tied = True)
    {
        // set the end hash
        parent_nr = nobj.ParentNoteRest;
        next_object = parent_nr.NextItem(parent_nr.VoiceNumber, 'NoteRest');

        if (next_object = null)
        {
            // check the first object in the next bar
            next_bar_num = parent_nr.ParentBar.BarNumber + 1;
            next_bar = parent_nr.ParentBar.ParentStaff.NthBar(next_bar_num);
            next_object = next_bar.NthBarObject(0);
        }

        if (next_object = null or next_object.Type != 'NoteRest')
        {
            // it's a hanging tie. What to do, what to do?
            // for now, just encode the startid with no endid and return the note.
            tie = libmei.Tie();
            libmei.AddAttribute(tie, 'startid', '#' & n._id);
            n._property:TieIds = CreateSparseArray(tie._id);
            return n;
        }

        for each next_note in next_object
        {
            if (nobj.Pitch = next_note.Pitch)
            {
                // it's probably this one.
                endhash = SimpleNoteHash(next_note);
                tie = libmei.Tie();
                libmei.AddAttribute(tie, 'startid', '#' & n._id);
                tieresolver[endhash] = tie._id;

                n._property:TieIds = CreateSparseArray(tie._id);
            }
        }
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
    
    tiearr = CreateSparseArray();

    for each note in bobj
    {
        sn = GenerateNote(note);
        libmei.AddChild(n, sn);

        if (sn._property:TieIds != null)
        {
            tieids = sn._property:TieIds;
            tiearr = tiearr.Concat(tieids);
        }
    }

    n._property:TieIds = tiearr;

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
            libmei.AddAttribute(line, 'rend', slurrend[1]);
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
            libmei.AddAttribute(octl, 'dis', octrend[0]);
            libmei.AddAttribute(octl, 'dis.place', octrend[1]);
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
                case('bracket')
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
        warnings.Push(utils.Format(_ObjectAssignedToAllVoicesWarning, bobj.Type));
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
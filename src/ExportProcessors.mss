function ProcessScore () {
    //$module(ExportProcessors.mss)
    // processors are a bit like a workflow manager -- they orchestrate the
    // generators, which in turn use the converters to convert specific values from sibelius
    // to MEI.
    score = Self._property:ActiveScore;

    mei = libmei.Mei();
    libmei.setDocumentRoot(mei);

    libmei.AddAttribute(mei, 'xmlns:xlink', 'http://www.w3.org/1999/xlink');
    libmei.AddAttribute(mei, 'xmlns', 'http://www.music-encoding.org/ns/mei');
    libmei.AddAttribute(mei, 'meiversion', '3.0.0');

    header = GenerateMEIHeader();
    libmei.AddChild(mei, header);

    music = GenerateMEIMusic();
    libmei.AddChild(mei, music);

}  //$end

function ProcessBeam (bobj, layer, normalizedBeamProp) {
    //$module(ExportProcessors.mss)
    /*
        Returns the active beam, if any, and creates new beam elements
        at the start of a beam.
    */
    switch (normalizedBeamProp)
    {
        case (NoBeam)
        {
            if (bobj.GraceNote)
            {
                if (layer._property:ActiveGraceBeam != null)
                {
                    layer._property:ActiveGraceBeam = null;
                }
                // If there is an active non-grace beam, we have a normal beam spanning
                // over a non-beamed grace note that will be added as a child of that beam.
                return GetNongraceParentBeam(bobj, layer);
            }
            else
            {
                if (layer._property:ActiveBeam != null)
                {
                    layer._property:ActiveBeam = null;
                }
                return null;
            }
        }
        case (StartBeam)
        {
            newBeam = libmei.Beam();
            if (bobj.GraceNote)
            {
                layer._property:ActiveGraceBeam = newBeam;
                nonGraceParentBeam = GetNongraceParentBeam(bobj, layer);
                if (nonGraceParentBeam != null)
                {
                    newBeam._property:ParentBeam = nonGraceParentBeam;
                }
            }
            else
            {
                layer._property:ActiveBeam = newBeam;
            }
            return newBeam;
        }
        default {
            // ContinueBeam and SingleBeam
            if (bobj.GraceNote)
            {
                return layer._property:ActiveGraceBeam;
            }
            else
            {
                return layer._property:ActiveBeam;
            }
        }
    }
}  //$end

function ProcessTuplet (noteRest, meielement, layer) {
    //$module(ExportProcessors.mss)
    if (noteRest.ParentTupletIfAny = null)
    {
        return null;
    }

    /*
       We encode inner tuplets of nested tuplet structures as <tupletSpan>s.
       Therefore we always return the outermost MEI tuplet for content to be added.
       Still, we need to keep track of the inner tuplets to assign the @endid.
       layer._property:ActiveMeiTuplet always points to the innermost tuplet.
    */
    activeMeiTuplet = layer._property:ActiveMeiTuplet;

    tupletIsContinued = activeMeiTuplet != null and TupletsEqual(noteRest.ParentTupletIfAny, activeMeiTuplet._property:SibTuplet);

    if (not(tupletIsContinued))
    {
        // New tuplets need to be added
        noteRestTupletStack = GetTupletStack(noteRest);
        sibTuplet = null;
        meiTupletDepth = GetMeiTupletDepth(layer);

        for i = meiTupletDepth to noteRestTupletStack.Length
        {
            sibTuplet = noteRestTupletStack[i];
            nextActiveMeiTuplet = GenerateTuplet(sibTuplet);
            if (meiTupletDepth > 0 or i > meiTupletDepth)
            {
                // We have an inner tuplet that we encode as <tupletSpan>
                nextActiveMeiTuplet = ShiftTupletToTupletSpan(nextActiveMeiTuplet, layer);
            }
            libmei.AddAttribute(nextActiveMeiTuplet, 'startid', '#' & meielement._id);
            // We basically create a linked list of tuplets
            nextActiveMeiTuplet._property:ParentTuplet = activeMeiTuplet;
            nextActiveMeiTuplet._property:SibTuplet = sibTuplet;
            activeMeiTuplet = nextActiveMeiTuplet;
        }
        layer._property:ActiveMeiTuplet = activeMeiTuplet;
    }

    meiTuplet = activeMeiTuplet;
    for i = 0 to CountTupletsEndingAtNoteRest(noteRest)
    {
        libmei.AddAttribute(meiTuplet, 'endid', '#' & meielement._id);
        meiTuplet = meiTuplet._property:ParentTuplet;
    }
    layer._property:ActiveMeiTuplet = meiTuplet;

    outermostMeiTuplet = activeMeiTuplet;
    while (outermostMeiTuplet._property:ParentTuplet)
    {
        outermostMeiTuplet = outermostMeiTuplet._property:ParentTuplet;
    }
    return outermostMeiTuplet;
}  //$end

function ShiftTupletToTupletSpan (tuplet) {
    //$module(ExportProcessors.mss)
    /*
        Shifts the tuplet object to a tupletSpan object. This is
        useful if we need to define a tuplet outside of a hierarchy;
        for example, if a tuplet is only on part of a beam group.

        A tupletSpan supports many of the same attributes as a tuplet
        object, so we can copy the attributes verbatim. Functionally,
        it should behave the same way as a tuplet, except that it
        takes no child elements and the parent element is the measure,
        not the layer. These two things get handled higher up the
        processing chain, however, so we don't have to worry about them here.
    */

    tupletSpan = libmei.TupletSpan();
    libmei.SetAttributes(tupletSpan, tuplet.attrs);

    if (tuplet._parent != null)
    {
        // if the tuplet has already been added to the tree,
        // remove it now. (Unfortunately, we can't delete the object,
        // but disowning it from the tree should be enough to keep it from
        // appearing in the output.)
        pobj = libmei.getElementById(tuplet._parent);
        libmei.RemoveChild(pobj, tuplet);
        tuplet._parent = null;
    }

    mobjs = Self._property:MeasureObjects;
    mobjs.Push(tupletSpan._id);
    Self._property:MeasureObjects = mobjs;

    return tupletSpan;
}  //$end

function ProcessLyric (lyricobj, objectPositions) {
    //$module(ExportProcessors.mss)
    /*
        We need to track initial, medial, and terminal lyrics. Sibelius
        only allows us to know the medial and terminal, so we store all the
        syllables in an array until we reach the end of the word, and then
        attach them to the notes.
    */

    if (lyricobj.Text = '')
    {
        return null;
    }

    styleparts = MSplitString(lyricobj.StyleId, '.');
    verse_id = styleparts[5];
    verse_id_arr = MSplitString(verse_id, false);
    verse_num = verse_id_arr[5];
    bar_num = lyricobj.ParentBar.BarNumber;
    staff_num = lyricobj.ParentBar.ParentStaff.StaffNum;
    voicenum = lyricobj.VoiceNumber;

    if (voicenum = 0)
    {
        // assign it to the first voice, since we don't have any notes in voice 0.
        voicenum = 1;
        warnings = Self._property:warnings;
        warnings.Push(utils.Format(_ObjectAssignedToAllVoicesWarning, bar_num, voicenum, 'Lyric object'));
    }

    lyricwords = Self._property:LyricWords;

    if (lyricwords.PropertyExists(staff_num) = False)
    {
        lyricwords[staff_num] = CreateDictionary();
    }

    lyricstaff = lyricwords[staff_num];

    if (lyricstaff.PropertyExists(voicenum) = False)
    {
        lyricstaff[voicenum] = CreateDictionary();
    }

    lyricvoice = lyricstaff[voicenum];

    if (lyricvoice.PropertyExists(verse_num) = False)
    {
        lyricvoice[verse_num] = CreateSparseArray();
    }

    if (lyricobj.SyllableType = MiddleOfWord)
    {
        lyricvoice[verse_num].Push(lyricobj);
        // we haven't reached the end of the word yet, so just return
        // and keep going.
        return null;
    }

    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // anything past here is in the EndOfWord condition.
    // this should return a sparse array containing the syllables of the word.
    lyricvoice[verse_num].Push(lyricobj);
    lyric_word = lyricvoice[verse_num];
    objects = objectPositions[voicenum];

    obj_id = null;
    obj = null;

    for j = 0 to lyric_word.Length
    {
        syl = lyric_word[j];

        verse = libmei.Verse();
        libmei.AddAttribute(verse, 'n', verse_num);
        sylel = libmei.Syl();
        // In the case of elisions, we create multiple syl elements from one
        // LyricItem. We have to distinguish between the first and the last syl
        // element we created. In the common, simple case, both are identical.
        sylel_last = sylel;
        libmei.SetText(sylel, syl.Text);
        libmei.AddChild(verse, sylel);

        if (utils.Pos('_', syl.Text) > -1)
        {
            // Syllable elision. split this syllable element by underscore.
            syllables = MSplitString(syl.Text, '_');

            // reset the text of the first syllable element to the first half of the syllable.
            libmei.SetText(sylel, syllables[0]);
            libmei.AddAttribute(sylel, 'con', 'b');

            for s = 1 to syllables.Length
            {
                sylel_last = libmei.Syl();
                libmei.SetText(sylel_last, syllables[s]);
                libmei.AddChild(verse, sylel_last);
            }
        }

        if (j = 0)
        {
            //add a wordpos only for partial words
            if (lyric_word.Length > 1)
            {
                libmei.AddAttribute(sylel_last, 'wordpos', 'i'); // 'initial'

                libmei.AddAttribute(sylel_last, 'con', 'd'); //dash syllable connector
            }

            //it is also possible, that an initial syllable has an underscore as an extender, if it is the only syllable of a word
            if (lyric_word.Length = 1)
            {
                if (syl.NumNotes > 1)
                {
                    libmei.AddAttribute(sylel_last, 'con', 'u'); // 'underscore'
                }
            }
        }
        else
        {
            if (syl.SyllableType = EndOfWord)
            {
                libmei.AddAttribute(sylel, 'wordpos', 't'); // 'terminal'

                if (syl.NumNotes > 1)
                {
                    libmei.AddAttribute(sylel, 'con', 'u'); // 'underscore'
                }

            }
            else
            {
                libmei.AddAttribute(sylel, 'wordpos', 'm'); // medial
                libmei.AddAttribute(sylel, 'con', 'd');
            }
        }

        obj = GetNoteObjectAtPosition(syl);

        if (obj != null)
        {
            name = libmei.GetName(obj);

            if (name = 'rest')
            {
                warnings = Self._property:warnings;
                warnings.Push(utils.Format(_ObjectIsOnAnIllogicalObject, bar_num, voicenum, 'Lyric', 'rest'));
            }

            if (name = 'chord')
            {
                warnings = Self._property:warnings;
                warnings.Push(utils.Format(_ObjectIsOnAnIllogicalObject, bar_num, voicenum, 'Lyric', 'chord'));
            }

            libmei.AddChild(obj, verse);
        }
        else
        {
            Log('Could not find note object for syl ' & syl);
        }
    }

    // now reset the syllable array for this voice
    lyricvoice[verse_num] = CreateSparseArray();
}  //$end

function ProcessSystemStaff (score) {
    //$module(ExportProcessors.mss)
    systf = score.SystemStaff;

    for each bar in systf
    {
        for each bobj in bar
        {
            switch (bobj.Type)
            {
                case ('SpecialBarline')
                {
                    spclbarlines = Self._property:SpecialBarlines;
                    if (spclbarlines.PropertyExists(bar.BarNumber) = False)
                    {
                        spclbarlines[bar.BarNumber] = CreateSparseArray();
                    }

                    spclbarlines[bar.BarNumber].Push(ConvertBarline(bobj.BarlineInternalType));
                }
                case ('SystemTextItem')
                {
                    if (bobj.OnNthBlankPage < 0)
                    {
                        ProcessFrontMatter(bobj);
                    }

                    systemtext = Self._property:SystemText;

                    if (systemtext.PropertyExists(bar.BarNumber) = False)
                    {
                        systemtext[bar.BarNumber] = CreateSparseArray();
                    }

                    systemtext[bar.BarNumber].Push(bobj);
                }
                case ('Graphic')
                {
                    Log('Found a graphic!');
                    Log('is object? ' & IsObject(bobj));
                }
                case ('RepeatTimeLine')
                {
                    RegisterVolta(bobj);
                }
            }
        }
    }
}  //$end

function ProcessFrontMatter (bobj) {
    //$module(ExportProcessors.mss)
    /*
        For example, if page 2 (0-indexed) is the first page of music,
        then 'OnNthPage' will be 2, but the system staff items for
        the first page of text will be -2, so 2 + (-2) = 0 + 1;
    */
    bar = bobj.ParentBar;
    text = '';

    pnum = (bar.OnNthPage + bobj.OnNthBlankPage) + 1;
    frontmatter = Self._property:FrontMatter;

    if (frontmatter.PropertyExists(pnum) = False)
    {
        pb = libmei.Pb();
        libmei.AddAttribute(pb, 'n', pnum);
        frontmatter[pnum] = CreateSparseArray(pb);
    }
    pagematter = frontmatter[pnum];

    text = GenerateFormattedString(bobj);
    frontmatter[pnum] = pagematter.Concat(text);

}  //$end

function RegisterVolta (bobj) {
    //$module(ExportProcessors.mss)
    voltabars = Self._property:VoltaBars;
    style = MSplitString(bobj.StyleId, '.');

    if (style[2] = 'repeat')
    {
        voltabars[bobj.ParentBar.BarNumber] = bobj;
    }
}  //$end

function ProcessVolta (mnum) {
    //$module(ExportProcessors.mss)
    voltabars = Self._property:VoltaBars;

    if (voltabars.PropertyExists(mnum))
    {
        voltaElement = libmei.Ending();

        Self._property:VoltaElement = voltaElement;

        voltaObject = voltabars[mnum];
        voltainfo = ConvertEndingValues(voltaObject.StyleId);

        libmei.AddAttribute(voltaElement, 'n', voltainfo[0]);
        libmei.AddAttribute(voltaElement, 'label', voltainfo[1]);
        libmei.AddAttribute(voltaElement, 'type', voltainfo[2]);

        if (voltaObject.EndBarNumber != mnum)
        {
            Self._property:ActiveVolta = voltaObject;
        }

        return voltaElement;
    }
    else
    {
        if (Self._property:ActiveVolta != null)
        {
            // we have an unresolved volta, so
            // we'll keep the previous parentElement
            // active.
            activeVolta = Self._property:ActiveVolta;
            voltaElement = Self._property:VoltaElement;

            // if the end bar is the current bar OR if the end
            // bar is the next bar, but the end position is 0, we're escaping the
            // volta the next time around.
            if ((activeVolta.EndBarNumber = mnum) or
                (activeVolta.EndBarNumber = (mnum + 1) and activeVolta.EndPosition = 0))
            {
                Self._property:ActiveVolta = null;
                Self._property:VoltaElement = null;
            }
            return null;
        }
    }

    return null;
}  //$end

function ProcessTremolo (bobj) {
    //$module(ExportProcessors.mss)
    if (bobj.DoubleTremolos = 0)
    {
        return null;
    }

    Log('Fingered tremolo: ' & bobj.DoubleTremolos);
    tremEl = libmei.FTrem();
    libmei.AddAttribute(tremEl, 'slash', bobj.DoubleTremolos);
    libmei.AddAttribute(tremEl, 'measperf');

} //$end

function ProcessSymbol (sobj) {
    //$module(ExportProcessors.mss)
    Log('symbol index: ' & sobj.Index & ' name: ' & sobj.Name);
    Log(sobj.VoiceNumber);
    voicenum = sobj.VoiceNumber;
    bar = sobj.ParentBar;

    if (voicenum = 0)
    {
        // assign it to the first voice, since we don't have any notes in voice/layer 0.
        sobj.VoiceNumber = 1;
        warnings = Self._property:warnings;
        warnings.Push(utils.Format(_ObjectAssignedToAllVoicesWarning, bar.BarNumber, voicenum, 'Symbol'));
    }

    switch (sobj.Index)
    {
        case ('32')
        {
            // trill
            trill = GenerateTrill(sobj);
            mlines = Self._property:MeasureObjects;
            mlines.Push(trill._id);
        }

        case ('36')
        {
            // inverted mordent
            mordent = libmei.Mordent();
            libmei.AddAttribute(mordent, 'form', 'inv');
            mordent = AddBarObjectInfoToElement(sobj, mordent);
            mlines = Self._property:MeasureObjects;
            mlines.Push(mordent._id);
        }

        case ('37')
        {
            // mordent
            mordent = libmei.Mordent();
            libmei.AddAttribute(mordent, 'form', 'norm');
            mordent = AddBarObjectInfoToElement(sobj, mordent);
            mlines = Self._property:MeasureObjects;
            mlines.Push(mordent._id);
        }

        case ('38')
        {
            // turn
            turn = libmei.Turn();
            libmei.AddAttribute(turn, 'form', 'norm');
            turn = AddBarObjectInfoToElement(sobj, turn);
            mlines = Self._property:MeasureObjects;
            mlines.Push(turn._id);
        }

        case ('39')
        {
            // inverted turn
            turn = libmei.Turn();
            libmei.AddAttribute(turn, 'form', 'inv');
            turn = AddBarObjectInfoToElement(sobj, turn);
            mlines = Self._property:MeasureObjects;
            mlines.Push(turn._id);
        }
        case ('52')
        {
            nobj = GetNoteObjectAtPosition(sobj);

            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'heel');
                libmei.AddChild(nobj, artic);
            }
        }
        case ('53')
        {
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'heel');
                libmei.AddChild(nobj, artic);
            }

        }
        case ('54')
        {
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'toe');
                libmei.AddChild(nobj, artic);
            }

        }
        case ('55')
        {
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'toe');
                libmei.AddChild(nobj, artic);
            }

        }
        case ('160')
        {
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'stop');
                libmei.AddChild(nobj, artic);
            }
        }
        case ('162')
        {
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'open');
                libmei.AddChild(nobj, artic);
            }
        }
        case ('163')
        {
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'damp');
                libmei.AddChild(nobj, artic);
            }
        }
        case ('164')
        {
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'damp');
                libmei.AddChild(nobj, artic);
            }

        }
        case ('165')
        {
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'damp');
                libmei.AddChild(nobj, artic);
            }
        }
        case ('166')
        {
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'damp');
                libmei.AddChild(nobj, artic);
            }

        }
        case ('212')
        {
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'ten');
                libmei.AddAttribute(artic, 'place', 'above');
                libmei.AddChild(nobj, artic);
            }
        }
        case ('214')
        {
            nobj = GetNoteObjectAtPosition(sobj);

            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'marc');
                libmei.AddAttribute(artic, 'place', 'above');
                libmei.AddChild(nobj, artic);
            }
        }
        case ('217')
        {
            // up-bow above
            nobj = GetNoteObjectAtPosition(sobj);

            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'upbow');
                libmei.AddAttribute(artic, 'place', 'above');
                libmei.AddChild(nobj, artic);
            }
        }
        case ('218')
        {
            // down-bow above
            nobj = GetNoteObjectAtPosition(sobj);

            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'dnbow');
                libmei.AddAttribute(artic, 'place', 'above');
                libmei.AddChild(nobj, artic);
            }

        }
        case ('233')
        {
            // up-bow below
            nobj = GetNoteObjectAtPosition(sobj);

            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'upbow');
                libmei.AddAttribute(artic, 'place', 'below');
                libmei.AddChild(nobj, artic);
            }
        }
        case ('234')
        {
            // down-bow below
            nobj = GetNoteObjectAtPosition(sobj);

            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttribute(artic, 'artic', 'dnbow');
                libmei.AddAttribute(artic, 'place', 'below');
                libmei.AddChild(nobj, artic);
            }
            else
            {
                warnings = Self._property:warnings;
                warnings.Push(utils.Format(_ObjectCouldNotFindAttachment, bar.BarNumber, voicenum, sobj.Name));
            }
        }
        case ('240')
        {
            // double staccato
            return null;
        }
        case ('241')
        {
            // triple staccato
            return null;
        }
        case ('242')
        {
            // quadruple staccato
            return null;
        }
        case ('243')
        {
            // snap
            nobj = GetNoteObjectAtPosition(sobj);

            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttributeValue(artic, 'artic', 'snap');
                libmei.AddChild(nobj, artic);
            }
            else
            {
                warnings = Self._property:warnings;
                warnings.Push(utils.Format(_ObjectCouldNotFindAttachment, bar.BarNumber, voicenum, sobj.Name));
            }
        }
        case ('480')
        {
            //scoop
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttributeValue(artic, 'artic', 'scoop');
                libmei.AddChild(nobj, artic);
            }
        }
        case ('481')
        {
            //fall
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttributeValue(artic, 'artic', 'fall');
                libmei.AddChild(nobj, artic);
            }

        }
        case ('490')
        {
            nobj = GetNoteObjectAtPosition(sobj);

            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttributeValue(artic, 'artic', 'fingernail');
                libmei.AddChild(nobj, artic);
            }
        }
        case ('494')
        {
            //doit
            nobj = GetNoteObjectAtPosition(sobj);
            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttributeValue(artic, 'artic', 'doit');
                libmei.AddChild(nobj, artic);
            }

        }
        case ('495')
        {
            //plop
            nobj = GetNoteObjectAtPosition(sobj);

            if (nobj != null)
            {
                artic = libmei.Artic();
                libmei.AddAttributeValue(artic, 'artic', 'plop');
                libmei.AddChild(nobj, artic);
            }

        }

    }
}  //$end

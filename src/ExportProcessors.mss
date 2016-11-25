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

    header = sibmei2.GenerateMEIHeader();
    libmei.AddChild(mei, header);

    music = sibmei2.GenerateMEIMusic();
    libmei.AddChild(mei, music);

}  //$end

function ProcessBeam (bobj, note, layer) {
    //$module(ExportProcessors.mss)
    ret = null;

    if (bobj.Duration < 256)
    {
        // if this object is an eighth note but is not beamed, and if the
        // active beam is set, null out the active beam and return null.
        if (bobj.Beam = NoBeam and layer._property:ActiveBeamId != null)
        {
            layer._property:ActiveBeamId = null;
            layer._property:ActiveSubBeamId = null;
            return ret;
        }

        // If we are in an active SubBeam and the note is no GraceNote end the active SubBeam
        if (bobj.GraceNote = False and layer._property:ActiveSubBeamId != null)
        {
            layer._property:ActiveSubBeamId = null;
        }

        nextNote = bobj.NextItem(bobj.VoiceNumber, 'NoteRest');
        while (nextNote != null and nextNote.GraceNote = True)
        {
            nextNote = nextNote.NextItem(nextNote.VoiceNumber, 'NoteRest');
        }

        // If we have a Gracenote and an active Beam and no active SubBeam and the following
        // non-grace Note is a startbeam quit the current beam to start a new one
        if (bobj.GraceNote = True and layer._property:ActiveBeamId != null and layer._property:ActiveSubBeamId = null)
        {
            // if the previous Note is also a GraceNote and has a Beam do nothing
            prevNote = bobj.PreviousItem(bobj.VoiceNumber, 'NoteRest');
            if ((prevNote.GraceNote = True and prevNote.Beam = ContinueBeam and prevNote.Duration < 256) = False)
            {
                if (nextNote != null and (nextNote.Duration >= 256 or nextNote.Beam = StartBeam))
                {
                    layer._property:ActiveBeamId = null;
                }
            }
        } 

        /*
            It's possible that Sibelius records a 'continue beam' at the start
            of a beamed group. Visually, this doesn't look out of place if the previous
            note was a quarter note or higher. 
            
            The first check we do is if the note has a 'continue beam' attribute and
            the previous note has a duration higher than 256 (quarter) or is a rest then we probably have
            a false negative (i.e., there is the start of a beam, but it isn't necessarily
            encoded correctly).
        */
        falseNegative = False;
        startGraceNoteBeam = False;
        next_obj = bobj.NextItem(bobj.VoiceNumber, 'NoteRest');
        prev_obj = bobj.PreviousItem(bobj.VoiceNumber, 'NoteRest');

        if ((bobj.Beam = ContinueBeam or bobj.Beam = SingleBeam) and layer._property:ActiveBeamId = null)
        {
            // by all accounts this should be a beamed note, but we'll need to double-check.
            if (prev_obj != null and (prev_obj.Duration >= 256 or prev_obj.NoteCount = 0))
            {
                falseNegative = True;
            }
            // GraceNotes never have a StartBeam. If the following Note is also a GraceNote
            // and the Durations fine set the falseNegative also to true to start a new Beam
            if (bobj.GraceNote = True and next_obj != null and next_obj.GraceNote = True and next_obj.Duration < 256)
            {
                falseNegative = True;
                startGraceNoteBeam = True;
            }
        }

        if ((bobj.Beam = StartBeam or falseNegative = True) and ((nextNote != null and nextNote.Beam = ContinueBeam) or startGraceNoteBeam = true))
        {
            // if:
            //  - we have a start beam
            //  - the next (non grace) note is a continue beam
            //  - or if we should start a beam with grace notes
            // ... then start a beam
            beam = libmei.Beam();
            layer._property:ActiveBeamId = beam._id;

            
            libmei.AddChild(beam, note);

            // return the beam so that we can add it to the tree.
            return beam;
            
        }

        if (layer._property:ActiveBeamId != null and (bobj.Beam = ContinueBeam or bobj.Beam = SingleBeam))
        {
            // if we have a gracenote we need to check if either we already have an active SubBeam
            // or if the folowing Note is also graced so we need to start a new SubBeam
            bolNoteAdded2SubBeam = False;
            if (bobj.GraceNote = True)
            {
                if (layer._property:ActiveSubBeamId != null)
                {
                    beamid = layer._property:ActiveSubBeamId;
                    beam = libmei.getElementById(beamid);
                    libmei.AddChild(beam, note);
                    bolNoteAdded2SubBeam = True;
                }
                else
                {
                    next_obj = bobj.NextItem(next_obj.VoiceNumber, 'NoteRest');
                    if (next_obj != null and bobj.Duration < 256 and next_obj.GraceNote = True and next_obj.Duration < 256)
                    {
                        // Get the active Beam
                        beamid = layer._property:ActiveBeamId;
                        beam = libmei.getElementById(beamid);

                        // Create a new SubBeam
                        subBeam = libmei.Beam();
                        layer._property:ActiveSubBeamId = subBeam._id;

                        libmei.AddChild(beam, subBeam);
                        libmei.AddChild(subBeam, note);

                        bolNoteAdded2SubBeam = True;
                    }
                }
            }
            // If we haven't added the note to a SubBeam add it to the beam
            if (bolNoteAdded2SubBeam = False)
            {
                beamid = layer._property:ActiveBeamId;
                beam = libmei.getElementById(beamid);
                libmei.AddChild(beam, note);
            }

            // Always return the active beam
            beamid = layer._property:ActiveBeamId;
            beam = libmei.getElementById(beamid);
            // Return the Beam
            ret = beam;
        }
    }
    else
    {
        if (layer._property:ActiveBeamId != null)
        {
            // this is a break in any active beam, so register it as such.
            layer._property:ActiveBeamId = null;
        }
        if (layer._property:ActiveSubBeamId != null)
        {
            layer._property:ActiveSubBeamId = null;
        }
    }

    return ret;
}  //$end

function ProcessTuplet (bobj, meielement, layer) {
    //$module(ExportProcessors.mss)
    if (bobj.ParentTupletIfAny = null)
    {
        return null;
    }

    if (layer._property:ActiveTupletId = null)
    {
        tupletObject = bobj.ParentTupletIfAny;

        tuplet = libmei.Tuplet();

        layer._property:ActiveTupletObject = tupletObject;
        layer._property:ActiveTupletId = tuplet._id;

        if (libmei.GetName(meielement) = 'beam')
        {
            // get the first child
            startid = meielement.children[0];
        }
        else
        {
            startid = meielement._id;
        }

        libmei.AddAttribute(tuplet, 'startid', '#' & startid);
        libmei.AddAttribute(tuplet, 'num', tupletObject.Left);
        libmei.AddAttribute(tuplet, 'numbase', tupletObject.Right);

        tupletStyle = tupletObject.Style;

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

        tupletBracket = tupletObject.Bracket;

        switch(tupletBracket)
        {
            case(TupletBracketOff)
            {
                libmei.AddAttribute(tuplet, 'bracket.visible', 'false');
            }
        }

        return tuplet;
    }
    else
    {
        tid = layer._property:ActiveTupletId;
        t = libmei.getElementById(tid);

        if (IsLastNoteInTuplet(bobj))
        {
            libmei.AddAttribute(t, 'endid', '#' & meielement._id);
            layer._property:ActiveTupletObject = null;
            layer._property:ActiveTupletId = null;
        }

        return t;
    }
}  //$end

function ShiftTupletToTupletSpan (tuplet, layer) {
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
    tupletSpan._property:AddedToMeasure = False;

    layer._property:ActiveTupletId = tupletSpan._id;

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
}  //$end

function ProcessLyric (lyricobj, objectPositions) {
    //$module(ExportProcessors.mss)
    /*
        We need to track initial, medial, and terminal lyrics. Sibelius
        only allows us to know the medial and terminal, so we store all the
        syllables in an array until we reach the end of the word, and then
        attach them to the notes.
    */
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
        libmei.SetText(sylel, syl.Text);
        libmei.AddChild(verse, sylel);

        if (j = 0)
        {
            libmei.AddAttribute(sylel, 'wordpos', 'i'); // 'initial'

            if (lyric_word.Length > 1)
            {
                libmei.AddAttribute(sylel, 'con', 'd');
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
            if (bobj.Hidden = False) 
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

                    case ('SystemSymbolItem')
                    {
                        sysSymb = Self._property:SystemSymbolItems;
                        if (sysSymb.PropertyExists(bar.BarNumber) = False)
                        {
                            sysSymb[bar.BarNumber] = CreateSparseArray();
                        }
                        
                        //Get symbol converted
                        symbol = ProcessSystemSymbol(bobj);
                        
                        //Add element to dictionary
                        sysSymb[bar.BarNumber].Push(symbol);
                    }
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

function ProcessSymbol (sobj) {
    //$module(ExportProcessors.mss)
    Log('symbol index: ' & sobj.Index & ' name: ' & sobj.Name);
    Log(sobj.VoiceNumber);

    switch (sobj.Index)
    {
        case ('32')
        {
            // trill
            trill = GenerateTrill(sobj);
            mlines = Self._property:MeasureLines;
            mlines.Push(trill._id);
        }

        case ('36')
        {
            // inverted mordent
            mordent = libmei.Mordent();
            libmei.AddAttribute(mordent, 'form', 'inv');
            mlines = Self._property:MeasureLines;
            mlines.Push(mordent._id);
        }

        case ('37')
        {
            // mordent
            mordent = libmei.Mordent();
            libmei.AddAttribute(mordent, 'form', 'norm');
            mlines = Self._property:MeasureLines;
            mlines.Push(mordent._id);
        }

        case ('38')
        {
            // turn
            turn = libmei.Turn();
            libmei.AddAttribute(turn, 'form', 'norm');
            turn = AddBarObjectInfoToElement(sobj, turn);
            mlines = Self._property:MeasureLines;
            mlines.Push(turn._id);
        }

        case ('39')
        {
            // inverted turn
            turn = libmei.Turn();
            libmei.AddAttribute(turn, 'form', 'inv');
            turn = AddBarObjectInfoToElement(sobj, turn);
            mlines = Self._property:MeasureLines;
            mlines.Push(turn._id);
        }

        case ('242')
        {
            // triple staccato
            return null;
        }

        case ('404')
        {
            // start bracket
            startBracket = libmei.Symbol();

            //Add SMuFL glyph codepoint
            libmei.AddAttribute(startBracket, 'glyphnum', 'U+E1FE');
            //Add type of symbol
            libmei.AddAttribute(startBracket, 'type', 'group_start');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, startBracket);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);
        }

        case ('405')
        {
            // end bracket
            endBracket = libmei.Symbol();

            // Add SMuFL glyph codepoint
            libmei.AddAttribute(endBracket, 'glyphnum', 'U+E200');
            //Add type of symbol
            libmei.AddAttribute(endBracket, 'type', 'group_end');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, endBracket);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);
        }

        case ('836')
        {
            //Opening bracket 2 lines
            suppliedBracketStart = libmei.Symbol();

            // Add SMuFL glyph codepoint
            libmei.AddAttribute(suppliedBracketStart, 'glyphnum', 'U+E877');
            //Add type of symbol
            libmei.AddAttribute(suppliedBracketStart, 'type', 'suppliedBracketStart');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, suppliedBracketStart);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);
        }

        case ('837')
        {
            //Closing bracket 2 lines
            suppliedBracketEnd = libmei.Symbol();

            // Add SMuFL glyph codepoint
            libmei.AddAttribute(suppliedBracketEnd, 'glyphnum', 'U+E878');
            //Add type of symbol
            libmei.AddAttribute(suppliedBracketEnd, 'type', 'suppliedBracketEnd');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, suppliedBracketEnd);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);
        }

        case ('838')
        {
            //Opening bracket 3 lines
            suppliedBracketStart = libmei.Symbol();

            // Add SMuFL glyph codepoint
            libmei.AddAttribute(suppliedBracketStart, 'glyphnum', 'U+E877');
            //Add type of symbol
            libmei.AddAttribute(suppliedBracketStart, 'type', 'suppliedBracketStart');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, suppliedBracketStart);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);
        }

        case ('839')
        {
            //Closing bracket 3 lines
            suppliedBracketEnd = libmei.Symbol();

            // Add SMuFL glyph codepoint
            libmei.AddAttribute(suppliedBracketEnd, 'glyphnum', 'U+E878');
            //Add type of symbol
            libmei.AddAttribute(suppliedBracketEnd, 'type', 'suppliedBracketEnd');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, suppliedBracketEnd);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);
        }

        case ('18')
        {
            //(
            hampRptStartBracket = libmei.Symbol();

            // Add SMuFL glyph codepoint
            libmei.AddAttribute(hampRptStartBracket, 'glyphnum', 'U+E875');
            //Add type of symbol
            libmei.AddAttribute(hampRptStartBracket, 'type', 'hampRptStartBracket');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, hampRptStartBracket);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);
        }

        case ('19')
        {
            //)
            hampRptEndBracket = libmei.Symbol();

            // Add SMuFL glyph codepoint
            libmei.AddAttribute(hampRptEndBracket, 'glyphnum', 'U+E876');
            //Add type of symbol
            libmei.AddAttribute(hampRptEndBracket, 'type', 'hampRptEndBracket');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, hampRptEndBracket);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);    
        }

        case ('247')
        {
            //Single stroke
            comma = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(comma, 'type', 'ornamentComma');
            //Add SMuFL glyph codepoint
            libmei.AddAttribute(comma, 'glyphnum', 'U+E581');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, comma);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);  
        }
    }

    switch (sobj.Name)
    {
        case ('Division')
        {
            //HampSubDivision
            HampSubDivision = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(HampSubDivision, 'type', 'HampSubDivision');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, HampSubDivision);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);    
        }

        case ('[Division]')
        {
            //[Division]
            HampSubDivision = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(HampSubDivision, 'type', 'HampSubDivision');

            //Put symbol in dir element
            dir = libmei.Dir();
            supp = libmei.Supplied();
            libmei.AddChild(supp, HampSubDivision);
            libmei.AddChild(dir, supp);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);    
        }

        case ('End cycle')
        {
            //HampEndCycle
            HampEndCycle = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(HampEndCycle, 'type', 'HampEndCycle');
            libmei.AddAttribute(HampEndCycle, 'subtype', 'vertical');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, HampEndCycle);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);    
        }

        case ('End cycle 2')
        {
            //HampEndCycle
            HampEndCycle = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(HampEndCycle, 'type', 'HampEndCycle');
            libmei.AddAttribute(HampEndCycle, 'subtype', 'diagonal');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, HampEndCycle);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);    
        }

        case ('[End cycle]')
        {
            //HampEndCycle Brackets
            HampEndCycle = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(HampEndCycle, 'type', 'HampEndCycle');
            libmei.AddAttribute(HampEndCycle, 'subtype', 'vertical');

            //Put symbol in supplied element
            supp = libmei.Supplied();
            libmei.AddChild(supp, HampEndCycle);

            //Put supplied into dir
            dir = libmei.Dir();
            libmei.AddChild(dir, supp);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);
        }

        case ('Hamp Segno')
        {
            //HampSegno
            HampSegno = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(HampSegno, 'type', 'HampSegno');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, HampSegno);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);  
        }

        case ('[Hamp Segno]')
        {
            //[HampSegno]
            HampSegno = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(HampSegno, 'type', 'HampSegno');

            //Put symbol in dir element
            dir = libmei.Dir();
            supp = libmei.Supplied();
            libmei.AddChild(supp, HampSegno);
            libmei.AddChild(dir, supp);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);  
        }

        case ('Asterisk')
        {
            //Asterisk
            Asterisk = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(Asterisk, 'type', 'Asterisk');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, Asterisk);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);  
        }

        case ('Double stroke')
        {
            //Double stroke
            dblStroke = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(dblStroke, 'type', 'Double stroke');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, dblStroke);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);  
        }

        case ('Prolongation')
        {
            //Prolongation
            Prolongation = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(Prolongation, 'type', 'Prolongation');

            //Put symbol in dir element
            dir = libmei.Dir();
            libmei.AddChild(dir, Prolongation);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);
        }

        case ('[Comma]')
        {
            //Single stroke
            comma = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(comma, 'type', 'ornamentComma');
            //Add SMuFL glyph codepoint
            libmei.AddAttribute(comma, 'glyphnum', 'U+E581');

            //Put symbol in dir element
            dir = libmei.Dir();
            supp = libmei.Supplied();
            libmei.AddChild(supp,comma);
            libmei.AddChild(dir, supp);

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(dir, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, dir);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(dir._id);  
        }
    }

}  //$end

function ProcessSystemSymbol(sobj) {
    //$module(ExportProcessors.mss)

    switch (sobj.Index)
    {
        case (2)
        {
            //Coda
            dir = libmei.Dir();
            coda = libmei.Symbol();

            //Add SMuFL glyph codepoint
            libmei.AddAttribute(coda, 'glyphnum', 'U+E048');
            //Add type of symbol
            libmei.AddAttribute(coda, 'type', 'coda');

            //Add tstamp to dir
            libmei.AddAttribute(dir, 'tstamp', ConvertPositionToTimestamp(sobj.Position, sobj.ParentBar));

            //Add Coda to dir
            libmei.AddChild(dir, coda);

            return dir;
        }

        default
        {
            return null;
        }
    }

}  //$end

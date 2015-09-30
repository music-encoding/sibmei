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

function ProcessBeam (bobj, layer) {
    //$module(ExportProcessors.mss)
    next_obj = bobj.NextItem(bobj.VoiceNumber, 'NoteRest');
    ret = null;

    if (bobj.Duration < 256)
    {
        // if this object is an eighth note but is not beamed, and if the
        // active beam is set, null out the active beam and return null.
        if (bobj.Beam = NoBeam and layer._property:ActiveBeamId != null)
        {
            layer._property:ActiveBeamId = null;
            return ret;
        }

        /*
            It's possible that Sibelius records a 'continue beam' at the start
            of a beamed group. Visually, this doesn't look out of place if the previous
            note was a quarter note or higher. 
            
            The first check we do is if the note has a 'continue beam' attribute and
            the previous note has a duration higher than 256 (quarter) then we probably have
            a false negative (i.e., there is the start of a beam, but it isn't necessarily
            encoded correctly).
        */
        falseNegative = False;

        if (bobj.Beam = ContinueBeam and layer._property:ActiveBeamId = null)
        {
            // by all accounts this should be a beamed note, but we'll need to double-check.
            prev_obj = bobj.PreviousItem(bobj.VoiceNumber, 'NoteRest');

            if (prev_obj != null and (prev_obj.Duration >= 256))
            {
                falseNegative = True;
            }
        }

        if (next_obj != null and (bobj.Beam = StartBeam or falseNegative = True) and next_obj.Beam = ContinueBeam)
        {
            // if:
            //  - we're not at the end of the bar
            //  - we have a start beam
            //  - the next note is a continue beam
            beam = libmei.Beam();
            layer._property:ActiveBeamId = beam._id;

            // return the beam so that we can add it to the tree.
            ret = beam;
        }

        if (layer._property:ActiveBeamId != null and bobj.Beam = ContinueBeam)
        {
            // add the note to the beam, but return null
            // so that we don't add it again to the tree.
            beamid = layer._property:ActiveBeamId;
            beam = libmei.getElementById(beamid);

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

        // used for tuplet spans...
        // mlines = Self._property:MeasureLines;
        // mlines.Push(tuplet._id);
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
            switch (bobj.Type)
            {
                case ('SpecialBarline')
                {
                    spclbarlines = Self._property:SpecialBarlines;
                    spclbarlines[bar.BarNumber] = ConvertBarline(bobj.BarlineInternalType);
                }
                case ('SystemText')
                {
                    systemtext = Self._property:SystemText;

                    if (systemtext.PropertyExists(bar.BarNumber) = False)
                    {
                        systemtext[bar.BarNumber] = CreateSparseArray();
                    }

                    systemtext[bar.BarNumber].Push(bobj);
                }
                case ('RepeatTimeLine')
                {
                    RegisterVolta(bobj);
                }
            }
        }
    }
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

        // swap out the section as the parent for the ending
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

function ProcessSymbol (sobj, objectPositions) {
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
    }
}  //$end

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
    
// The method distinguishes first the duration of the current note and then if it is a grace note or a non-grace note.
// Check, if current note has to end an active beam.
// Then it will be decided, if the current note should start a (grace note) beam.
// If there is an active beam, add the current note to the beam and check what to be returned.
//  Returned will be either:
//    - nothing, if no beam is active,
//    - a beam of grace notes, if there are beamed grace notes, directly within the layer
//    - a beam of non grace notes, if there are beamed non-grace notes in the layer
//       - if there are beamed grace notes within a beam of non-grace notes,
//         the non-grace beam will be modified and returned
    
    ret = null;

    //Get the next note, to check for FalseNegative and the start of a new beam
    next_note = bobj.NextItem(bobj.VoiceNumber, 'NoteRest');
    
    // Get the next Non-Grace Note
    nextNonGraceNote = bobj.NextItem(bobj.VoiceNumber, 'NoteRest');
    while (nextNonGraceNote != null and nextNonGraceNote.GraceNote = True)
    {
        nextNonGraceNote = nextNonGraceNote.NextItem(nextNonGraceNote.VoiceNumber, 'NoteRest');
    }

    //Get previous note, to check if a beam should be started.
    prev_note = bobj.PreviousItem(bobj.VoiceNumber, 'NoteRest');    
                
                      
                

    if (bobj.Duration < 256)
    {
        // It's possible that Sibelius records a 'continue beam' at the start of a beamed group.
        // We have to check, if a beam has to be started anyway.
        // If falseNegative becomes true, a beam should be started even if the condition is ContinueBeam.

        falseNegative = null;
        
        if (bobj.GraceNote = true)
        {
            //First, all conditions to null an active grace beam should be checked.
            //According to that, it will be decided, if a new beam should be started or not.

            //Check if an active non-grace beam should be nulled
            if (nextNonGraceNote.Beam = StartBeam and layer._property:ActiveBeamId != null)
            {
                layer._property:ActiveBeamId = null;
            }
            
            if (layer._property:ActiveGraceBeamId = null and (bobj.Beam = ContinueBeam or bobj.Beam = SingleBeam))
            {
                //In most cases grace notes are ContinueBeam, even if they should start a grace note beam.
                //Now we have to check, if there is a falseNegative according to the following note
                //If the next note is a grace note and its duration is less than a quarter and with ContinueBeam

                if (next_note != null and (next_note.GraceNote = true and next_note.Duration < 256 and next_note.Beam = ContinueBeam))
                {
                    //If there is a previous non-grace note or no previous note, falseNegative becomes true, otherwise it stays false.
                    //But it's easier to check for the reverse.
                    if (prev_note != null and prev_note.GraceNote = true)
                    {
                        falseNegative = false;
                    }
                    //Either prev_note is null or prev_note.Grace = true
                    else
                    {
                        falseNegative = true;
                    }
                }
            }
            
            // if this object is an eighth note but is not beamed, and if the active grace beam is set, null out the active grace beam
            if (bobj.Beam = NoBeam and layer._property:ActiveGraceBeamId != null)
            {
                layer._property:ActiveGraceBeamId = null;
            }
            
            //If a grace note has a StartBeam condition, end the active grace beam and start a new one
            if (bobj.Beam = StartBeam or falseNegative = true)
            {
                if (layer._property:ActiveGraceBeamId != null)
                {
                    layer._property:ActiveGraceBeamId = null;
                }
                
                graceBeam = libmei.Beam();
                layer._property:ActiveGraceBeamId = graceBeam._id;

                //if there is an active non-grace beam, add the new grace beam to the active beam
                if (layer._property:ActiveBeamId != null)
                {

                    beamid = layer._property:ActiveBeamId;
                    beam = libmei.getElementById(beamid);
                    //Add grace beam to the active non-grace beam
                    libmei.AddChild(beam,graceBeam);
                }
            }
            
            //If a graceBeam is active, add the current note to the graceBeam.
            //Then, we have to check,what should be returned, either a grace note beam, a non-grace beam, or no beam at all.
            if (layer._property:ActiveGraceBeamId != null)
            {
                //If there is an active graceBeam, put the current grace note into that beam
                graceBeamID = layer._property:ActiveGraceBeamId;
                graceBeam = libmei.getElementById(graceBeamID);

                //Add current grace note to the beam
                libmei.AddChild(graceBeam, note);
                
                //Always the beam of the higher priority should be returned, check for it
                if (layer._property:ActiveBeamId != null)
                {
                    // Always return the active non grace note beam if existing
                    beamid = layer._property:ActiveBeamId;
                    beam = libmei.getElementById(beamid);
                    ret = beam;
                }
                else
                {
                    //If there is no active non-grace beam, return the active graceBeam.
                    ret = graceBeam;
                }
            }
            else
            {
                if (layer._property:ActiveBeamId != null)
                {
                    beamid = layer._property:ActiveBeamId;
                    beam = libmei.getElementById(beamid);
                    
                    //Add note to the active beam, because it is a non-beamed grace note while another non-grace beam is active.
                    libmei.AddChild(beam,note);
                    
                    // Return the Beam
                    ret = beam;
                }
                
                //Otherwise the current note is an independent grace note and will be a child of the layer.
            }
        }

        // bobj is not a grace note
        else
        {
            //If current note is not a grace note, but there is a grace note beam active, end this beam
            if (layer._property:ActiveGraceBeamId != null)
            {
                layer._property:ActiveGraceBeamId = null;
            }
            
            // if this object is an eighth note but is not beamed, and if the
            // active beam is set, null out the active beam and return null.
            if (bobj.Beam = NoBeam and layer._property:ActiveBeamId != null)
            {
                layer._property:ActiveBeamId = null;
            }
            
            //Check for falseNegative
            if ((bobj.Beam = ContinueBeam or bobj.Beam = SingleBeam) and layer._property:ActiveBeamId = null)
            {
                // by all accounts this should be a beamed note, but we'll need to double-check.
                if (prev_note != null and (prev_note.Duration >= 256 or prev_note.NoteCount = 0))
                {
                    falseNegative = True;
                }
            }
            
            //Start a new beam if necessary
            //The current note must be a start beam or a falseNegative and the next non-grace note must be a note that could continue the beam
            if(bobj.Beam = StartBeam or falseNegative = True)
            {
                if (nextNonGraceNote != null and (nextNonGraceNote.Duration < 256 and nextNonGraceNote.Beam = ContinueBeam))
                {
                    if(layer._property:ActiveBeamId != null)
                    {
                        layer._property:ActiveBeamId = null;
                    }
                    
                    beam = libmei.Beam();
                    layer._property:ActiveBeamId = beam._id;
                }
            }
            
            //If a beam is active, add the current note to the beam.
            //Then, we have to check,what should be returned, either a grace note beam, a non-grace beam, or no beam at all.
            if (layer._property:ActiveBeamId != null)
            {
                beamid = layer._property:ActiveBeamId;
                beam = libmei.getElementById(beamid);
                
                //Add current grace note to the beam
                libmei.AddChild(beam, note);
                
                ret = beam;
            }   
        }
    }

    //Duration of current note is at least a quarter note.
    else
    {
        //This is always a break in the current active beam, so register it as such.
        //It is also possible to have grace notes with a duration of a least a quarter.
        //If they occur in an active beam of non-grace notes, don't break that beam, but any existing grace note beam.
        
        if (bobj.GraceNote = true and next_note != null)
        {
            //This case ends every active grace note beam
            if (layer._property:ActiveGraceBeamId != null)
            {
                layer._property:ActiveGraceBeamId = null;
            }
            
            //If there is (still) an active non-grace beam, it depends on the next note, if it should be nulled.
            if (layer._property:ActiveBeamId != null)
            {
                //if the following note is another grace note, there is no decision about that beam possible
                //if next note is a non-grace note, it must be at least an eighth note with ContinueBeam to continue the active beam
                //add the current note to the active non-grace beam

                if (next_note.GraceNote = true or (next_note.Duration < 256 and next_note.Beam = ContinueBeam))
                {
                    beamid = layer._property:ActiveBeamId;
                    beam = libmei.getElementById(beamid);
                    libmei.AddChild(beam, note);
                    ret = beam;
                }
                //in all other cases break the beam
                else
                {
                    layer._property:ActiveBeamId = null;
                }
            }
        }
        //If the current note is not a grace note or doesn't have a following note, end every beam...
        //At least it is not possible to put grace notes at the end of a bar in Sibelius.
        else
        {
            if (layer._property:ActiveBeamId != null)
            {
                layer._property:ActiveBeamId = null;
            }
            if (layer._property:ActiveGraceBeamId != null)
            {
                layer._property:ActiveGraceBeamId = null;
            }
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
            
            //add a wordpos only for partial words
            if (lyric_word.Length > 1)
            {
                libmei.AddAttribute(sylel, 'wordpos', 'i'); // 'initial'

                libmei.AddAttribute(sylel, 'con', 'd'); //dash syllable connector
            }

            //it is also possible, that an initial syllable has an underscore as an extender, if it is the only syllable of a word
            if (lyric_word.Length = 1)
            {
                if (syl.NumNotes > 1)
                {
                    libmei.AddAttribute(sylel, 'con', 'u'); // 'underscore'
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

    //get list of Sgno symbols
    segnos = MSplitString(_userSegnoSymbols,';');

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

        case ('221')
        {
            //Fermata (D.C.)
            fermata = libmei.Fermata();
            libmei.AddAttribute(fermata, 'type','D.C.');

            //Try to get note at position of bracket and put id
            obj = GetNoteObjectAtPosition(sobj);

            if (obj != null)
            {
                libmei.AddAttribute(fermata, 'startid', '#' & obj._id);
            }

            else
            {
                //Add bar object information for safety
                dir = AddBarObjectInfoToElement(sobj, fermata);
            }

            //Add element to measure
            mlines = Self._property:MeasureLines;
            mlines.Push(fermata._id);
        }

        
    }

    //Get user-defined by name because index position doesn't stay consistent
    /*switch (sobj.Name)
    {
        case ('Division')
        {
            //HampSubDivision
            HampSubDivision = libmei.Symbol();

            //Add type of symbol
            libmei.AddAttribute(HampSubDivision, 'type', 'Division');

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
    }*/

    //Because we have a lot Segno symbols, it is much easier to solve this dynamically
    if(IsObjectInArray(segnos,sobj.Name))
    {
        segnoSymbol = libmei.Symbol();

        //Add name of symbol object as label
        libmei.AddAttribute(segnoSymbol, 'label', sobj.Name);

        //Put symbol in dir element
        dir = libmei.Dir();
        libmei.AddAttribute(dir, 'type','Segno');
        libmei.AddChild(dir, segnoSymbol);

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
            libmei.AddAttribute(coda, 'type', 'Coda');

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

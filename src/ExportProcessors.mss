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
        next_obj = bobj.NextItem(bobj.VoiceNumber, 'NoteRest');

        if ((bobj.Beam = ContinueBeam or bobj.Beam = SingleBeam) and layer._property:ActiveBeamId = null)
        {
            // by all accounts this should be a beamed note, but we'll need to double-check.
            prev_obj = bobj.PreviousItem(bobj.VoiceNumber, 'NoteRest');

            if (prev_obj != null and (prev_obj.Duration >= 256))
            {
                falseNegative = True;
            }
        }

        if (next_obj != null and (bobj.Beam = StartBeam or falseNegative = True) and next_obj.Beam = ContinueBeam and next_obj.Duration < 256)
        {
            // if:
            //  - we're not at the end of the bar
            //  - we have a start beam
            //  - the next note is a continue beam
            //  - the next note is a beamable duration (safeguard against quarter and longer
            //    notes with Beam = ContinueBeam, which for some reason can actually occur)
            beam = libmei.Beam();
            layer._property:ActiveBeamId = beam._id;

            // return the beam so that we can add it to the tree.
            ret = beam;
        }

        if (layer._property:ActiveBeamId != null and (bobj.Beam = ContinueBeam or bobj.Beam = SingleBeam))
        {
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

        syltext = libmei.GetText(sylel);

        if (utils.Pos('_', syltext) > -1)
        {
            // Syllable elision. split this syllable element by underscore.
            syllables = MSplitString(syltext, '_');
            sylarray = CreateSparseArray();

            // reset the text of the first syllable element to the first half of the syllable. 
            libmei.SetText(sylel, syllables[0]);
            libmei.AddAttribute(sylel, 'con', 'b');

            for s = 1 to syllables.Length
            {
                esyl = libmei.Syl();
                libmei.SetText(esyl, syllables[s]);
                libmei.AddChild(verse, esyl);
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

function ProcessTremolo (bobj) {
    //$module(ExportProcessors.mss)
    if (bobj.DoubleTremolos = 0)
    {
        return null;
    }

    Log('Fingered tremolo: ' & bobj.DoubleTremolos);
    tremEl = libmei.FTrem();
    libmei.AddAttribute(tremEl, 'slash', bobj.DoubleTremolos);
    libmei.AddAttribute(tremEl, 'measperf')
    
} //$end

function ProcessSymbol (sobj) {
    //$module(ExportProcessors.mss)
    Log('symbol index: ' & sobj.Index & ' name: ' & sobj.Name);
    Log(sobj.VoiceNumber);

    voicenum = sobj.VoiceNumber;

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
            mlines = Self._property:MeasureObjects;
            mlines.Push(mordent._id);
        }

        case ('37')
        {
            // mordent
            mordent = libmei.Mordent();
            libmei.AddAttribute(mordent, 'form', 'norm');
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
        case ('242')
        {
            // triple staccato
            return null;
        }
        case ('243')
        {
            // snap
            nobj = GetNoteObjectAtPosition(sobj);

            if (nobj != null)
            {
                libmei.AddAttributeValue(nobj, 'artic', 'snap');
            }
            else
            {
                warnings = Self._property:warnings;
                warnings.Push(utils.Format(_ObjectCouldNotFindAttachment, bar.BarNumber, voicenum, sobj.Name));
            }
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
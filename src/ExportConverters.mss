function ConvertDiatonicPitch (diatonic_pitch) {
    //$module(ExportConverters)
    octv = (diatonic_pitch / 7) - 1;
    pnames = CreateSparseArray('c', 'd', 'e', 'f', 'g', 'a', 'b');
    idx = (diatonic_pitch % 7);
    pname = pnames[idx];

    return CreateSparseArray(pname, octv);
}  //$end

function ConvertOffsetsToMEI (offset) {
    /*
     This function will convert the 1/32 unit
     Sibelius offsets into the MEI virtual units as required by the
     data.MEASUREMENTREL datatype used by MEI.

    The `StaffHeight` property always returns the staff height in millimeters.

    Most offsets are given in Sibelius Units, which
    are defined as 1/32 of a space. A space is 1/4 of the staff height.

    MEI virtual unit (vu) is defined as half the distance between the vertical
    center point of a staff line and that of an adjacent staff line.
    */
    return (offset / 16.0) & 'vu';
}  //$end

function ConvertOffsetsToMillimeters (offset) {
    /*
     This function will convert the 1/32 unit
     Sibelius offsets into a millimeter measurement as required by the
     data.MEASUREMENT datatype used by MEI.

    The `StaffHeight` property always returns the staff height in millimeters.

    Most offsets are given in Sibelius Units, which
    are defined as 1/32 of a space. A space is 1/4 of the staff height, so
    the staff height is always 128. A unit is therefore:
    ((staffheight / 128) = units in mm.

    So a staff height of 7mm (default) gives us (7 / 128) = 0.05mm per Sibelius
    Unit.
    */

    return (StaffHeight / 128.0 * offset) & 'mm';
}  //$end

function ConvertUnitsToPoints (units) {
    /*
        Points are 0.352778mm (a point is 1/72 of an inch * 25.4mm/in).
    */
    return (StaffHeight / 128.0 * units / 0.352778) & 'pt';
}  //$end


function ConvertKeySignature (numsharps) {
    //$module(ExportConverters.mss)
    switch (numsharps)
    {
        case (0)
        {
            // key of c
            return '0';
        }
        case (-8)
        {
            // atonal in Sibelius
            return '0';
        }
        case (numsharps > 0)
        {
            // sharps
            return numsharps & 's';
        }
        case (numsharps < 0)
        {
            //flats
            return utils.AbsoluteValue(numsharps) & 'f';
        }
    }
}  //$end

function PitchesInKeySignature (keysig) {
    //$module(ExportConverters.mss)

    // keysig is 7 >= 0 >= -7, for the number of sharps (negative is flats)
    ac = CreateSparseArray('F', 'C', 'G', 'D', 'A', 'E', 'B');

    // key of C, or atonal. All notes are natural.
    if (keysig = 0 or keysig = -8)
    {
        return CreateSparseArray();
    }

    if (keysig > 0)
    {
        return ac.Slice(0, keysig);
    }
    else
    {
        v = ac.Slice(keysig);
        v.Reverse();
        return v;
    }
}  //$end

function ConvertAccidental (noteobj) {
    //$module(ExportConverters.mss)
    // If accidentals are audible, but not visible, you get @accid.ges
    // If accidentals are both audible and visible, you get @accid
    // is_visible is not to be confused with hidden accidentals! is_visible
    // just determines whether an accidental is shown or not based on
    // the rules of CMN.

    // Returns a tuple [0 => accid (string), 1 => is_visible (bool)]
    // If the accidental is a natural and is visible, returns ('n', true); otherwise,
    // it returns ('', false);

    // first, determine if the accidental is visible.
    is_visible = HasVisibleAccidental(noteobj);
    ac = ' ';

    pname = Substring(noteobj.Name, 0, 1);  // captures first letter
    accid = Substring(noteobj.Name, 1);     // captures all other characters

    switch(accid)
    {
        case('bb')
        {
            ac = 'ff';
        }
        case('b-')
        {
            ac = 'fd';
        }
        case('b')
        {
            ac = 'f';
        }
        case('-')
        {
            ac = 'fu';
        }
        case('')
        {
            if (is_visible = True)
            {
                ac = 'n';
            }
        }
        case('+')
        {
            ac = 'sd';
        }
        case('#')
        {
            ac = 's';
        }
        case('#+')
        {
            ac = 'su';
        }
        case('x')
        {
            if (is_visible = True)
            {
                ac = 'x';
            }
            else
            {
                ac = 'ss';
            }
        }
        case('##')
        {
            ac = 'ss';
        }
    }

    ret = CreateSparseArray(ac, is_visible);
    return ret;
}  //$end

function HasVisibleAccidental (noteobj) {
    //$module(ExportConverters.mss)
    // determines whether a note is *likely* to have a visible accidental.
    // Caution: This is probably not 100% accurate.

    // Returns a boolean if the accidental is visible.

    // Sibelius 7.1.3 introduced the IsAccidentalVisible parameter. Sweet.
    if (Sibelius.ProgramVersion >= 7130)
    {
        return noteobj.IsAccidentalVisible and (noteobj.AccidentalStyle != HiddenAcc);
    }

    // If it has a cautionary accidental, it's most likely to be visible.
    if (noteobj.AccidentalStyle = CautionaryAcc)
    {
        return True;
    }

    if (noteobj.AccidentalStyle = HiddenAcc)
    {
        return False;
    }

    keysig = noteobj.ParentNoteRest.ParentBar.GetKeySignatureAt(noteobj.ParentNoteRest.Position);
    sf = PitchesInKeySignature(keysig.Sharps);
    pname = Substring(noteobj.Name, 0, 1);  // captures first letter
    accid = Substring(noteobj.Name, 1);  // captures all other characters

    // if the note is not in the key signature, then it should have an accidental
    note_is_in_keysig = utils.IsInArray(sf, pname);
    has_prev_pitch_with_accidental = False;

    parent_nr = noteobj.ParentNoteRest;
    parent_bar = parent_nr.ParentBar;

    for each NoteRest nr in parent_bar
    {
        if (nr.Position < parent_nr.Position)
        {
            for each n in nr
            {
                pname2 = Substring(n.Name, 0, 1);  // captures first letter
                accid2 = Substring(n.Name, 1);  // captures all other characters

                if (n.Name = noteobj.Name and note_is_in_keysig = False and n.Accidental != 0)
                {
                    has_prev_pitch_with_accidental = True;
                }

                if (n.Name = noteobj.Name and n.AccidentalStyle = CautionaryAcc)
                {
                    has_prev_pitch_with_accidental = True;
                }

                if (n.Name = noteobj.Name and note_is_in_keysig = True)
                {
                    has_prev_pitch_with_accidental = False;
                }

                // this is a special case for dealing with naturals. If the pitch names
                // match, and the note is not in the key signature, and the previous pitch
                // was not empty, then we probably have a natural on the query note.
                if (pname = pname2 and note_is_in_keysig = False and accid2 != '')
                {
                    has_prev_pitch_with_accidental = True;
                }

            }
        }
        else
        {
            for each n in nr
            {
                if (n.Name = noteobj.Name and n.Accidental != 0 and note_is_in_keysig = True)
                {
                    has_prev_pitch_with_accidental = False;
                }
            }
        }
    }

    // deal with the 'weird' accidental values that don't have a value in noteobj.Accidental
    switch (accid)
    {
        case ('bb')
        {
            ret = (has_prev_pitch_with_accidental != True);
            return ret;
        }
        case ('b-')
        {
            ret = (has_prev_pitch_with_accidental != True);
            return ret;
        }
        case ('-')
        {
            ret = (has_prev_pitch_with_accidental != True);
            return ret;
        }
        case ('+')
        {
            ret = (has_prev_pitch_with_accidental != True);
            return ret;
        }
        case ('#+')
        {
            ret = (has_prev_pitch_with_accidental != True);
            return ret;
        }
    }

    if (noteobj.Accidental = 0 and note_is_in_keysig = True and has_prev_pitch_with_accidental = False)
    {
        // it's a natural?
        return True;
    }

    if (note_is_in_keysig = True and has_prev_pitch_with_accidental = False)
    {
        return False;
    }

    if (has_prev_pitch_with_accidental = False and noteobj.Accidental != 0)
    {
        return True;
    }

    if (has_prev_pitch_with_accidental = True and accid = '')
    {
        // this is the corresponding return value for special cased naturals.
        return True;
    }

    // Finally, by default, assume this has no accidental.
    return False;
}  //$end


function ConvertBracket (bracket) {
    //$module(ExportConverters.mss)
    switch(bracket)
    {
        case(BracketFull)
        {
            return 'bracket';
        }
        case(BracketBrace)
        {
            return 'brace';
        }
        case(BracketSub)
        {
            return 'bracketsq';
        }
        default
        {
            return 'none';
        }
    }
}  //$end


function ConvertColor (nrest) {
    //$module(ExportConverters.mss)
    r = nrest.ColorRed;
    g = nrest.ColorGreen;
    b = nrest.ColorBlue;
    a = nrest.ColorAlpha / 255.0;

    return 'rgba(' & r & ',' & g & ',' & b & ',' & a & ')';
}  //$end

function ConvertNoteStyle (style) {
    //$module(ExportConverters.mss)
    noteStyle = ' ';

    if (style = NormalNoteStyle)
    {
        return ' ';
    }

    switch (style)
    {
        case (CrossNoteStyle)
        {
            noteStyle = 'x';
        }
        case (DiamondNoteStyle)
        {
            noteStyle = 'diamond';
        }
        case (CrossOrDiamondNoteStyle)
        {
            // Sibelius uses this for percussion
            // and does not differentiate in the
            // head style, so we have to choose one
            // or the other.
            noteStyle = 'x';
        }
        case (BlackAndWhiteDiamondNoteStyle)
        {
            // There is not filled diamond in data.HEADSHAPE.list
            noteStyle = 'filldiamond';
        }
        case (SlashedNoteStyle)
        {
            // There is only an unfilled slash in data.HEADSHAPE.list, no added slash
            noteStyle = 'addslash';
        }
        case (BackSlashedNoteStyle)
        {
            // There is only an unfilled backslash in data.HEADSHAPE.list, no added slash
            noteStyle = 'addbackslash';
        }
        case (ArrowDownNoteStyle)
        {
            // this is not completely correct, since
            // we use the same value for up and down
            // iso triangles. But it's all we have for now.
            noteStyle = 'isotriangle';
        }
        case (ArrowUpNoteStyle)
        {
            noteStyle = 'isotriangle';
        }
        case (InvertedTriangleNoteStyle)
        {
            noteStyle = 'isotriangle';
        }
        case (ShapedNote1NoteStyle)
        {
            noteStyle = 'isotriangle';
        }
        case (ShapedNote2NoteStyle)
        {
            noteStyle = 'semicircle';
        }
        case (ShapedNote3NoteStyle)
        {
            noteStyle = 'diamond';
        }
        case (ShapedNote4StemUpNoteStyle)
        {
            noteStyle = 'rtriangle';
        }
        case (ShapedNote4StemDownNoteStyle)
        {
            noteStyle = 'rtriangle';
        }
        case (ShapedNote5NoteStyle)
        {
            // this looks normal...
            noteStyle = ' ';
        }
        case (ShapedNote6NoteStyle)
        {
            noteStyle = 'square';
        }
        case (ShapedNote7NoteStyle)
        {
            noteStyle = 'piewedge';
        }
    }

    return noteStyle;
}  //$end


function ConvertPositionToTimestamp (position, bar) {
    //$module(ExportConverters.mss)
    /*
        To convert Sibelius ticks to musical timestamps
        we use the formula:

        tstamp = (notePosition / beatDuration)
    */

    timesignature = SystemStaff.CurrentTimeSignature(bar.BarNumber);

    if (position = 0)
    {
        return 1;
    }

    // Make sure we're working with floating point numbers with '.0'
    beatDuration = 1024.0 / timesignature.Denominator;
    ret = (position / beatDuration) + 1;

    return ret;
}  //$end

function ConvertPositionWithDurationToTimestamp (bobj) {
    //$module(ExportConverters.mss)

    /*
        Like ConvertPositionToTimestamp, but suitable to filling out the tstamp2 parameter
        with an object of a specific duration (such as a slur or hairpin), e.g., 1m+2

        NB: Can only be used on objects with EndBarNumber and EndPosition attributes, like Lines.
    */
    startBar = bobj.ParentBar;
    startBarNum = startBar.BarNumber;
    endBarNum = bobj.EndBarNumber;
    endBar = startBar.ParentStaff.NthBar(endBarNum);
    endPosition = bobj.EndPosition;
    measureDuration = endBarNum - startBarNum;
    position = ConvertPositionToTimestamp(endPosition, endBar);

    return measureDuration & 'm+' & position;
} //$end


function ConvertFbFigures (fb, bobj) {
    //$module(ExportConverters)
    if (Self._property:FigbassCharMap = null)
    {
        Self._property:FigbassCharMap = InitFigbassCharMap();
    }
    figbassCharMap = Self._property:FigbassCharMap;

    n = 1;
    currentLine = '';
    altsym = null;
    components = bobj.TextWithFormatting;

    // Strangely, components.Length is null, so we can't use a for loop.
    // We want one more iteration than we have components, hence we start at
    // -1.
    i = -1;
    component = null;
    while ((i = -1) or (component != null))
    {
        i = i + 1;
        component = components[i];
        if ((component = null) or (component = '\\n\\'))
        {
            // We reached a linebreak or the last component
            if (currentLine != '')
            {
                f = CreateElement('f');
                SetText(f, currentLine);
                AddAttribute(f, 'n', n);
                AddChild(fb, f);
                if (altsym != null)
                {
                    AddAttribute(f, 'altsym', altsym);
                    altsym = null;
                }
            }
            n = n + 1;
            currentLine = '';
        }
        else
        {
            if (CharAt(component, 0) != '\\')
            {
                // We ignore formatting, i.e. text that is encoded with leading '\'
                for j = 0 to Length(component)
                {
                    sibChar = CharAt(component, j);
                    outputChar = figbassCharMap[sibChar];
                    if (outputChar = null)
                    {
                        // Char is not in map => Convert literally
                        currentLine = currentLine & sibChar;
                    }
                    else
                    {
                        if (IsObject(outputChar))
                        {
                            // This is a special char that we output in normalized form
                            // with a reference to a SMuFL glyph. outputChar is an array
                            // with two entries: The normalized format and the SMuFL
                            // codepoint.
                            currentLine = currentLine & outputChar[0];
                            altsym = GenerateSmuflAltsym(outputChar[1], outputChar[2]);
                        }
                        else
                        {
                            currentLine = currentLine & outputChar;
                        }
                    }
                }
            }
        }
    }
}  //$end


function ConvertDate (datetime) {
    //$module(ExportConverters.mss)
    d = datetime.DayOfMonth;
    m = datetime.Month;
    y = datetime.Year;

    time = datetime.TimeWithSeconds;

    isodate = utils.Format('%s-%s-%sT%sZ', y, m, d, time);

    return isodate;
}  //$end

function ConvertTimeStamp (time) {
    //$module(ExportConverters.mss)
    // Converts a timestamp in milliseconds to an
    // isotime (hh:mm:ss.s) suitable for use in @tstamp.real

    if (time < 0)
    {
        // Negative times can occur when Sibelius does not know when an event
        // is played. In that case, don't write a time.
        return ' ';
    }

    secs = time % 60000.0 / 1000.0;
    mins = time % 3600000 / 60000;
    hours = time / 3600000;

    if (secs < 10)
    {
        secs = '0' & secs;
    }
    if (mins < 10)
    {
        mins = '0' & mins;
    }
    if (hours < 10)
    {
        hours = '0' & hours;
    }

    return hours & ':' & mins & ':' & secs;
}  //$end

function ConvertFermataForm (bobj) {
    //$module(ExportConverters.mss)

    // Tries to find out @shape for 'keypad fermatas' of NoteRests and BarRests.
    // At this point we expect that the calling function has already determined
    // that the noteRest has a 'keypad fermata'.

    if (bobj.Type = 'BarRest')
    {
        stemweight = 0;
    }
    else
    {
        stemweight = bobj.Stemweight;
    }

    if ((stemweight < 0) or (bobj.VoiceNumber % 2 = 1) or HasSingleVoice(bobj.ParentBar))
    {
        return 'norm';
    }
    else
    {
        return 'inv';
    }

}  //$end


function ConvertToAbsoluteDuration (noteRest) {
    // Factors in tuplets to calculate an 'absolute' duration, based on
    // non-tuplet whole note duration = 1024.
    absoluteDuration = noteRest.Duration * 1.0;
    tuplet = noteRest.ParentTupletIfAny;
    while (null != tuplet)
    {
        absoluteDuration = absoluteDuration * tuplet.Right / tuplet.Left;
        tuplet = tuplet.ParentTupletIfAny;
    }
    return absoluteDuration;
}  //$ends


function ConvertChord (guitarFrame) {
    // Converts a GuitarFrame to an element template

    harm = @Element('harm', @Attrs('label', guitarFrame.ChordNameAsPlainText));
    styledString = guitarFrame.ChordNameAsStyledString;

    for i = 0 to Length(styledString)
    {
        char = CharAt(styledString, i);
        previousItem = harm[-1];
        currentItem = ChordFontMap[char];
        switch (true) {
            case ('' = currentItem)
            {
                RegisterWarning(guitarFrame, 'Unsupported chord character', char & ' (' & (char + 0) & ')');
            }
            case (harm.Length < 3)
            {
                // This is the first child
                harm.Push(currentItem);
            }
            case (IsObject(previousItem) != IsObject(currentItem))
            {
                // items are not compatible and can not be combined
                harm.Push(currentItem);
            }
            case (not IsObject(currentItem))
            {
                // both items are strings and can be joined
                harm[-1] = previousItem & currentItem;
            }
            case (previousItem.Slice(0, 2) != currentItem.Slice(0, 2))
            {
                // Tag name or attributes differ. Items can't be combined.
                harm.Push(currentItem);
            }
            case (IsObject(previousItem[-1]) or IsObject(currentItem[-1]))
            {
                // Combine element or mixed text/element children of both items
                // Clone (slice) the previous item to not modify the template
                harm[-1] = previousItem.Slice(0, previousItem.Length).Concat(currentItem.Slice(2));
            }
            default
            {
                // Combine text children of both items
                // Clone (slice) the previous item to not modify the template
                harm[-1] = previousItem.Slice(0, previousItem.Length - 1);
                harm[-1].Push(previousItem[-1] & currentItem[-1]);
            }
        }
    }

    return harm;
}  //$end


function ConvertChordGrid (guitarFrame) {
    // Creates a <chordDef>, attaches it to <chordTable> and returns the
    // reference to the <chordDef> (ID prefixed with '#')

    if (null = ChordTable)
    {
        ChordTable = CreateElement('chordTable');
        // Schema requires this to precede <staffGrp> elements
        AddChildAtPosition(MainScoreDef, ChordTable, 0);
    }

    chordDef = CreateElement('chordDef');
    AddChild(ChordTable, chordDef);
    AddAttribute(chordDef, 'label', guitarFrame.ChordNameAsPlainText);
    if (guitarFrame.LowestVisibleFret > 1)
    {
        AddAttribute(chordDef, 'tab.pos', guitarFrame.LowestVisibleFret);
    }
    barreEndString = -1;
    barres = CreateSparseArray();

    fingerings = guitarFrame.Fingerings;

    numberOfStrings = guitarFrame.NumberOfStrings;

    for stringIndex = 0 to numberOfStrings
    {
        chordMember = CreateElement('chordMember');
        AddChild(chordDef, chordMember);
        // In Sibelius, course 0 is lowest, but the convention is the reverse
        AddAttribute(chordMember, 'tab.course', numberOfStrings - stringIndex);
        fretPosition = guitarFrame.GetPositionOfFingerOnNthString(stringIndex);
        switch (fretPosition)
        {
            case (-1)
            {
                AddAttribute(chordMember, 'tab.fing', 'x');
            }
            case (0)
            {
                AddAttribute(chordMember, 'tab.fing', 'o');
                AddAttribute(chordMember, 'tab.fret', '0');
            }
            default
            {
                AddAttribute(chordMember, 'tab.fret', fretPosition);
                fingering = CharAt(fingerings, stringIndex);
                // The schema only allows fingerings from 1 to 4. Single quotes
                // are required because we're dealing with char, not int.
                if (fingering >= '1' and fingering <= '4')
                {
                    AddAttribute(chordMember, 'tab.fing', fingering);
                }
            }
        }

        startingBarreIndex = IndexOfBarreStartingAtString(guitarFrame, stringIndex);
        if (startingBarreIndex >= 0)
        {
            barre = CreateElement('barre');
            barres.Push(barre);
            AddAttribute(barre, 'startid', '#' & chordMember._id);
            // The specs say, @fret is deprecated in favour of @tab.fret, which
            // however is not yet available on <barre>
            AddAttribute(barre, 'fret', fretPosition);
            barreEndString = guitarFrame.GetEndStringForNthBarre(startingBarreIndex);
        }

        if (stringIndex = barreEndString)
        {
            AddAttribute(barres[-1], 'endid', '#' & chordMember._id);
        }
    }

    // <barre>s must follow <chordMember>s
    for each barre in barres
    {
        AddChild(chordDef, barre);
    }

    return '#' & chordDef._id;
}  //$end


function IndexOfBarreStartingAtString (guitarFrame, startStringIndex) {
    // Returns index n >= 0 if startStringIndex is the first string of the nth
    // barre and that barre is plausible (i.e. all strings in the barre are
    // stopped at the same fret and there are no gaps in the barre). This check
    // is done because some barres that ManuScript reports are not actually
    // present in the chord diagram that Sibelius displays.
    //
    // If the string does not start a barre, -1 is returned.

    for barreIndex = 0 to guitarFrame.NumBarresInChord
    {
        if (startStringIndex = guitarFrame.GetStartStringForNthBarre(barreIndex))
        {
            fretPosition = guitarFrame.GetPositionOfFingerOnNthString(startStringIndex);
            endStringIndex = guitarFrame.GetEndStringForNthBarre(barreIndex);
            if (endStringIndex > startStringIndex)
            {
                for stringIndex = startStringIndex + 1 to endStringIndex
                {
                    if (guitarFrame.GetPositionOfFingerOnNthString(stringIndex) < fretPosition)
                    {
                        barreIndex = -1;
                    }
                }
                if (barreIndex >= 0)
                {
                    return barreIndex;
                }
            }
        }
    }

    return -1;
}  //$end


function ConvertToChordGridHash (guitarFrame) {
    // This hash is used to identify the <chordDef> that `guitarFrame` belongs
    // to. The hash is composed of:
    //  * A letter defining the lowest visible fret (A: 1st fret)
    //  * fingering (1 character per string)
    //  * semicolon (like this we know for sure how many strings there are)
    //  * finger position (1 character per string, '/' for quiet strings)
    //  * barre information (1 cryptic character per barre)

    numberOfStrings = guitarFrame.NumberOfStrings;
    hash = Chr(guitarFrame.LowestVisibleFret + 'A' - 1) & guitarFrame.Fingerings & ';';
    for stringIndex = 0 to guitarFrame.NumberOfStrings
    {
        // Finger position of empty string (-1) becomes `/` in the hash because
        // '/' precedes '0' in ASCII/Unicode.
        hash = hash & (Chr(guitarFrame.GetPositionOfFingerOnNthString(stringIndex) + '0'));
    }
    for barreIndex = 0 to guitarFrame.NumBarresInChord
    {
        // Sibelius allows a maximum of 128 strings
        hash = hash & Chr(
            guitarFrame.GetStartStringForNthBarre(barreIndex) * 128
            + guitarFrame.GetEndStringForNthBarre(barreIndex)
        );
    }
    return hash;
}  //$end

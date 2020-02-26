
function ConvertClef (clefid) {
    //$module(ExportConverters.mss)
    clefparts = MSplitString(clefid, '.');
    shape = ' ';
    line = ' ';
    dis = ' ';
    dir = ' ';

    switch(clefparts[2])
    {
        case ('down')
        {
            dir = 'below';
        }
        case ('up')
        {
            dir = 'above';
        }
    }

    switch(clefparts[3])
    {
        case ('8')
        {
            dis = '8';
        }
        case ('15')
        {
            dis = '15';
        }
    }

    switch (clefparts[1]) {
        case ('bass')
        {
            shape = 'F';
            line = '4';
        }
        case ('treble')
        {
            if (clefparts[4] = 'old')
            {
                shape = 'GG';
            }
            else
            {
                shape = 'G';
            }
            line = '2';
        }
        case ('tenor')
        {
            shape = 'C';
            line = '4';
        }
        case ('alto')
        {
            shape = 'C';
            line = '3';
        }
        case ('soprano')
        {
            shape = 'C';
            if (clefparts[2] = 'mezzo')
            {
                line = '2';
            }
            else
            {
                line = '1';
            }
        }
        case ('baritone')
        {
            if (clefparts[2] = 'c')
            {
                shape = 'C';
                line = '5';
            }
            else
            {
                shape = 'F';
                line = '3';
            }
        }
        case ('violin')
        {
            shape = 'G';
            line = '1';
        }
        case ('sub-bass')
        {
            shape = 'F';
            line = '5';
        }
        case ('tab')
        {
            shape = 'TAB';
        }
        case (('percussion') or ('percussion_2'))
        {
            shape = 'perc';
        }
    }

    ret = CreateSparseArray(shape, line, dis, dir);
    return ret;
}  //$end

function ConvertOctava (octava_id) {
    //$module(ExportConverters.mss)
    octparts = MSplitString(octava_id, '.');
    switch(octparts[3])
    {
        case ('minus15')
        {
            dis = '15';
            place = 'below';
        }
        case ('minus8')
        {
            dis = '8';
            place = 'below';
        }
        case ('plus15')
        {
            dis = '15';
            place = 'above';
        }
        case ('plus8')
        {
            dis = '8';
            place = 'above';
        }
        default
        {
            dis = ' ';
            place = ' ';
        }
    }
    return CreateSparseArray(dis, place);
}  //$end

function ConvertSlur (slur_value) {
    //$module(ExportConverters.mss)
    slurparts = MSplitString(slur_value, '.');
    direction = ' ';
    style = ' ';
    switch(slurparts[3])
    {
        case ('up')
        {
            direction = 'above';
        }
        case ('down')
        {
            direction = 'below';
        }
        default
        {
            direction = ' ';
        }
    }
    switch(slurparts[4])
    {
        case ('dashed')
        {
            style = 'dashed';
        }
        case ('dotted')
        {
            style = 'dotted';
        }
        default
        {
            style = ' ';
        }
    }
    return CreateSparseArray(direction, style);
}  //$end

function ConvertDiatonicPitch (diatonic_pitch) {
    //$module(ExportConverters)
    octv = (diatonic_pitch / 7) - 1;
    pnames = CreateSparseArray('c', 'd', 'e', 'f', 'g', 'a', 'b');
    idx = (diatonic_pitch % 7);
    pname = pnames[idx];

    return CreateSparseArray(pname, octv);
}  //$end

function ConvertOffsetsToMEI (offset) {
    //$module(ExportConverters.mss)

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
    retval = (offset / 16.0);
    return retval & 'vu';
}  //$end

function ConvertOffsetsToMillimeters (offset) {
    //$module(ExportConverters.mss)

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
    scr = Sibelius.ActiveScore;
    staffheight = scr.StaffHeight;
    factor = (staffheight / 128.0);
    oset = factor * offset;
    retval = oset & 'mm';
    return retval;
}  //$end

function ConvertUnitsToPoints (units) {
    //$module(ExportConverters.mss)
    scr = Sibelius.ActiveScore;
    staffheight = scr.StaffHeight;

    /*
        Points are 0.352778mm (a point is 1/72 of an inch * 25.4mm/in).
    */
    retval = (((staffheight / 128.0) * units) / 0.352778;
    return retval & 'pt';
}  //$end

function ConvertDuration (dur) {
    //$module(ExportConverters.mss)
    // there doesn't really seem to be a smarter way to do this...
    // 1024 = 1 whole note

    ret = CreateSparseArray();

    pow = PrevPow2(dur);
    counter = pow;
    dots = 0;
    powcount = pow;
    durset = false;

    durrem = 1024 % dur;
    if (durrem != 0)
    {
        while (counter < dur)
        {
            powcount = (powcount / 2);
            counter = counter + powcount;
            dots = dots + 1;

            if (dots > 5)
            {
                // prevent a runaway loop.
                counter = 1000000000;
            }
        }
    }

    switch (powcount)
    {
        case (pow >= 4096)
        {
            ret[0] = 'long';
            durset = true;
        }
        case (pow >= 2048)
        {
            ret[0] = 'breve';
            durset = true;
        }
        default
        {
            if (durset = false)
            {
                ret[0] = 1024 / pow;
            }
        }
    }

    if (dots = 0)
    {
        ret[1] = ' ';
    }
    else
    {
        ret[1] = dots;
    }

    return ret;
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
            ac = 'x';
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

function ConvertNamedTimeSignature (timesig) {
    //$module(ExportConverters.mss)
    switch(timesig)
    {
        case(CommonTimeString)
        {
            return 'common';
        }
        case(AllaBreveTimeString)
        {
            return 'cut';
        }
        default
        {
            return ' ';
        }
    }
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
            return 'line';
        }
        default
        {
            return 'none';
        }
    }
}  //$end

function ConvertSibeliusStructure (score) {
    //$module(ExportConverters.mss)
    // Takes in the Staff/Bar Sibelius Structure and returns a Bar/Staff
    // mapping for our MEI writers.
    bar_to_staff = CreateDictionary();

    // Invert the Sibelius structure
    for each Staff s in score
    {
        for each Bar b in s
        {
            if (bar_to_staff.PropertyExists(b.BarNumber))
            {
                bar_to_staff[b.BarNumber].Push(s.StaffNum);
            }
            else
            {
                bar_to_staff[b.BarNumber] = CreateSparseArray();
                bar_to_staff[b.BarNumber].Push(s.StaffNum);
            }
        }
    }
    return bar_to_staff;
}  //$end

function ConvertColor (nrest) {
    //$module(ExportConverters.mss)
    r = nrest.ColorRed;
    g = nrest.ColorGreen;
    b = nrest.ColorBlue;
    a_dec = nrest.ColorAlpha & '.0';
    a = a_dec / 255.0;

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
            noteStyle = 'cross';
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
            noteStyle = 'cross';
        }
        case (BlackAndWhiteDiamondNoteStyle)
        {
            noteStyle = 'filldiamond';
        }
        case (SlashedNoteStyle)
        {
            noteStyle = 'addslash';
        }
        case (BackSlashedNoteStyle)
        {
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
            // there is no square in MEI...
            noteStyle = ' ';
        }
        case (ShapedNote7NoteStyle)
        {
            noteStyle = 'piewedge';
        }
    }

    return noteStyle;
}  //$end

function ConvertSlurStyle (style) {
    //$module(ExportConverters.mss)
    slurparts = MSplitString(style, '.');
    direction = ' ';
    style = ' ';

    switch(slurparts[3])
    {
        case ('up')
        {
            direction = 'above';
        }
        case ('down')
        {
            direction = 'below';
        }
        default
        {
            direction = ' ';
        }
    }
    switch(slurparts[4])
    {
        case ('dashed')
        {
            style = 'dashed';
        }
        case ('dotted')
        {
            style = 'dotted';
        }
        default
        {
            style = ' ';
        }
    }
    return CreateSparseArray(direction, style);
}  //$end

function ConvertPositionToTimestamp (position, bar) {
    //$module(ExportConverters.mss)
    /*
        To convert Sibelius ticks to musical timestamps
        we use the formula:

        tstamp = (notePosition / beatDuration)
    */

    timesignature = Sibelius.ActiveScore.SystemStaff.CurrentTimeSignature(bar.BarNumber);

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

function ConvertTupletStyle (tupletStyle) {
    //$module(ExportConverters.mss)
    switch (tupletStyle)
    {
        case(TupletNoNumber)
        {
            libmei.AddAttribute(activeTuplet, 'dur.visible', 'false');
        }
        case(TupletLeft)
        {
            libmei.AddAttribute(activeTuplet, 'num.format', 'count');
        }
        case(TupletLeftRight)
        {
            libmei.AddAttribute(activeTuplet, 'num.format', 'ratio');
        }
    }

}  //$end

function ConvertBarline (linetype) {
    //$module(ExportConverters.mss)
    switch(linetype)
    {
        case (SpecialBarlineStartRepeat)
        {
            // start repeat
            return 'rptstart';
        }
        case (SpecialBarlineEndRepeat)
        {
            // end repeat
            return 'rptend';
        }
        case (SpecialBarlineDashed)
        {
            // dashed
            return 'dashed';
        }
        case (SpecialBarlineDouble)
        {
            // double
            return 'dbl';
        }
        case (SpecialBarlineFinal)
        {
            // final
            return 'end';
        }
        case (SpecialBarlineInvisible)
        {
            // invisible
            return 'invis';
        }
        case (SpecialBarlineBetweenStaves)
        {
            // between staves
            // no MEI equiv.
            return ' ';
        }
        case (SpecialBarlineNormal)
        {
            // normal
            // this should usually be needed.
            return 'single';
        }
        case (SpecialBarlineTick)
        {
            // tick
            // unknown
            return ' ';
        }
        case (SpecialBarlineShort)
        {
            // short
            // unknown
            return ' ';
        }
        default
        {
            return ' ';
        }
    }
}  //$end

function ConvertText (textobj) {
    //$module(ExportConverters.mss)
    styleid = textobj.StyleId;
    switch (styleid)
    {
        case ('text.staff.expression')
        {
            dynam = libmei.Dynam();
            libmei.SetText(dynam, lstrip(textobj.Text));
            libmei.AddAttribute(dynam, 'staff', textobj.ParentBar.ParentStaff.StaffNum);
            libmei.AddAttribute(dynam, 'tstamp', ConvertPositionToTimestamp(textobj.Position, textobj.ParentBar));

            if (textobj.Dx != 0)
            {
                libmei.AddAttribute(dynam, 'ho', ConvertOffsetsToMEI(textobj.Dx));
            }

            if (textobj.Dy != 0)
            {
                libmei.AddAttribute(dynam, 'vo', ConvertOffsetsToMEI(textobj.Dy));
            }
            return dynam;
        }
        case ('text.system.page_aligned.title')
        {
            text = ConvertSubstitution(textobj.Text);
            atext = libmei.AnchoredText();
            title = libmei.Title();

            libmei.AddChild(atext, title);
            libmei.SetText(title, text);

            return atext;
        }
        case ('text.system.page_aligned.composer')
        {
            return ConvertTextElement(textobj);
        }
        case ('text.system.tempo')
        {
            tempo = libmei.Tempo();
            atext = ConvertTextElement(textobj);
            libmei.AddAttribute(tempo, 'tstamp', ConvertPositionToTimestamp(textobj.Position, textobj.ParentBar));
            libmei.AddChild(tempo, atext);
            return tempo;
        }
        case ('text.staff.space.figuredbass')
        {
            harm = libmei.Harm();
            harm = AddBarObjectInfoToElement(textobj, harm);
            fb = libmei.Fb();
            libmei.AddChild(harm, fb);
            ConvertFbFigures(fb, textobj);
            return harm;
        }
        default
        {
            return null;
        }
    }
}  //$end

function ConvertTextElement (textobj) {
    //$module(ExportConverters.mss)
    obj = libmei.AnchoredText();

    text = ConvertSubstitution(textobj.Text);

    libmei.SetText(obj, text);

    if (textobj.Dx != 0)
    {
        libmei.AddAttribute(obj, 'ho', ConvertOffsetsToMEI(textobj.Dx));
    }

    if (textobj.Dy != 0)
    {
        libmei.AddAttribute(obj, 'vo', ConvertOffsetsToMEI(textobj.Dy));
    }

    return obj;
}  //$end

function ConvertFbFigures (fb, bobj) {
    //$module(ExportConverters)
    if (Self._property:FigbassCharMap = null)
    {
        Self._property:FigbassCharMap = InitFigbassCharMap();
    }
    if (Self._property:FigbassSmuflMap = null)
    {
        Self._property:FigbassSmuflMap = CreateDictionary();
    }
    figbassCharMap = Self._property:FigbassCharMap;
    figbassSmuflMap = Self._property:FigbassSmuflMap;

    n = 1;
    currentLine = '';
    altsym = null;
    components = bobj.TextWithFormatting;

    // Strangely, components.Length is null, so we can't use a for loop.
    // We want one more iteration than we have components, hence we start at
    // -1.
    i = -1;
    while ((i = -1) or (component != null))
    {
        i = i + 1;
        component = components[i];
        if ((component = null) or (component = '\\n\\'))
        {
            // We reached a linebreak or the last component
            if (currentLine != '')
            {
                f = libmei.F();
                libmei.SetText(f, currentLine);
                libmei.AddAttribute(f, 'n', n);
                libmei.AddChild(fb, f);
                if (altsym != null)
                {
                    libmei.AddAttribute(f, 'altsym', altsym);
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

function ConvertEndingValues (styleid) {
    //$module(ExportConverters)
    ending_style = MSplitString(styleid, '.');
    num = ' ';
    label = ' ';
    type = ' ';

    switch(ending_style[3])
    {
        case ('1st')
        {
            num = 1;
            label = '1.';
            type = 'closed';
        }
        case ('1st_n_2nd')
        {
            num = 1;
            label = '1. 2.';
            type = 'closed';
        }
        case ('2nd')
        {
            num = 2;
            label = '2.';
            if (ending_style[-1] = 'closed')
            {
                type = 'closed';
            }
            else
            {
                type = 'open';
            }
        }
        case ('3rd')
        {
            num = 3;
            label = '3.';
            type = 'closed';
        }
        case ('open')
        {
            type = 'open';
        }
        case ('closed')
        {
            type = 'closed';
        }
    }

    return CreateSparseArray(num, label, type);

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
    // Converts a timestamp in milliseconds to a
    // string suitable for use in @tstamp.ges
    t = time / 1000.0;
    return t & 's';
}  //$end


function ConvertSubstitution (string) {
    //$module(ExportConverters.mss)
    // if the string does not start with a substitution, send back the original string.
    if (Substring(string, 0, 2) != '\\$')
    {
        return string;
    }

    score = Self._property:ActiveScore;
    // it's 3 because of the two chars at the beginning, and then the last backslash.
    fieldname = Substring(string, 2, Length(string) - 3);

    switch (fieldname)
    {
        case ('Title')
        {
            return score.Title;
        }
        case ('Composer')
        {
            return score.Composer;
        }
        case ('Arranger')
        {
            return score.Arranger;
        }
        case ('Lyricist')
        {
            return score.Lyricist;
        }
        case ('MoreInfo')
        {
            return score.MoreInfo;
        }
        case ('Artist')
        {
            return score.Artist;
        }
        case ('Copyright')
        {
            return score.Copyright;
        }
        case ('Publisher')
        {
            return score.Publisher;
        }
        case ('PartName')
        {
            return score.PartName;
        }
    }

    // if it doesn't match anything, return the original string.
    return string;
}  //$end

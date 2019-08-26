function MSplitString (string, delimiter) {
    //$module(Utilities.mss)
    /*
        The default Splitstring method is buggy,
        so I've re-implemented it here.

        Delimiter is optional; if it is false, this will
        split the string into an array of characters.
    */
    ret = CreateSparseArray();
    pos = 0;
    // If there is no delimiter, split the string
    // into an array of characters.
    if (delimiter = false)
    {
        for i = 0 to Length(string)
        {
            ret.Push(Substring(string, i, 1));
        }
        return ret;
    }

    for i = 0 to Length(string) + 1
    {
        if (utils.CharAt(string, i) = delimiter)
        {
            ret.Push(Substring(string, pos, i - pos));
            pos = i + 1;
        }

        if (i = Length(string))
        {
            ret.Push(Substring(string, pos, Length(string) - pos));
        }
    }
    return ret;
}  //$end

function PrevPow2 (val) {
    //$module(Utilities.mss)
    if (val = 0)
    {
        return 0;
    }
    //val = val - 1;
    val = utils.bwOR(val, utils.shr(val, 1));
    val = utils.bwOR(val, utils.shr(val, 2));
    val = utils.bwOR(val, utils.shr(val, 4));
    val = utils.bwOR(val, utils.shr(val, 8));
    val = utils.bwOR(val, utils.shr(val, 16));
    // this might be a hack, but I wrote it in
    // a power outage with no internet.
    // we get the next power of two, and then
    // divide by two to get the previous one.
    val = (val + 1) / 2;
    return val;
}  //$end

function SimpleNoteHash (nobj) {
    //$module(Utilities.mss)
    /*
        Generate a simple note hash. Not guaranteed to be unique given
        any suitably large sample of notes, but should be unique enough for quick
        checks.
    */
    pos = nobj.ParentNoteRest.Position;
    pitch = nobj.Pitch;
    duration = nobj.Duration;
    voice = nobj.VoiceNumber;
    name = nobj.Name;
    parent_bar_number = nobj.ParentNoteRest.ParentBar.BarNumber;
    parent_staff_number = nobj.ParentNoteRest.ParentBar.ParentStaff.StaffNum;
    time = nobj.ParentNoteRest.Time;

    hash = '' & pos & '-' & pitch & '-' & duration & '-' & voice & '-' & name & '-' & parent_bar_number & '-' & parent_staff_number & '-' & time;

    return hash;

}  //$end

function LayerHash (barInfo, voiceInfo) {
    //$module(Utilities.mss)
    // `barInfo` is either a bar number or a `Bar` object.
    // `voiceInfo` is either a voice number or a `BarObject` from which the
    // `VoiceNumber` info would be used.
    // At least one of the two arguments must be an object.
    //
    // Calculates a numeric identifier from the implied bar number, voice number
    // and staff number.
    // `barInfo` is needed because we might either want the hash of the layer an
    // objects starts in, or the hash of the layer it ends in (where we'd supply
    // bobj.EndBarNumber).
    //
    // We call the generated number 'Layer'Hash because it is unique to each
    // MEI `<layer>` element that will aggregate all elements originating from a
    // specific staff, bar and voice.

    staff = null;
    if (IsObject(voiceInfo))
    {
        voiceNumber = voiceInfo.VoiceNumber;
        staff = voiceInfo.ParentBar.ParentStaff;
    }
    else
    {
        voiceNumber = voiceInfo;
    }

    if (IsObject(barInfo))
    {
        barNumber = barInfo.BarNumber;
        staff = barInfo.ParentStaff;
    }
    else
    {
        barNumber = barInfo;
    }
    if (staff = null) {
        Trace('At least one of the arguments to LayerHash() must be an object');
        ExitPlugin();
    }

    hash = staff.StaffNum;
    // For each addition, we multiply by the maximum value to make enough space
    // in the 'lower digits' so that the hash actually is unique and we could
    // in principle invert the calculation.
    hash = (staff.BarCount + 1) * hash + barNumber;
    hash = 5 * hash + voiceNumber;
    return hash;
}  //$end

function PushToHashedLayer (hashedLayers, bar, bobj) {
    //$module(Utilities.mss)
    // hashedLayers is a SparseArray where indices are hashes for layers
    // calculated by LayerHash(). Under each hash, there is a SparseArray where
    // objects associated with the layer can be added by this function.
    // Argument `bar` can be either a bar number or a Bar object.
    hash = LayerHash(bar, bobj);
    layerArray = hashedLayers[hash];
    if (layerArray = null)
    {
        layerArray = CreateSparseArray();
        hashedLayers[hash] = layerArray;
    }
    layerArray.Push(bobj);
}  //$end

function GetNoteObjectAtEndPosition (bobj) {
    //$module(Utilities.mss)
    // takes a bar object, and returns the NoteRest object closest to the end position.
    // If one isn't found exactly at the end position, it will first look back (previous)
    // and then look forward, for candidate objects.
    // NB: This will probably only work for line objects, since they are the only ones with the EndPosition attribute.
    // Returns the MEI element closest to that position.

    objectPositions = Self._property:ObjectPositions;
    staff_num = bobj.ParentBar.ParentStaff.StaffNum;
    // bar_num = bobj.ParentBar.BarNumber;
    bar_num = bobj.EndBarNumber;
    Log('bar_num: ' & bar_num);
    voice_num = bobj.VoiceNumber;

    staffObjectPositions = objectPositions[staff_num];
    barObjectPositions = staffObjectPositions[bar_num];
    if (barObjectPositions = null) {
        // TODO: We have a line that continues into a 'future' bar. Track these
        // lines and add IDs when we've reached the end NoteRest and know its ID
        return null;
    }
    voiceObjectPositions = barObjectPositions[voice_num];

    if (voiceObjectPositions = null)
    {
        // theres not much we can do here. Bail.
        Log('Bailing due to insufficient voice information');
        return null;
    }

    if (voiceObjectPositions.PropertyExists(bobj.EndPosition))
    {
        obj_id = voiceObjectPositions[bobj.EndPosition];
        obj = libmei.getElementById(obj_id);
        return obj;
    }
    else
    {
        // if we can't find anything at this position,
        // find the previous and subsequent objects, and align the
        // lyrics with them.
        prev_obj = bobj.PreviousItem(voice_num, 'NoteRest');

        if (prev_obj != null)
        {
            // there should be an object registered here
            obj_id = voiceObjectPositions[prev_obj.Position];
            obj = libmei.getElementById(obj_id);
            return obj;
        }
        else
        {
            next_obj = bobj.NextItem(voice_num, 'NoteRest');

            if (next_obj != null)
            {
                obj_id = voiceObjectPositions[next_obj.Position];
                obj = libmei.getElementById(obj_id);
                return obj;
            }
        }
    }

    return null;
} //$end


function GetNoteObjectAtPosition (bobj) {
    //$module(Utilities.mss)
    // takes a bar object, and returns the NoteRest object closest to its position.
    // If one isn't found exactly at the end position, it will first look back (previous)
    // and then look forward, for candidate objects.

    objectPositions = Self._property:ObjectPositions;
    staff_num = bobj.ParentBar.ParentStaff.StaffNum;
    bar_num = bobj.ParentBar.BarNumber;
    voice_num = bobj.VoiceNumber;

    staffObjectPositions = objectPositions[staff_num];
    barObjectPositions = staffObjectPositions[bar_num];
    voiceObjectPositions = barObjectPositions[voice_num];

    if (voiceObjectPositions = null)
    {
        // theres not much we can do here. Bail.
        Log('Bailing due to insufficient voice information');
        return null;
    }

    if (voiceObjectPositions.PropertyExists(bobj.Position))
    {
        obj_id = voiceObjectPositions[bobj.Position];
        obj = libmei.getElementById(obj_id);
        return obj;
    }
    else
    {
        // if we can't find anything at this position,
        // find the previous and subsequent objects, and align the
        // lyrics with them.
        next_obj = bobj.NextItem(voice_num, 'NoteRest');

        if (next_obj != null)
        {
            obj_id = voiceObjectPositions[next_obj.Position];
            obj = libmei.getElementById(obj_id);
            return obj;
        }
        else
        {
            prev_obj = bobj.PreviousItem(voice_num, 'NoteRest');

            if (prev_obj != null)
            {
                // there should be an object registered here
                obj_id = voiceObjectPositions[prev_obj.Position];
                obj = libmei.getElementById(obj_id);
                return obj;
            }
        }
    }

    return null;
}  //$end

function AddBarObjectInfoToElement (bobj, element) {
    //$module(Utilities.mss)
    /*
        adds timing and position info (tstamps, etc.) to an element.
        This info is mostly derived from the base BarObject class.
    */
    voicenum = bobj.VoiceNumber;
    bar = bobj.ParentBar;

    if (voicenum = 0)
    {
        // assign it to the first voice, since we don't have any notes in voice/layer 0.
        voicenum = 1;
        warnings = Self._property:warnings;
        warnings.Push(utils.Format(_ObjectAssignedToAllVoicesWarning, bar.BarNumber, voicenum, 'Bar object'));
    }

    if (bobj.Type = 'Line')
    {
        // lines have durations, but symbols do not.
        if (bobj.Duration > 0)
        {
            libmei.AddAttribute(element, 'dur.ges', bobj.Duration & 'p');
        }
    }

    libmei.AddAttribute(element, 'tstamp', ConvertPositionToTimestamp(bobj.Position, bar));

    switch (bobj.Type)
    {
        case('Line')
        {
            libmei.AddAttribute(element, 'tstamp2', ConvertPositionWithDurationToTimestamp(bobj));
        }
        case('Slur')
        {
            libmei.AddAttribute(element, 'tstamp2', ConvertPositionWithDurationToTimestamp(bobj));
            start_obj = GetNoteObjectAtPosition(bobj);
            if (start_obj != null)
            {
                libmei.AddAttribute(element, 'startid', '#' & start_obj._id);
            }
        }
        case('DiminuendoLine')
        {
            libmei.AddAttribute(element, 'tstamp2', ConvertPositionWithDurationToTimestamp(bobj));
        }
        case('CrescendoLine')
        {
            libmei.AddAttribute(element, 'tstamp2', ConvertPositionWithDurationToTimestamp(bobj));
        }
        case('GlissandoLine')
        {
            libmei.AddAttribute(element, 'tstamp2', ConvertPositionWithDurationToTimestamp(bobj));
        }
        case('Trill')
        {
            libmei.AddAttribute(element, 'tstamp2', ConvertPositionWithDurationToTimestamp(bobj));
        }
        case('SymbolItem')
        {
            start_obj = GetNoteObjectAtPosition(bobj);
            if (start_obj != null)
            {
                libmei.AddAttribute(element, 'startid', '#' & start_obj._id);
            }
        }
    }

    libmei.AddAttribute(element, 'staff', bar.ParentStaff.StaffNum);
    libmei.AddAttribute(element, 'layer', voicenum);

    if (bobj.Dx > 0)
    {
        libmei.AddAttribute(element, 'ho', ConvertOffsetsToMillimeters(bobj.Dx));
    }

    if (bobj.Dy > 0)
    {
        libmei.AddAttribute(element, 'vo', ConvertOffsetsToMillimeters(bobj.Dy));
    }

    return element;

}  //$end

function TupletsEqual (t, t2) {
    //$module(Utilities.mss)

    // shamelessly copied from the built-in tuplet plugin.
    tIsBar = (t = null) or (t.Type = 'Bar');
    t2IsBar = (t2 = null) or (t2.Type = 'Bar');

    if( tIsBar and t2IsBar ) { return true; }
    if( tIsBar or t2IsBar ) { return false; }

    b = t.ParentBar;
    b2 = t2.ParentBar;

    if( b.BarNumber != b2.BarNumber ) { return false; }
    if( b.ParentStaff.StaffNum != b2.ParentStaff.StaffNum ) { return 0; }
    if( t.VoiceNumber != t2.VoiceNumber ) { return false; }

    if( t.Position != t2.Position ) { return false; }
    if( t.PlayedDuration != t2.PlayedDuration ) { return false; }

    return true;

}  //$end

function GetTupletStack (bobj) {
    //$module(Utilities.mss)
    tupletStack = CreateSparseArray();
    parentTuplet = bobj.ParentTupletIfAny;
    while (parentTuplet != null)
    {
        tupletStack.Push(parentTuplet);
        parentTuplet = parentTuplet.ParentTupletIfAny;
    }
    tupletStack.Reverse();
    return tupletStack;
}  //$end

function CountTupletsEndingAtNoteRest(noteRest) {
    //$module(Utilities.mss)
    tuplet = noteRest.ParentTupletIfAny;

    if (tuplet = null)
    {
        return 0;
    }

    nextNoteRest = noteRest.NextItem(noteRest.VoiceNumber, 'NoteRest');

    if (nextNoteRest = null or nextNoteRest.ParentTupletIfAny = null)
    {
        tupletStack = GetTupletStack(noteRest);
        return tupletStack.Length;
    }

    if (TupletsEqual(tuplet, nextNoteRest.ParentTupletIfAny))
    {
        return 0;
    }

    tupletStack = GetTupletStack(noteRest);
    nextTupletStack = GetTupletStack(nextNoteRest);

    // We are looking for the highest index where both stacks are identical.
    index = utils.min(tupletStack.Length, nextTupletStack.Length) - 1;

    while (index >= 0 and not(TupletsEqual(tupletStack[index], nextTupletStack[index])))
    {
        index = index - 1;
    }

    return tupletStack.Length - 1 - index;
}  //$end

function GetMeiTupletDepth (layer) {
    //$module(Utilities.mss)
    depth = 0;
    tuplet = layer._property:ActiveMeiTuplet;
    while (tuplet != null)
    {
        depth = depth + 1;
        tuplet = tuplet._property:ParentTuplet;
    }
    return depth;
}  //$end

function lstrip (str) {
    //$module(Utilities.mss)
    if (utils.CharAt(str, 0) = ' ')
    {
        return Substring(str, 1);
    }
    else
    {
        return str;
    }
}  //$end

function rstrip (str) {
    //$module(Utilities.mss)
    if (utils.CharAt(str, Length(str) - 1) = ' ')
    {
        return Substring(str, 0, Length(str) - 1);
    }
    else
    {
        return str;
    }
}  //$end

function Log (message) {
    //$module(Utilities.mss)
    Sibelius.AppendLineToFile(Self._property:Logfile, message, True);
}  //$end

function NormalizedBeamProp (noteRest) {
    //$module(Utilities.mss)
    /*
        Sibelius' Beam properties can't be trusted. We need to look at the context,
        check whether they make sense and if they don't, find out the value we'd expect.
        Problems can e.g. be that Sibelius reports
         * a ContinueBeam at the start of a beam (we'd expect StartBeam)
         * a property other than NoBeam on a quarter or longer un-beamable duration
           (we'd expect NoBeam)
         * ... (almost any combinations imaginable)
    */
    if (noteRest.Beam = NoBeam or noteRest.Duration >= 256)
    {
        return NoBeam;
    }

    // At this point, we're only dealing with ContinueBeam and SingleBeam.
    // We need to look at the preceding note to see whether there's any
    // beam to continue.

    if (noteRest.Beam != StartBeam)
    {
        prev_obj = PrevNormalOrGrace(noteRest, noteRest.GraceNote);

        if (prev_obj != null and prev_obj.Beam != NoBeam and prev_obj.Duration < 256)
        {
            // We actually have a beam we can continue.
            if (noteRest.Beam = SingleBeam and noteRest.Duration < 128 and prev_obj.Duration < 128)
            {
                // SingleBeam only makes sense if we actually have secondary beams between the
                // previous note and the current note.
                return SingleBeam;
            }
            return ContinueBeam;
        }
    }

    // At this point, we know there is no previous beam we can continue because we have a
    // StartBeam or the above test for a previous beam failed.
    // We still need to check whether there is a following note that we can beam to.

    next_obj = NextNormalOrGrace(noteRest, noteRest.GraceNote);
    if (next_obj != null and next_obj.Duration < 256 and (next_obj.Beam = ContinueBeam or next_obj.Beam = SingleBeam))
    {
        return StartBeam;
    }
    else
    {
        return NoBeam;
    }
}  //$end

function NextNormalOrGrace (noteRest, grace) {
    //$module(Utilities.mss)
    /*
        When given a 'normal' NoteRest, this function returns the next 'normal' NoteRest
        in the same voice.
        When given a grace NoteRest, this function returns the immediately adjacent
        following grace NoteRest, if existant.
        This function is basically a duplicate of PrevNormalOrGrace() with
        'Previous' replaced by 'Next'.
    */
    next_obj = noteRest.NextItem(noteRest.VoiceNumber, 'NoteRest');
    if (grace)
    {
        // There mustn't be any intermitting 'normal' notes between grace notes.
        if (next_obj != null and not(next_obj.GraceNote))
        {
            next_obj = null;
        }
    }
    else
    {
        // If noteRest isn't a grace note, we skip all grace notes as their beams
        // can be nested inside normal beams.
        while (next_obj != null and next_obj.GraceNote)
        {
            next_obj = next_obj.NextItem(noteRest.VoiceNumber, 'NoteRest');
        }
    }
    return next_obj;
}  //$end

function PrevNormalOrGrace (noteRest, grace) {
    //$module(Utilities.mss)
    /*
        For a description, see NextNormalOrGrace().
        This function is basically a duplicate of PrevNormalOrGrace() with
        'Next' replaced by 'Previous'.
    */
    prev_obj = noteRest.PreviousItem(noteRest.VoiceNumber, 'NoteRest');
    if (grace)
    {
        // There mustn't be any intermitting 'normal' notes between grace notes.
        if (prev_obj != null and not(prev_obj.GraceNote))
        {
            prev_obj = null;
        }
    }
    else
    {
        // If noteRest isn't a grace note, we skip all grace notes as their beams
        // can be nested inside normal beams.
        while (prev_obj and prev_obj.GraceNote)
        {
            prev_obj = prev_obj.NextItem(noteRest.VoiceNumber, 'NoteRest');
        }
    }
    return prev_obj;
}  //$end

function GetNongraceParentBeam (noteRest, layer) {
    //$module(Utilities.mss)
    /*
       This function is used to find out whether a non-grace beam spans over a grace
       NoteRest that is either unbeamed or at the start of a grace beam.
    */
    if (layer._property:ActiveBeam != null)
    {
        // Only if the active non-grace beam continues to the next normal note, the
        // grace note is truly placed under the non-grace beam.
        nextNongraceNoteRest = NextNormalOrGrace(noteRest, false);
        if (nextNongraceNoteRest != null)
        {
            nextNormalBeamProp = NormalizedBeamProp(nextNongraceNoteRest);
        }
        else
        {
            nextNormalBeamProp = NoBeam;
        }
        if (nextNormalBeamProp = ContinueBeam or nextNormalBeamProp = SingleBeam)
        {
            return layer._property:ActiveBeam;
        }
    }
    return null;
}  //$end

function GetTempDir () {
    //$module(Utilities.mss)
    if (Sibelius.PathSeparator = '/')
    {
        tempFolder = '/tmp/';
    }
    else
    {
        appDataFolder = Sibelius.GetUserApplicationDataFolder();
        // appDataFolder usually looks like C:\Users\{username}\AppData\Roaming\
        // We strip the trailing bit until the second to last backslash
        i = Length(appDataFolder) - 2;
        while (i >= 0 and CharAt(appDataFolder, i) != '\\')
        {
            i = i - 1;
        }
        // tempFolder usually looks like C:\Users\USERNAME\AppData\Local\Temp\
        // So we replace the trailing 'Roaming' with 'Local\Temp'
        tempFolder = Substring(appDataFolder, 0, i) & '\\Local\\Temp\\';
    }
    if (Sibelius.FolderExists(tempFolder))
    {
        return tempFolder;
    }
}  //$end

function InitFigbassCharMap () {
    //$module(Utilities.mss)
    map = CreateDictionary(
        '§', '♮',
        '#', '♯',
        '!', '♭',
        '?', '𝄪',
        '%', '𝄫',
        'a', '(2)',
        'i', '[2]',
        'w', '2♮',
        's', '2♯',
        'x', '2♭',
        'W', '♮2',
        'S', '♯2',
        'X', '♭2',
        'k', '2+',
        'p', '(3)',
        'q', '[3]',
        'e', '3♮',
        'd', '3♯',
        'c', '3♭',
        'E', '♮3',
        'D', '♯3',
        'C', '♭3',
        'z', '3+',
        'A', '(4)',
        'I', '[4]',
        'r', '4♮',
        'f', '4♯',
        'v', '4♭',
        'R', '♮4',
        'F', '♯4',
        'V', '♭4',
        'K', '4+',
        'P', '(5)',
        'Q', '[5]',
        't', '5♮',
        'g', '5♯',
        'b', '5♭',
        'T', '♮5',
        'G', '♯5',
        'B', '♭5',
        'Z', '5+',
        '$', '(6)',
        '¨', '[6]',
        'y', '6♮',
        'h', '6♯',
        'n', '6♭',
        'Y', '♮6',
        'H', '♯6',
        'N', '♭6',
        ',', '6+',
        'Â', '(7)',
        ';', '[7]',
        'u', '7♮',
        'j', '7♯',
        'm', '7♭',
        'U', '♮7',
        'J', '♯7',
        'M', '♭7',
        '<', '7+',
        '>', '+7',
        '=', '(8)',
        'Ö', '[8]',
        'À', '(9)',
        '{', '[9]',
        'o', '9♮',
        'l', '9♯',
        'ë', '9♭',
        'O', '♮9',
        'L', '♯9',
        ':', '♭9',
        '}', '9+',
        'Å', '|',
        'ü', '_',
        '©', CreateSparseArray('2♯', 'U+EA53', 'figbass2Raised' ), // 2 with slashed foot
        'Ä', CreateSparseArray('4♯', 'U+EA56', 'figbass4Raised' ), // 4 with slashed horizontal line
        'Ë', CreateSparseArray('5♯', 'U+EA58', 'figbass5Raised1'), // 5 with straight slash through head
        'Ï', CreateSparseArray('5♯', 'U+EA59', 'figbass5Raised2'), // 5 with angled slash through head
        'ï', CreateSparseArray('5♯', 'U+EA5A', 'figbass5Raised3'), // 5 with slashed foot
        '´', CreateSparseArray('6♯', 'U+EA6F', 'figbass6Raised' ), // 6 with slashed head
        'ä', CreateSparseArray('7♯', 'U+EA5E', 'figbass7Raised1'), // 7 with slashed head
        '&', CreateSparseArray('7♯', 'U+EA5F', 'figbass8Raised2'), // 7 with slashed stem
        // (Sibelius/Opus and SMuFL/Bravura don't match 100% for the slashed 9:
        // Opus slashes the stem, Bravura the head)
        'ö', CreateSparseArray('9#', 'U+EA62', 'figbass9Raised')   // slashed 9
    );
    literalChars = '0123456789[]_-+.';
    for i = 0 to Length(literalChars)
    {
        char = CharAt(literalChars, i);
        map[char] = char;
    }

    return map;
}  //$end

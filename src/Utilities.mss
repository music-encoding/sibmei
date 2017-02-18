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

function GetNoteObjectAtPosition (bobj) {
    //$module(Utilities.mss)
    // takes a dictionary of {pos:id} mappings for a given
    // voice, and returns the NoteRest object. If one isn't found
    // exactly at `position`, it will first look back (previous)
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
}  //$end

function AddBarObjectInfoToElement (bobj, element) {
    //$module(Utilities.mss)
    /*
        adds timing and position info (startids, endids, tstamps, etc.) to an element
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
        return GetSibTupletDepth(noteRest);
    }
    
    if (TupletsEqual(tuplet, nextNoteRest.ParentTupletIfAny))
    {
        return 0;
    }
    
    tupletDepth = GetSibTupletDepth(noteRest);
    nextTupletDepth = GetSibTupletDepth(nextNoteRest);
    nextTuplet = nextNoteRest.ParentTupletIfAny;
    numberOfEndingTuplets = 0;
    
    // We need to check to which depth the tuplets are equal.
    // First of all, we have to make sure we are starting at the same depth if
    // depths are note equal.
    if (tupletDepth > nextTupletDepth)
    {
        for i = nextTupletDepth to tupletDepth
        {
            tuplet = tuplet.ParentTupletIfAny;
        }
        numberOfEndingTuplets = tupletDepth - nextTupletDepth;
    }
    else
    {
        for i = tupletDepth to nextTupletDepth
        {
            nextTuplet = nextTuplet.ParentTupletIfAny;
        }
    }
    
    // We are looking for the highest index where both stacks are identical.
    while ((tuplet != null) and not(TupletsEqual(tuplet, nextTuplet)))
    {
        numberOfEndingTuplets = numberOfEndingTuplets + 1;
        tuplet = tuplet.ParentTupletIfAny;
        nextTuplet = nextTuplet.ParentTupletIfAny;
    }
    
    return numberOfEndingTuplets;
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

function GetSibTupletDepth (noteRest) {
    //$module(Utilities.mss)
    depth = 0;
    tuplet = noteRest.ParentTupletIfAny;
    while (tuplet != null)
    {
        depth = depth + 1;
        tuplet = tuplet.ParentTupletIfAny;
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
    Sibelius.AppendLineToFile(LOGFILE, message, True);
}  //$end
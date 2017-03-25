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
    position = bobj.Position;

    staffObjectPositions = objectPositions[staff_num];
    barObjectPositions = staffObjectPositions[bar_num];
    voiceObjectPositions = barObjectPositions[voice_num];

    if (voiceObjectPositions = null)
    {
        // theres not much we can do here. Bail.
        Log('Bailing due to insufficient voice information');
        return null;
    }

    if (voiceObjectPositions.PropertyExists(position))
    {
        obj_id = voiceObjectPositions[position];
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
        adds timing and position info (startids, endids, tstamps, etc.) to an element.
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

    libmei.AddAttribute(element, 'tstamp', ConvertPositionToTimestamp(bobj.Position, bar));
    libmei.AddAttribute(element, 'staff', bar.ParentStaff.StaffNum);
    libmei.AddAttribute(element, 'layer', voicenum);

    startNote = GetNoteObjectAtPosition(bobj);
    if (startNote != null)
    {
        libmei.AddAttribute(element, 'startid', '#' & startNote._id);
    }

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
    while (tuplet)
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
    Sibelius.AppendLineToFile(LOGFILE, message, True);
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

function SpannerAppliesToBobj (spanner, bobj) {
    //$module(Utilities.mss)
    spannerVoiceNum = spanner.VoiceNumber;
    if ((spannerVoiceNum != 0) and (spannerVoiceNum != bobj.VoiceNumber))
    {
        return false;
    }
    bobjBar = bobj.ParentBar;
    bobjBarNum = bobjBar.BarNumber;
    startBar = spanner.ParentBar;
    startBarNum = startBar.BarNumber;
    endBarNum = spanner.EndBarNumber;
    if ((bobjBarNum > endBarNum) or (bobjBarNum < startBarNum)) 
    {
        return false;
    }
    bobjStaff = bobjBar.ParentStaff;
    spannerStaff = startBar.ParentStaff;
    if (bobjStaff.StaffNum != spannerStaff.StaffNum)
    {
        return false;
    }
    
    startPos = spanner.Position;
    bobjPos = bobj.Position;
    if ((bobjBarNum = startBarNum) and (bobjPos < startPos))
    {
        return false;
    }

    if (bobjBarNum = endBarNum)
    {
        endPos = NormalizedEndPosition(spanner);

        if (bobj.Type = 'OctavaLine') 
        {
            // Sibelius does not consider a note at the EndPosition of an
            // ottava line to be part of the ottava. This becomes clear
            //  * when creating an ottava for a single note (will stretch
            //    until the Position of the next note - and visually beyond)
            //  * when exporting MIDI (the note at the EndPosition will not
            //    be transposed)
            // Other lines might behave similarly and will have to be added.
            appliesToEndPosition = false;
        }
        else
        {
            appliesToEndPosition = true;
        }

        if (appliesToEndPosition)
        {
            return bobjPos < endPos;
        }
        else
        {
            return bobjPos <= endPos;
        }
    }
    return true;
}  //$end

function NormalizedEndPosition (bobj) {
    //$module(Utilities.mss)
    /*
      When spanners like octava lines are spanning until the end of a 
      measure, they by default get their EndBarNumber set to the next 
      bar and EndPosition set to 0.  However, if they end at the end of
      the last bar, EndBarNumber is set to this last bar and 
      EndPosition is set to 0, i.e. it looks as if it ended at the
      beginning, not the end, of the last measure.

      To tell apart whether a spanner ends at the beginning or the end
      of the last measure, we also need to take into account Duration.
      If Duration indicates that the spanner continues to the end of
      the measure, we return the Length of the measure as EndPosition,
      e.g. 1024 in 4/4 time. Sibelius would never return this value
      (it would use values from 0 to 1023), but this value is very
      sensible when calculating a @tstamp2 in MEI. (1024 in 4/4 would
      translate to the 5th beat, which in MEI means attachment to the
      ending barline.)
    */
    endPosition = bobj.EndPosition;
    if (endPosition = 0)
    {
        bar = bobj.ParentBar;
        staff = bar.ParentStaff;
        barCount = staff.BarCount;
        if (bobj.EndBarNumber = barCount)
        {
            if (bar.BarNumber = barCount)
            {
                return bobj.Duration;
            }
            else
            {
                durationSum = bar.Length - bobj.Position;
                for n = bar.BarNumber + 1 to barCount
                {
                    nthBar = staff.NthBar(n);
                    durationSum = durationSum + nthBar.Length;
                }
                if (bobj.Duration > durationSum)
                {
                    bar = staff.NthBar(barCount);
                    return bar.Length;
                }
            }
        }
    }
    return endPosition;
}  //$end

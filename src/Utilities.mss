function MSplitString (string, delimiter) {
    //$module(Utilities.mss)
    /*
        The default SplitString method returns a TreeNode Array which is hard
        to handle and can lead to Sibelius crashes.  This is a more friendly
        wrapper that returns a SparseArray instead.
    */
    return SplitString(string, delimiter).ConvertToSparseArray();
}  //$end


function SplitStringIncludeDelimiters (string, delimiters) {
    //$module(Utilities.mss)
    /*
        This function is useful if a string should be split at more than one
        delimiter, but the delimiter should be preserved to know at which
        delimiter we split.  Example:

          result = SplitStringIncludeDelimiters('foo-bar baz', '- ');
          Trace(result); // =>  ['foo', '-', 'bar', ' ', 'baz']

        Multiple delimiter chars of the same kind are treated as just one
        delimiter, i.e. 'foo  bar' would be split in the same fashion as
        'foo bar' with just one space.
    */
    components = SplitString(string, delimiters);
    if (components.NumChildren = 1)
    {
        return CreateSparseArray(string);
    }

    ret = CreateSparseArray();
    delimiterIndex = -1;
    previousDelimiter = '';
    for each component in components
    {
        delimiterIndex = delimiterIndex + Length(component) + 1;
        delimiter = Substring(string, delimiterIndex, 1);
        if (component != '' or delimiter != previousDelimiter)
        {
            // `component` is a TreeNode that we convert to a string with `& ''`
            ret.Push(component & '');
            ret.Push(delimiter);
        }
        previousDelimiter = delimiter;
    }

    // In the loop, we push the component and the following delimiter, but
    // there is no delimiter following the last component, so we remove the last
    // item again (which is always an empty string).
    ret.Pop();

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


function GetNoteObjectAtPosition (bobj, searchStrategy, positionProperty) {
    //$module(Utilities.mss)
    // takes a bar object, and returns the MEI element generated from the
    // NoteRest object closest to `bobj`'s position, in the same voice as
    // `bobj`. If `bobj` is in voice 0, `null` will be returned.
    // For line-like objects, parameter `position` must be supplied and be
    // either `Position` or `EndPosition`. For all other objects, this
    // parameter is not used and should be omitted.
    // If no NoteRest is found exactly at the position, the defined
    // `searchStrategy` is used to find another NoteRest and may be one of the
    // the following strings: `PreciseMatch`, `Next`, `Previous` or `Closest`.

    objectPositions = Self._property:NoteRestIdsByLocation;
    if (bobj.IsALine and positionProperty = 'EndPosition')
    {
        bobjPosition = bobj.EndPosition;
        noteIdsByPosition = objectPositions[LayerHash(bobj.EndBarNumber, bobj)];
    }
    else
    {
        noteIdsByPosition = objectPositions[LayerHash(bobj.ParentBar, bobj)];
        bobjPosition = bobj.Position;
    }

    if (null = noteIdsByPosition)
    {
        return null;
    }

    objId = noteIdsByPosition[bobjPosition];
    if (null != objId)
    {
        return libmei.getElementById(objId);
    }

    // `bobj` was not precisely attached to a NoteRest in the same voice.
    if (searchStrategy = 'PreciseMatch')
    {
        return null;
    }

    // Try and find the best matching note according to the `searchStrategy`.
    noteRestPositions = noteIdsByPosition.ValidIndices;

    for noteRestIndex = noteRestPositions.Length- 1 to -1 step -1 {
        if (noteRestPositions[noteRestIndex] < bobjPosition)
        {
            // We found the closest preceding and following positions
            return GetClosestNoteObject(
                noteIdsByPosition,
                bobjPosition,
                noteRestPositions[noteRestIndex],
                noteRestPositions[noteRestIndex + 1],
                searchStrategy
            );
        }
    }

    // We did not find a preceding position
    return GetClosestNoteObject(
        noteIdsByPosition, bobjPosition, null, noteRestPositions[0], searchStrategy
    );
}  //$end


function GetClosestNoteObject (noteIdsByPosition, position, precedingPosition, followingPosition, searchStrategy) {
    switch (true)
    {
        case (searchStrategy = 'Next')
        {
            noteRestPosition = followingPosition;
        }
        case (searchStrategy = 'Previous')
        {
            noteRestPosition = precedingPosition;
        }
        case (searchStrategy != 'Closest')
        {
            Trace('\'' & searchStrategy & '\' is not an accepted value for parameter `searchStrategy`');
            ExitPlugin();
        }
        // `'' = x` is testig if x is null. We can not use `x = null` or
        // `null = x` because both expressions are truthy if `x` is 0. We can't
        // use `x = ''` either for the same reason.
        case ('' = precedingPosition)
        {
            noteRestPosition = followingPosition;
        }
        case ('' = followingPosition)
        {
            noteRestPosition = precedingPosition;
        }
        case ((followingPosition - position) < (position - precedingPosition))
        {
            noteRestPosition = followingPosition;
        }
        default
        {
            noteRestPosition = precedingPosition;
        }
    }

    if ('' = noteRestPosition)
    {
        return null;
    }

    return libmei.getElementById(noteIdsByPosition[noteRestPosition]);
} //$end


function GetMeiNoteRestAtPosition (bobj, endPosition) {
    // Returns the MEI element generated from a NoteRest at the start or end
    // position of `bobj`, depending on whether `endPosition` is true or false.

    if (endPosition)
    {
        layerHash = LayerHash(bobj.EndBarNumber, bobj);
        position = bobj.EndPosition;
    }
    else
    {
        layerHash = LayerHash(bobj.ParentBar, bobj);
        position = bobj.Position;
    }

    noteRestIdsByPosition = NoteRestIdsByLocation[layerHash];

    if (null = noteRestIdsByPosition)
    {
        return null;
    }

    id = noteRestIdsByPosition[position];

    if (null != id)
    {
        return libmei.getElementById(id);
    }

    // If there is no NoteRest at the precise position, linearly search the
    // NoteRests in this layer for the closest position.
    noteRestPositions = noteRestIdsByPosition.ValidIndices;

    for i = 0 to noteRestPositions.Length
    {
        if (noteRestPositions[i] > position)
        {
            // If the preceding position was closer, use that one
            if (
                (i > 0)
                and (position - noteRestPositions[i - 1] < noteRestPositions[i] - position)
            )
            {
                i = i - 1;
            }
            id = noteRestIdsByPosition[noteRestPositions[i]];
            return libmei.getElementById(id);
        }
    }

    return null;
} //$end


function RegisterNoteRestIdByLocation (noteRest, id) {
    //$module(Utilities.mss)
    /**
     * Registers the NoteRest's id in the global NoteRestIdsByLocation object
     * that is used by GetMeiNoteRestAtPosition() to retrieve MEI objects that
     * other objects are attached to.
     */

    layerHash = LayerHash(noteRest.ParentBar, noteRest);
    noteIdsByPosition = NoteRestIdsByLocation[layerHash];
    if (null = noteIdsByPosition)
    {
        noteIdsByPosition = CreateSparseArray();
        NoteRestIdsByLocation[layerHash] = noteIdsByPosition;
    }
    noteIdsByPosition[noteRest.Position] = id;
}  //$end


function AddControlEventAttributes (bobj, element) {
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

    if (not element.attrs.PropertyExists('tstamp'))
    {
        // Some templates might set `@tstamp` explicitly, especially to prevent
        // `@tstamp` from being output for elements that don't allow it.
        libmei.AddAttribute(element, 'tstamp', ConvertPositionToTimestamp(bobj.Position, bar));
    }

    start_obj = GetNoteObjectAtPosition(bobj, 'PreciseMatch', 'Position');
    if (start_obj != null)
    {
        libmei.AddAttribute(element, 'startid', '#' & start_obj._id);
    }

    if (TypeHasEndBarNumberProperty[bobj.Type])
    {
        libmei.AddAttribute(element, 'tstamp2', ConvertPositionWithDurationToTimestamp(bobj));
    }

    staff = bar.ParentStaff;

    if (staff.StaffNum > 0)
    {
        // Only add @staff if this is not attached to the SystemStaff
        libmei.AddAttribute(element, 'staff', staff.StaffNum);
        libmei.AddAttribute(element, 'layer', voicenum);
    }

    score = staff.ParentScore;

    if (bobj.Type = 'Line')
    {
        // lines have durations, but symbols do not.
        if (bobj.Duration > 0)
        {
            libmei.AddAttribute(element, 'dur.ppq', bobj.Duration);
        }

        // lines have a left hand and a right hand offset
        // left hand offset
        if (bobj.Dx > 0)
        {
            libmei.AddAttribute(element, 'startho', ConvertOffsetsToMillimeters(bobj.Dx));
        }
        if (bobj.Dy > 0)
        {
            libmei.AddAttribute(element, 'startvo', ConvertOffsetsToMillimeters(bobj.Dy));
        }
        // right hand offset
        if (bobj.RhDx > 0)
        {
            libmei.AddAttribute(element, 'endho', ConvertOffsetsToMillimeters(bobj.Dx));
        }
        if (bobj.RhDy > 0)
        {
            libmei.AddAttribute(element, 'endvo', ConvertOffsetsToMillimeters(bobj.Dy));
        }
    }
    else
    {
        // other types only have a left hand offset
        if (bobj.Dx > 0)
        {
            libmei.AddAttribute(element, 'ho', ConvertOffsetsToMillimeters(bobj.Dx));
        }
    }

    if (bobj.Type != 'Text')
    {
        if (bobj.Color != 0)
        {
            libmei.AddAttribute(element, 'color', ConvertColor(bobj));
        }
    }

    return element;

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
        prev_obj = AdjacentNormalOrGrace(noteRest, noteRest.GraceNote, 'PreviousItem');

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

    next_obj = AdjacentNormalOrGrace(noteRest, noteRest.GraceNote, 'NextItem');
    if (next_obj != null and next_obj.Duration < 256 and (next_obj.Beam = ContinueBeam or next_obj.Beam = SingleBeam))
    {
        return StartBeam;
    }
    else
    {
        return NoBeam;
    }
}  //$end

function AdjacentNormalOrGrace (noteRest, grace, previousOrNext) {
    //$module(Utilities.mss)
    /*
        When given a 'normal' NoteRest, this function returns the next 'normal' NoteRest
        in the same voice.
        When given a grace NoteRest, this function returns the immediately adjacent
        following grace NoteRest, if existant.
    */
    next_obj = noteRest.@previousOrNext(noteRest.VoiceNumber, 'NoteRest');
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

function HasSingleVoice (bar) {
    //$module(Utilities.mss)

    // Returns true if the bar has at most one single voice

    voiceNum = -1;
    for each bobj in bar
    {
        if (voiceNum != bobj.VoiceNumber and (bobj.Type = 'NoteRest' or bobj.Type = 'BarRest'))
        {
            if (voiceNum > 0)
            {
                return false;
            }
            voiceNum = bobj.VoiceNumber;
        }
    }

    return true;
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
        nextNongraceNoteRest = AdjacentNormalOrGrace(noteRest, false, 'NextItem');
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


function MeiFactory (data, bobj) {
    // Parameter `data` is a template SparseArray with the following entries:
    //
    // 0. The capitalized tag name
    // 1. A dictionary with attribute names and values
    // 2., 3., ... Child nodes (optional) as strings (for text nodes) or as
    //    template SparseArrays (for child elements)
    //
    // For further documentation, see Extensions.md

    tagName = data[0];
    element = libmei.@tagName();

    attributes = data[1];
    if (null != attributes)
    {
        for each Name attName in attributes
        {
            libmei.AddAttribute(element, attName, attributes[attName]);
        }
    }

    if (data.Length > 2)
    {
        // Add children
        for i = 2 to data.Length
        {
            childData = data[i];
            switch (true)
            {
                case (not IsObject(childData))
                {
                    AppendText(element, childData);
                }
                case (null != childData._property:templateAction)
                {
                    childData.templateAction.action(element, bobj);
                }
                default
                {
                    // We have a child element
                    currentChild = MeiFactory(childData, bobj);
                    libmei.AddChild(element, currentChild);
                }
            }
        }
    }

    return element;
}  //$end


function SetTemplateAction (templateNode, plugin, functionName) {
    // Associates a template action Dictionary with the templateNode. When
    // MeiFactory() finds a descendant template that has an action Dictionary
    // as user property `templateAction`, it calls the Dictionary's action()
    // method to take over control instead of converting it to MEI itself.

    // `templateNode` can be a Dictionary that works as a placeholder, or it
    // can be an actual element template (a SparseArray) that the action method
    // can retrieve from the action Dictionary to work with it (e.g. pass it
    // back to MeiFactory() and then add more attributes dynamically, or only
    // pass it to MeiFactory() if certain conditions are met etc.).

    // Depending on what the function specified by `functionName` needs, either
    // the placholder or template form of `templateNode` should be chosen.
    templateNode._property:templateAction = CreateDictionary('templateNode', templateNode);
    templateNode.templateAction.SetMethod('action', plugin, functionName);
    return templateNode;
}  //$end


function GetTemplateElementsByTagName (template, tagName) {
    // Works basically like getElementsByTagName() in XML/HTML DOM

    elements = CreateSparseArray();

    if (template[0] = tagName)
    {
        elements.Push(template);
    }

    if (template.Length < 3)
    {
        return elements;
    }

    for childIndex = 2 to template.Length
    {
        childNode = template[childIndex];
        if (IsObject(childNode) and childNode[0] != '')
        {
            // The child node is an element template
            for each element in GetTemplateElementsByTagName(childNode, tagName)
            {
                elements.Push(element);
            }
        }
    }

    return elements;
}  //$end


function AppendText (element, text) {
    if (element.children.Length = 0)
    {
        libmei.SetText(element, element.text & text);
    }
    else
    {
        lastChildIndex = element.children.Length - 1;
        lastChild = libmei.getElementById(element.children[lastChildIndex]);
        lastChild.tail = lastChild.tail & text;
    }
}  //$end

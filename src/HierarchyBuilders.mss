function BuildLayerHierarchy (staffnum, measurenum) {
    score = Self._property:ActiveScore;
    this_staff = score.NthStaff(staffnum);
    bar = this_staff[measurenum];

    mobjs = Self._property:MeasureObjects;

    parentsByVoiceAndPosition = BuildNoteRestParentsByVoiceAndPosition(bar);
    activeGraceBeam = null;

    for each bobj in bar
    {
        switch (bobj.Type)
        {
            case('Clef')
            {
                // Clefs are always VoiceNumber 0. We have to include them in
                // all existing layers.
                firstClefId = '';

                for each voiceNumber in parentsByVoiceAndPosition.ValidIndices
                {
                    clef = GenerateClef(bobj);
                    if (firstClefId != '')
                    {
                        libmei.AddAttribute(clef, 'sameas', '#' & firstClefId);
                    }
                    else
                    {
                        firstClefId = clef._id;
                    }
                    precedingNoteRest = bobj.PreviousItem(voiceNumber, 'NoteRest');
                    parentsInVoice = parentsByVoiceAndPosition[voiceNumber];
                    container = parentsInVoice.layerInfo;
                    if (null != precedingNoteRest)
                    {
                        container = parentsInVoice[precedingNoteRest.Position];
                    }
                    while (
                        container.element.name != 'layer'
                        // If the clef is at the very end position of the
                        // container or beyond, the clef is not part of this
                        // container.
                        and bobj.Position > container.endPosition
                    )
                    {
                        container = container.parent;
                    }
                    libmei.AddChild(container.element, clef);
                }
            }
            case('NoteRest')
            {
                note = GenerateNoteRest(bobj);

                parentsInVoice = parentsByVoiceAndPosition[bobj.VoiceNumber];

                if (note != null)
                {
                    RegisterNoteRestIdByLocation(bobj, note._id);

                    normalizedBeamProp = NormalizedBeamProp(bobj);

                    if (normalizedBeamProp = SingleBeam)
                    {
                        if (bobj.GraceNote)
                        {
                            prevNote = parentsInVoice._property:PrevGraceNote;
                        }
                        else
                        {
                            prevNote = parentsInVoice._property:PrevNote;
                        }
                        // prevNote is not null here - unless we have a bug in NormalizeBeamProp()
                        // or the registration of previous notes.
                        libmei.AddAttribute(prevNote, 'breaksec', '1');
                    }

                    parentsInVoice = parentsByVoiceAndPosition[bobj.VoiceNumber];
                    container = parentsInVoice[bobj.Position];


                    if (not bobj.GraceNote)
                    {
                        parentsInVoice._property:PrevNote = note;
                    }
                    else
                    {
                        while (
                            container.element.name != 'layer'
                            // If the grace note is at the start position of the
                            // container (beam or tuplet), it is not part of this
                            // container. It needs to go before the container.
                            and bobj.Position <= container.position
                        )
                        {
                            container = container.parent;
                        }

                        switch (normalizedBeamProp)
                        {
                            case (NoBeam)
                            {
                                containerElement = container.element;
                            }
                            case (StartBeam)
                            {
                                containerElement = libmei.Beam();
                                libmei.AddChild(container.element, containerElement);
                                parentsInVoice._property:activeGraceBeam = containerElement;
                            }
                            default
                            {
                                containerElement = parentsInVoice._property:activeGraceBeam;
                            }
                        }

                        parentsInVoice._property:PrevGraceNote = note;
                    }

                    libmei.AddChild(container.element, note);

                    // We can only add the containers to the layer (or their
                    // respective parent) after all preceding siblings were
                    // added. When we reach the first NoteRest of a container,
                    // we have to add its container.
                    while (container.element.name != 'layer' and null = container.element._parent)
                    {
                        libmei.AddChild(container.parent.element, container.element);
                        container = container.parent;
                    }
                }


                if (bobj.ArpeggioType != ArpeggioTypeNone)
                {
                    arpeg = GenerateArpeggio(bobj);
                }
            }
            case('BarRest')
            {
                brest = GenerateBarRest(bobj);

                if (brest != null)
                {
                    layer = parentsByVoiceAndPosition[bobj.VoiceNumber].layerInfo.element;

                    libmei.AddChild(layer, brest);
                }
            }
        }
    }

    for each bobj in bar
    {
        switch (bobj.Type)
        {
            case('GuitarFrame')
            {
                GenerateChordSymbol(bobj);
            }
            case('Slur')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('CrescendoLine')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('DiminuendoLine')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('OctavaLine')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('GlissandoLine')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('Trill')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('ArpeggioLine')
            {
                GenerateArpeggio(bobj);
            }
            case('RepeatTimeLine')
            {
                RegisterVolta(bobj);
            }
            case('Line')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('Text')
            {
                HandleStyle(TextHandlers, bobj);
            }
            case('SymbolItem')
            {
                HandleSymbol(bobj);
            }
        }
    }

    for each LyricItem lobj in bar
    {
        HandleLyricItem(lobj);
    }

    ProcessEndingLines(bar);

    layers = CreateSparseArray();
    for each layerNumber in parentsByVoiceAndPosition.ValidIndices
    {
        parentsInVoice = parentsByVoiceAndPosition[layerNumber];
        layers.Push(parentsInVoice.layerInfo.element._id);
    }
    layers._property:beamSpans = parentsByVoiceAndPosition.beamSpans;
    return layers;
}  //$end


function BuildNoteRestParentsByVoiceAndPosition (bar) {
    // Pre-analyzes a measure and creates all container elements for notes,
    // rests, chords and clefs, and, crucially, establishes their hierarchy.
    // Container elements are <layer>, <beam> and <tuplet>, If beams and tuplets
    // can not be nested properly, <beamSpan>s are created.
    //
    // The returned `parentsByVoiceAndPosition` is a 2D SparseArray lookup table
    // where the innermost container element can be retrieved by any NoteRest's
    // VoiceNumber and Position. It has a user property `beamSpans`, which is a
    // SparseArray of all the generated <beamSpan>s that have to be appended to
    // <measure>.

    parentsByVoiceAndPosition = CreateSparseArray();
    parentsByVoiceAndPosition._property:beamSpans = CreateSparseArray();
    beamInfosByVoice = CreateSparseArray();

    // Associate NoteRests with either beams or layers. <beam> and <layer>
    // elements are generated as needed.
    for each NoteRest noteRest in bar
    {
        // Grace note beams are created on-the-fly later because we can have
        // multiple grace notes with the same Position, which would not allow us
        // to look up grace note beams by the position of their notes. As
        // Sibelius does not allow grace note tuplets, we don't have any nesting
        // issues inside grace note beams, although we will have to check if a
        // grace note beam is appended to a 'full-size' beam or whether it's
        // appended to the layer.
        if (not noteRest.GraceNote)
        {
            parentsInVoice = GetOrBuildParentsInVoiceMap(parentsByVoiceAndPosition, noteRest.VoiceNumber);
            switch (NormalizedBeamProp(noteRest))
            {
                case (NoBeam)
                {
                    parentsInVoice[noteRest.Position] = parentsInVoice.layerInfo;
                }
                case (StartBeam)
                {
                    beamInfo = CreateDictionary(
                        'element', libmei.Beam(),
                        'parent', parentsInVoice.layerInfo,
                        // TODO: We don't really need an array of all the notes,
                        // it suffices to have the first and the last one
                        'noteRests', CreateSparseArray(noteRest),
                        'position', noteRest.Position,
                        // This value will be updated when iteration reaches
                        // subsequent NoteRests under this beam
                        'endPosition', noteRest.Position
                    );
                    beamInfosInVoice = beamInfosByVoice[noteRest.VoiceNumber];
                    if (null = beamInfosInVoice)
                    {
                        beamInfosInVoice = CreateSparseArray();
                        beamInfosByVoice[noteRest.VoiceNumber] = beamInfosInVoice;
                    }
                    beamInfosInVoice.Push(beamInfo);
                    parentsInVoice[noteRest.Position] = beamInfo;
                }
                default
                {
                    beamInfosForVoice = beamInfosByVoice[noteRest.VoiceNumber];
                    // This should be a continued beam
                    if (null != beamInfosForVoice and beamInfosForVoice.Length > 0)
                    {
                        beamInfosForVoice[-1].noteRests.Push(noteRest);
                        beamInfosForVoice[-1].endPosition = noteRest.Position;
                        parentsInVoice[noteRest.Position] = beamInfosForVoice[-1];
                    }
                    else
                    {
                        // TODO: If we're here, we have a beam that crossed the
                        // preceding barline.
                        parentsInVoice[noteRest.Position] = parentsInVoice.layerInfo;
                    }
                }
            }
        }
    }

    // Check if there are tuplets interlocking with any beams, in which case we
    // turn the beam into a beamSpan
    for each voiceNumber in beamInfosByVoice.ValidIndices
    {
        beamInfosForVoice = beamInfosByVoice[voiceNumber];
        for each beamInfo in beamInfosForVoice
        {
            if (not BeamFitsInTupletHierarchy(beamInfo.noteRests))
            {
                // drop beam and create beamSpan instead
                beamSpan = libmei.BeamSpan();
                beamInfo.element = beamSpan;
                libmei.AddAttribute(beamSpan, 'layer', voiceNumber);
                libmei.AddAttribute(beamSpan, 'staff', bar.ParentStaff.StaffNum);
                // Register start and end NoteRests so we can later add @startid
                // and @endid when the MEI elements IDs were created.
                beamSpan['startNoteRest'] = beamInfo.noteRests[0];
                beamSpan['endNoteRest'] = beamInfo.noteRests[-1];

                parentsByVoiceAndPosition.beamSpans.Push(beamSpan);
                parentsInVoice = parentsByVoiceAndPosition[voiceNumber];

                for each noteRest in beamInfo.noteRests
                {
                    parentsInVoice[noteRest.Position] = parentsInVoice.layerInfo;
                }
            }
        }
    }

    // For all tuplets, check the relationship between tuplet and beams.
    // Possible situations:
    // * There is no beam (parent of the tuplet will be layer)
    // * Tuplet fits inside beam (parent of tuplet will be beam)
    // * Beam fits inside tuplet (tuplet will be parent of beam)
    // * They are interlocking and we have to resort to <beamSpan>. We've
    //   already ruled those out and created <beamSpan>s for these cases.
    for each Tuplet tuplet in bar
    {
        // The iteration visists the outer tuplets first, then their children
        parentsInVoice = parentsByVoiceAndPosition[tuplet.VoiceNumber];
        tupletInfo = CreateDictionary(
            'element', GenerateTuplet(tuplet),
            'parent', parentsInVoice[tuplet.Position],
            'position', tuplet.Position,
            'endPosition', tuplet.EndPosition
        );

        beamEnclosesTuplet = (
            tupletInfo.parent.element.name = 'beam'
            and tupletInfo.parent.noteRests[-1].Position >= tuplet.EndPosition
        );

        if (tupletInfo.parent.element.name = 'beam' and not beamEnclosesTuplet)
        {
            tupletInfo.parent = parentsInVoice.layerInfo;
        }

        noteRest = tuplet.NextItem(tuplet.VoiceNumber, 'NoteRest');
        while (null != noteRest and noteRest.Position < (tuplet.Position + tuplet.PlayedDuration))
        {
            parentInfo = parentsInVoice[noteRest.Position];
            if (parentInfo.element.name = 'beam' and not beamEnclosesTuplet)
            {
                parentInfo.parent = tupletInfo;
            }
            else
            {
                parentsInVoice[noteRest.Position] = tupletInfo;
            }
            tupletInfo.endPosition = noteRest.Position;
            noteRest = noteRest.NextItem(tuplet.VoiceNumber, 'NoteRest');
        }
    }

    for each BarRest barRest in bar
    {
        // This will initialize any uninitalized layers
        GetOrBuildParentsInVoiceMap(parentsByVoiceAndPosition, barRest.VoiceNumber);
    }

    if (parentsByVoiceAndPosition.ValidIndices.Length = 0)
    {
        // Make sure to initialize at least one layer even in (entirely
        // possible!) broken cases where a Bar has no NoteRests and no BarRest.
        // At least we can then attach clefs.
        GetOrBuildParentsInVoiceMap(parentsByVoiceAndPosition, 1);
    }

    return parentsByVoiceAndPosition;
} //$end


function GetOrBuildParentsInVoiceMap (parentsByVoiceAndPosition, voiceNumber) {
    /**
     * Returns the entry for `voiceNumber` found in `parentsByVoiceAndPosition`.
     * If the entry does not exist yet for this layer, one is created.
     */
    if (null != parentsByVoiceAndPosition[voiceNumber])
    {
        return parentsByVoiceAndPosition[voiceNumber];
    }
    else
    {
        layer = libmei.Layer();
        libmei.AddAttribute(layer, 'n', voiceNumber);
        layerInfo = CreateDictionary('element', layer);
        parentsInVoice = CreateSparseArray(layerInfo);
        parentsInVoice._property:layerInfo = layerInfo;
        parentsByVoiceAndPosition[voiceNumber] = parentsInVoice;
        return parentsInVoice;
    }
} //$end


function BeamFitsInTupletHierarchy (beamedNoteRests) {
    // `beamedNoteRests` is a SparseArray of all NoteRests belonging to a beam

    tupletAtStart = beamedNoteRests[0].ParentTupletIfAny;
    tupletAtEnd = beamedNoteRests[-1].ParentTupletIfAny;

    if (null = tupletAtStart and null = tupletAtEnd)
    {
        return true;
    }

    firstNoteRestPosition = beamedNoteRests[0].Position;
    lastNoteRestPosition = beamedNoteRests[-1].Position;

    while (null != tupletAtStart)
    {
        if (
            tupletAtStart.Position < firstNoteRestPosition
            and tupletAtStart.EndPosition < lastNoteRestPosition
        )
        {
            // Tuplet starts before beam and ends within beam
            return false;
        }
        tupletAtStart = tupletAtStart.ParentTupletIfAny;
    }

    followingNoteRest = beamedNoteRests[-1].NextItem(beamedNoteRests[0].VoiceNumber, 'NoteRest');
    if (null = followingNoteRest)
    {
        followingPosition = beamedNoteRests[0].ParentBar.Length;
    }
    else
    {
        followingPosition = followingNoteRest.Position;
    }

    while (null != tupletAtEnd)
    {
        if (
            tupletAtEnd.Position > firstNoteRestPosition
            and tupletAtEnd.EndPosition > followingPosition
        )
        {
            // Tuplet starts within beam and ends after beam
            return false;
        }
        tupletAtEnd = tupletAtEnd.ParentTupletIfAny;
    }

    return true;
}  //$end

function BuildStaffGrpHierarchy(score, barnum) {
    // Build the <staffGrp> hierarchy, respecting all instrument, bracket, brace
    // and barline groupings. Add all <staffDef>s.
    // Returns the root <staffGrp>.

    // We collect all the Sibelius objects relevant to staff grouping, namely
    // brackets/braces, barlines and instruments
    sibGroupItems = CreateSparseArray();

    for each bracketOrBrace in score.BracketsAndBraces
    {
        bracketOrBrace._property:groupType = 'bracket';
        sibGroupItems.Push(bracketOrBrace);
    }
    for each barline in score.Barlines
    {
        barline._property:groupType = 'barline';
        sibGroupItems.Push(barline);
    }
    staffNum = 1;
    staffCount = score.StaffCount;
    while (staffNum < staffCount)
    {
        staff = score.NthStaff(staffNum);
        sibGroupItems.Push(staff);
        staff._property:TopStaveNum = staffNum;
        staff._property:BottomStaveNum = staffNum + staff.NumStavesInSameInstrument - 1;
        staff._property:groupType = 'instrument';
        staffNum = staffNum + staff.NumStavesInSameInstrument;
    }

    // Now sort all the objects from the top of the staff to the bottom by means
    // of a rank value. The higher the rank of an item, the further down in the
    // score and/or in the hierarchy the item is.
    rankedItems = CreateSparseArray();
    maxSubrank = sibGroupItems.Length;
    subrank = 0;
    for each groupItem in sibGroupItems
    {
        // TopStaveNum takes highest priority in the rank
        rank = groupItem.TopStaveNum;
        // As items spanning less staves are further down in the hierarchy,
        // lower BottomStaveNum values must result in higher rank values, so
        // flip the value (i.e. staffCount - BottomStaveNum).
        rank = rank * staffCount + (staffCount - groupItem.BottomStaveNum);
        // Sub-brackets need a higher rank than other brackets because they must
        // be enclosed by any other brackets spanning the same staves.
        isSubBracket = groupItem.groupType = 'bracket' and groupItem.BracketType = BracketSub;
        rank = rank * 2 + isSubBracket;
        rank = rank * maxSubrank + subrank;
        // The 'subrank' (lowest priority) makes sure we don't get duplicate
        // rank values e.g. for instruments and braces that have the same top
        // and bottom staff and brackets/braces spanning the same staves.
        subrank = subrank + 1;
        rankedItems[rank] = groupItem;
    }

    // Now, the hierarchy of groups must be built up
    staffGrpByStaffNum = CreateSparseArray();
    rootGroup = CreateDictionary(
        'TopStaveNum', 1,
        'BottomStaveNum', staffCount,
        'groupType', 'rootGroup'
    );

    staffGrpStack = CreateSparseArray();
    AddNewStaffGrpToHierarchy(staffGrpStack, staffGrpByStaffNum, rootGroup);
    // Iteration is in ascending order of the rank value
    for each rank in rankedItems.ValidIndices
    {
        groupItem = rankedItems[rank];
        groupType = groupItem.groupType;
        // Pop all groups until we find the first enclosing group on the stack.
        // It's safe that the stack will not run empty because the root group
        // encloses all possible sub-groups.
        while (staffGrpStack[-1].BottomStaveNum < groupItem.BottomStaveNum)
        {
            poppedGroupItem = staffGrpStack.Pop();
            if (poppedGroupItem.BottomStaveNum >= groupItem.TopStaveNum)
            {
                OverlappingHierarchyWarning(poppedGroupItem, groupItem);
            }
        }
        enclosingGroupItem = staffGrpStack[-1];
        if (
            // Only create a new <staffGrp> if we can't reuse an existing one
            // (spanning the same staves) to encode groupItem's features.
            enclosingGroupItem.TopStaveNum != groupItem.TopStaveNum
            or enclosingGroupItem.BottomStaveNum != groupItem.BottomStaveNum
            // We can not re-use the <staffGrp> to encode the same kind of
            // features twice (specifically not multiple brackets).
            or enclosingGroupItem.groupType = groupItem.groupType
        )
        {
            AddNewStaffGrpToHierarchy(staffGrpStack, staffGrpByStaffNum, groupItem);
            groupType = groupItem.groupType;
        }

        staffGrpElement = staffGrpStack[-1].staffGrpElement;
        switch (groupType)
        {
            case ('bracket')
            {
                libmei.AddAttribute(staffGrpElement, 'symbol', ConvertBracket(groupItem.BracketType));
            }
            case ('barline')
            {
                libmei.AddAttribute(staffGrpElement, 'bar.thru', 'true');
            }
            case ('instrument')
            {
                // The Short/FullInstrumentName properties are always the
                // same in all staves of an instrument.
                staff = score.NthStaff(groupItem.TopStaveNum);
                AddLabelsToHierarchy(
                    staffGrpElement,
                    staff.FullInstrumentNameWithFormatting,
                    staff.ShortInstrumentNameWithFormatting
                );
            }
        }
    }

    AddStaffDefsToHierarchy(score, staffGrpByStaffNum, barnum);
    return staffGrpStack[0].staffGrpElement;
} //$end


function AddNewStaffGrpToHierarchy (staffGrpStack, staffGrpByStaffNum, groupItem) {
    // Create a new <staffGrp> with @n attribute, pushes it to the
    // staffGrpStack, registers which staves are part of it in
    // staffGrpByStaffNum and appends it to the tree (parent node is
    // staffGrpStack[-1].staffGrp).
    staffGrpStack._property:staffGrpNum = staffGrpStack._property:staffGrpNum + 1;
    groupItem._property:staffGrpElement = libmei.StaffGrp();
    libmei.AddAttribute(groupItem.staffGrpElement, 'n', staffGrpStack.staffGrpNum);
    if (staffGrpStack.Length > 0)
    {
        libmei.AddChild(staffGrpStack[-1].staffGrpElement, groupItem.staffGrpElement);
    }
    staffGrpStack.Push(groupItem);
    for staffNum = groupItem.TopStaveNum to groupItem.BottomStaveNum + 1
    {
        staffGrpByStaffNum[staffNum] = groupItem.staffGrpElement;
    }
} //$end


function AddStaffDefsToHierarchy (score, staffGrpByStaffNum, barnum) {
    for each Staff s in score
    {
        std = libmei.StaffDef();

        libmei.AddAttribute(std, 'n', s.StaffNum);
        libmei.AddAttribute(std, 'lines', s.InitialInstrumentType.NumStaveLines);

        diaTrans = s.InitialInstrumentType.DiatonicTransposition;
        semiTrans = s.InitialInstrumentType.ChromaticTransposition;
        if (diaTrans != 0 and semiTrans != 0)
        {
            libmei.AddAttribute(std, 'trans.semi', semiTrans);
            libmei.AddAttribute(std, 'trans.diat', diaTrans);
        }
        if (s.Small)
        {
            libmei.AddAttribute(std, 'scale', score.EngravingRules.SmallStaffSizeScale & '%');
        }

        clefinfo = ConvertClef(s.InitialClefStyleId);
        libmei.AddAttribute(std, 'clef.shape', clefinfo[0]);
        libmei.AddAttribute(std, 'clef.line', clefinfo[1]);
        libmei.AddAttribute(std, 'clef.dis', clefinfo[2]);
        libmei.AddAttribute(std, 'clef.dis.place', clefinfo[3]);

        keysig = s.CurrentKeySignature(barnum);
        libmei.AddAttribute(std, 'key.sig', ConvertKeySignature(keysig.Sharps));

        if (keysig.Major)
        {
            libmei.AddAttribute(std, 'key.mode', 'major');
        }
        else
        {
            libmei.AddAttribute(std, 'key.mode', 'minor');
        }

        AddLabelsToHierarchy(std, s.FullStaffNameWithFormatting, s.ShortStaffNameWithFormatting);

        libmei.AddChild(staffGrpByStaffNum[s.StaffNum], std);
    }
}  //$end


function AddLabelsToHierarchy (staffGrpElement, fullName, shortName) {
    if (fullName != '')
    {
        label = libmei.Label();
        AddTextWithFormattingAsString(label, fullName);
        libmei.AddChild(staffGrpElement, label);
    }

    if (shortName != '')
    {
        labelAbbr = libmei.LabelAbbr();
        AddTextWithFormattingAsString(labelAbbr, shortName);
        libmei.AddChild(staffGrpElement, labelAbbr);
    }
} //$end


function OverlappingHierarchyWarning (poppedGroupItem, groupItem) {
    if (groupItem.TopStaveNum = poppedGroupItem.BottomStaveNum)
    {
        affectedStaves = 'staff ' & groupItem.TopStaveNum;
    }
    else
    {
        affectedStaves = 'staves ' & groupItem.TopStaveNum & '-' & poppedGroupItem.BottomStaveNum;
    }
    Trace(
        'Warning: Overlapping '
        & poppedGroupItem.groupType
        & ' and '
        & groupItem.groupType
        & ' in '
        & affectedStaves
        & '. Overlapping hierarchies can not be encoded.'
    );
} //$end

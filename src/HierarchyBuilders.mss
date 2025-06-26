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

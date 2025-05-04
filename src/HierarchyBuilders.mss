function BuildStaffGrpHierarchy(score, barnum) {
    // Build the <staffGrp> hierarchy, respecting all instrument, bracket, brace
    // and barline groupings. Add all <staffDef>s.
    // Returns the root <staffGrp>.

    // We collect all the Sibelius objects relevant to staff grouping, namely
    // brackets/braces, barlines and instruments
    sibGroupItems = CreateSparseArray();

    for each bracketOrBrace in score.BracketsAndBraces
    {
        bracketOrBrace._property:action = 'addSymbolAttribute';
        sibGroupItems.Push(bracketOrBrace);
    }
    for each barline in score.Barlines
    {
        barline._property:action = 'addBarThru';
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
        staff._property:action = 'addLabels';
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
        isSubBracket = groupItem.action = 'addSymbolAttribute' and groupItem.BracketType = BracketSub;
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
        'action', 'createRootGroup'
    );

    staffGrpStack = CreateSparseArray();
    AddNewStaffGrpToHierarchy(staffGrpStack, staffGrpByStaffNum, rootGroup);
    // Iteration is in ascending order of the rank value
    for each rank in rankedItems.ValidIndices
    {
        groupItem = rankedItems[rank];
        action = groupItem.action;
        // Pop all groups until we find the first enclosing group on the stack.
        // It's safe that the stack will not run empty because the root group
        // encloses all possible sub-groups.
        while (staffGrpStack[-1].BottomStaveNum < groupItem.BottomStaveNum)
        {
            poppedGroupItem = staffGrpStack.Pop();
            if (poppedGroupItem.BottomStaveNum > groupItem.TopStaveNum)
            {
                // If the popped group is interlocking with the current
                // goupItem, they can't both fit in the hierarchy, so we have to
                // drop one of them.
                action = 'dropGroup';
            }
        }
        enclosingGroupItem = staffGrpStack[-1];
        if (
            action != 'dropGroup' and (
                // We combine different kinds of groups, e.g. staff line groups
                // and brackets if they span the same staves.
                enclosingGroupItem.TopStaveNum != groupItem.TopStaveNum
                or enclosingGroupItem.BottomStaveNum != groupItem.BottomStaveNum
                // If we have nested brackets/braces for the same group of
                // staves, we want to create nested <staffGrp>s. If the actions
                // to be performed for the group differ, we don't have to create
                // nested <staffGrp>s.
                or enclosingGroupItem.action = groupItem.action
            )
        )
        {
            AddNewStaffGrpToHierarchy(staffGrpStack, staffGrpByStaffNum, groupItem);
            action = groupItem.action;
        }

        staffGrpElement = staffGrpStack[-1].staffGrpElement;
        switch (action)
        {
            case ('addSymbolAttribute')
            {
                libmei.AddAttribute(staffGrpElement, 'symbol', ConvertBracket(staffGrpStack[-1].BracketType));
            }
            case ('addBarThru')
            {
                libmei.AddAttribute(staffGrpElement, 'bar.thru', 'true');
            }
            case ('addLabels')
            {
                // The Short/FullInstrumentName properties are always the
                // same in all staves of an instrument.
                staff = score.NthStaff(staffGrpStack[-1].TopStaveNum);
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

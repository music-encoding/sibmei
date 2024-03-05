function InitLyricHandlers() {
    Self._property:LyricText = SetTemplateAction(CreateDictionary(), Self, 'LyricTextAction');

    Self._property:LyricsHandlers = CreateDictionary(
        'StyleId', CreateDictionary(),
        'StyleAsText', CreateDictionary()
    );

    sylTemplate = CreateSparseArray('Syl', null, LyricText);

    RegisterLyricHandlers('StyleId', CreateDictionary(
        'text.staff.space.hypen.lyrics.above', CreateSparseArray('Verse', CreateDictionary('place', 'above'), sylTemplate),
        'text.staff.space.hypen.lyrics.chorus', CreateSparseArray('Refrain', null, sylTemplate),
        'text.staff.space.hypen.lyrics.verse1', CreateSparseArray('Verse', CreateDictionary('n', '1'), sylTemplate),
        'text.staff.space.hypen.lyrics.verse2', CreateSparseArray('Verse', CreateDictionary('n', '2'), sylTemplate),
        'text.staff.space.hypen.lyrics.verse3', CreateSparseArray('Verse', CreateDictionary('n', '3'), sylTemplate),
        'text.staff.space.hypen.lyrics.verse4', CreateSparseArray('Verse', CreateDictionary('n', '4'), sylTemplate),
        'text.staff.space.hypen.lyrics.verse5', CreateSparseArray('Verse', CreateDictionary('n', '5'), sylTemplate)
    ), Self);
}  //$end


function RegisterLyricHandlers (styleIdType, lyricsHandlerDict, plugin) {
    for each handler in lyricsHandlerDict
    {
        if (IsObject(handler))
        {
            // `handler` is a template
            for each sylTemplate in GetTemplateElementsByTagName(handler, 'Syl')
            {
                SetTemplateAction(sylTemplate, Self, 'SylElementAction');
            }
        }
    }
    RegisterHandlers(LyricsHandlers[styleIdType], lyricsHandlerDict, plugin);
}  //$end


function HandleLyricItem (lyricobj, objectPositions) {
    /*
        We need to track initial, medial, and terminal lyrics. Sibelius
        only allows us to know the medial and terminal, so we store all the
        syllables in an array until we reach the end of the word, and then
        attach them to the notes.
    */

    if (lyricobj.Text = '')
    {
        return null;
    }

    barNum = lyricobj.ParentBar.BarNumber;
    staffNum = lyricobj.ParentBar.ParentStaff.StaffNum;
    voiceNum = lyricobj.VoiceNumber;

    if (voiceNum = 0)
    {
        // assign it to the first voice, since we don't have any notes in voice 0.
        voiceNum = 1;
        warnings = Self._property:warnings;
        warnings.Push(utils.Format(_ObjectAssignedToAllVoicesWarning, barNum, voiceNum, 'Lyric object'));
    }

    if (null = LyricWords[staffNum])
    {
        LyricWords[staffNum] = CreateSparseArray();
    }

    lyricstaff = LyricWords[staffNum];

    if (null = lyricstaff[voiceNum])
    {
        lyricstaff[voiceNum] = CreateDictionary();
    }

    lyricvoice = lyricstaff[voiceNum];

    // We can have multiple layers of lyrics (specifically multiple verses) on
    // top of each other.  Each layer has its own style.
    if (null = lyricvoice[lyricobj.StyleId])
    {
        lyricvoice[lyricobj.StyleId] = CreateSparseArray();
    }
    lyricvoice[lyricobj.StyleId].Push(lyricobj);

    if (lyricobj.SyllableType = MiddleOfWord)
    {
        // we haven't reached the end of the word yet, so just return
        // and keep going.
        return null;
    }

    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // anything past here is in the EndOfWord condition.
    // this should return a sparse array containing the syllables of the word.
    lyricItemsInWord = lyricvoice[lyricobj.StyleId];

    lastLyricItemInWord = lyricItemsInWord[lyricItemsInWord.Length - 1];

    for lyricItemIndex = 0 to lyricItemsInWord.Length
    {
        lyricItem = lyricItemsInWord[lyricItemIndex];
        if (lyricItemIndex = 0)
        {
            lyricItem._property:startOfWord = true;
        }
        lyricElement = HandleStyle(LyricsHandlers, lyricItem);
        if (lyricItem.Color != 0)
        {
            libmei.AddAttribute(lyricElement, 'color', ConvertColor(lyricItem));
        }
    }

    // now reset the syllable array for this verse
    lyricvoice[lyricobj.StyleId] = CreateSparseArray();
}  //$end


function SylElementAction (actionDict, parent, lyricItem) {
    // This action is directly attached to the <syl> template.  It creates one
    // or more <syl> elements (depending on whether we have an elision).

    // Split lyrics text by underscore and space, in case we have an elision
    syllables = SplitStringIncludeDelimiters(lyricItem.Text, '_ ');
    firstSylElement = CreateSylChild(parent, actionDict.templateNode, lyricItem, syllables[0]);

    // In the case of elisions, we create multiple syl elements from one
    // LyricItem. We have to distinguish between the first and the last syl
    // element we created. In the common, simple case, both are identical.
    lastSylElement = firstSylElement;

    // Handle any found elisions. The syllables array includes both the text
    // and the elision delimiters ' ' and '_', i.e. lyric text and delimiters
    // are alternating.
    for i = 1 to syllables.Length step 2
    {
        elisionDelimiter = syllables[i];
        elisionSyl = syllables[i + 1];

        if (elisionDelimiter = '_')
        {
            // breve (curved line below) connector
            libmei.AddAttribute(lastSylElement, 'con', 'b');
        }
        else
        {
            // space connector
            libmei.AddAttribute(lastSylElement, 'con', 's');
        }

        lastSylElement = CreateSylChild(parent, actionDict.templateNode, lyricItem, elisionSyl);
    }

    if (lyricItem.SyllableType = EndOfWord)
    {
        // Check if the last syllable is melismatic and shows a line.
        // Sibelius only shows an extender line if both of the following
        // conditions are met (plus lyricItem.SyllableType = EndOfWord).
        if (lyricItem.NumNotes > 1 and lyricItem.Duration > 0)
        {
            libmei.AddAttribute(lastSylElement, 'con', 'u'); // 'underscore'
        }
    }
    else
    {
        // Word continues after lyricItem, so we need a dash connector.
        libmei.AddAttribute(lastSylElement, 'con', 'd');
        // We're in initial word position if the lyricItem starts the word, or
        // if a new word started within the lyricItem because of an elision.
        if (lyricItem._property:startOfWord or syllables.Length > 1)
        {
            libmei.AddAttribute(lastSylElement, 'wordpos', 'i'); // 'initial'
        }
        else
        {
            libmei.AddAttribute(lastSylElement, 'wordpos', 'm'); // 'medial'
        }
    }

    // Word ends at EndOfWord or before an elision interruption. In case both
    // `EndOfWord` and `startOfWord` apply, we have a single syllable and no
    // @wordpos should be written.
    if ((lyricItem.SyllableType = EndOfWord or syllables.Length > 1) and not lyricItem._property:startOfWord)
    {
        libmei.AddAttribute(firstSylElement, 'wordpos', 't'); // 'terminal'
    }

    // TODO: This code most go somewhere!
    // parentElement = GetNoteObjectAtPosition(lyricItem, 'PreciseMatch');
    //
    // if (parentElement != null)
    // {
    //     if (libmei.GetName(parentElement) = 'rest')
    //     {
    //         warnings = Self._property:warnings;
    //         warnings.Push(utils.Format(_ObjectIsOnAnIllogicalObject, barNum, voiceNum, 'Lyric', 'rest'));
    //     }
    //
    // }
    // else
    // {
    //     Log('Could not find note object for syl ' & lyricItem);
    // }
} //$end


function CreateSylChild (parent, template, lyricItem, sylText) {
    // `template` should have a decendant LyricText action.  This action will be
    // called by MeiFactory() when it reaches the decendant action.  Because we
    // can't simply insert `lyricItem`'s `Text` value in the case of an elision,
    // this action relies on the the user property `currentSyllable` for the
    // inserted text.
    lyricItem._property:currentSyllable = sylText;
    sylElement = MeiFactory(template, lyricItem);
    libmei.AddChild(parent, sylElement);
    return sylElement;
} //$end


function LyricTextAction (action, parentElement, lyricItem) {
    AppendText(null, parentElement, lyricItem.currentSyllable);
}  //$end

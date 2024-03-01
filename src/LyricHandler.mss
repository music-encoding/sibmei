function HandleLyric (lyricobj, objectPositions) {
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

    verse_num = 0;
    isChorus = (lyricobj.StyleId = 'text.staff.space.hypen.lyrics.chorus');

    if (not isChorus)
    {
        verseIdPrefix = 'text.staff.space.hypen.lyrics.verse';
        // Substring after the verse ID prefix is a verse number, from 1 to 6
        verse_num = Substring(lyricobj.StyleId, Length(verseIdPrefix)) + 0;
    }

    bar_num = lyricobj.ParentBar.BarNumber;
    staff_num = lyricobj.ParentBar.ParentStaff.StaffNum;
    voicenum = lyricobj.VoiceNumber;

    if (voicenum = 0)
    {
        // assign it to the first voice, since we don't have any notes in voice 0.
        voicenum = 1;
        warnings = Self._property:warnings;
        warnings.Push(utils.Format(_ObjectAssignedToAllVoicesWarning, bar_num, voicenum, 'Lyric object'));
    }

    lyricwords = Self._property:LyricWords;

    if (lyricwords.PropertyExists(staff_num) = False)
    {
        lyricwords[staff_num] = CreateDictionary();
    }

    lyricstaff = lyricwords[staff_num];

    if (lyricstaff.PropertyExists(voicenum) = False)
    {
        lyricstaff[voicenum] = CreateDictionary();
    }

    lyricvoice = lyricstaff[voicenum];

    if (lyricvoice.PropertyExists(verse_num) = False)
    {
        lyricvoice[verse_num] = CreateSparseArray();
    }

    if (lyricobj.SyllableType = MiddleOfWord)
    {
        lyricvoice[verse_num].Push(lyricobj);
        // we haven't reached the end of the word yet, so just return
        // and keep going.
        return null;
    }

    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // anything past here is in the EndOfWord condition.
    // this should return a sparse array containing the syllables of the word.
    lyricvoice[verse_num].Push(lyricobj);
    lyric_word = lyricvoice[verse_num];
    objects = objectPositions[voicenum];

    obj_id = null;
    obj = null;

    for j = 0 to lyric_word.Length
    {
        syl = lyric_word[j];

        if (isChorus) {
            verse = libmei.Refrain();
        }
        else
        {
            verse = libmei.Verse();
        }

        if (verse_num > 0)
        {
            // verse_num = 0 is used for anything that is not a verse, e.g.
            // chorus, Siblius' 'lyrics above' style and any other user defined
            // lyrics styles where we don't know if a specific verse number is
            // intended.  We therefore only write @n if verse_num > 0.
            libmei.AddAttribute(verse, 'n', verse_num);
        }
        if (syl.Color != 0)
        {
            libmei.AddAttribute(verse, 'color', ConvertColor(syl));
        }

        sylel = libmei.Syl();
        // In the case of elisions, we create multiple syl elements from one
        // LyricItem. We have to distinguish between the first and the last syl
        // element we created. In the common, simple case, both are identical.
        sylel_last = sylel;
        libmei.AddChild(verse, sylel);

        // Split lyrics text by underscore and space, in case there is an elision
        syllables = SplitStringIncludeDelimiters(syl.Text, '_ ');
        libmei.SetText(sylel, syllables[0]);

        // Handle any found elisions
        for s = 1 to syllables.Length step 2
        {
            elisionDelimiter = syllables[s];
            elisionSyl = syllables[s + 1];
            if (elisionDelimiter = '_')
            {
                libmei.AddAttribute(sylel_last, 'con', 'b');
            }
            else
            {
                libmei.AddAttribute(sylel_last, 'con', 's');
            }
            sylel_last = libmei.Syl();
            libmei.SetText(sylel_last, elisionSyl);
            libmei.AddChild(verse, sylel_last);
        }

        if (syl.SyllableType = MiddleOfWord)
        {
            libmei.AddAttribute(sylel_last, 'con', 'd'); //dash syllable connector

            // New word starts at the first syllable in the lyric_word or after an elision
            if (j = 0 or syllables.Length > 1)
            {
                libmei.AddAttribute(sylel_last, 'wordpos', 'i'); // 'initial'
            }
            else
            {
                libmei.AddAttribute(sylel_last, 'wordpos', 'm'); // 'medial'
            }
        }

        // Word ends at EndOfWord or before an elision (if there are syllables before the elision)
        if (j > 0 and (syl.SyllableType = EndOfWord or syllables.Length > 1))
        {
            libmei.AddAttribute(sylel, 'wordpos', 't'); // 'terminal'
        }

        obj = GetNoteObjectAtPosition(syl, 'PreciseMatch');

        if (obj != null)
        {
            name = libmei.GetName(obj);

            if (name = 'rest')
            {
                warnings = Self._property:warnings;
                warnings.Push(utils.Format(_ObjectIsOnAnIllogicalObject, bar_num, voicenum, 'Lyric', 'rest'));
            }

            libmei.AddChild(obj, verse);
        }
        else
        {
            Log('Could not find note object for syl ' & syl);
        }
    }

    // Check if the last syllable is melismatic
    if (syl.NumNotes > 1)
    {
        libmei.AddAttribute(sylel_last, 'con', 'u'); // 'underscore'
    }

    // now reset the syllable array for this voice
    lyricvoice[verse_num] = CreateSparseArray();
}  //$end

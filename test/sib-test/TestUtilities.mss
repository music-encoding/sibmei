function TestUtilities (suite) {
    //$module(TestUtilities)
    suite
        .Add('TestMSplitString')
        .Add('TestSplitStringIncludeDelimiters')
        .Add('TestPrevPow2')
        .Add('TestGetTemplateElementsByTagName')
        .Add('TestBeamIsInterlockingWithTuplet')
        ;
} //$end


function TestMSplitString (assert, plugin) {
    //$module(TestUtilities)
    split = sibmei.MSplitString('foo.bar.baz', '.');
    assert.Equal(split.Length, 3, 'There should be three elements in the split string');
    assert.Equal(split[0], 'foo', 'The first element should be foo');
}  //$end


function TestSplitStringIncludeDelimiters (assert, plugin) {
    //$module(TestUtilities)
    split = sibmei.SplitStringIncludeDelimiters('foo-bar baz', ' -');
    assert.Equal(split, CreateSparseArray('foo', '-', 'bar', ' ', 'baz'), 'Interspersed delimiters');

    split = sibmei.SplitStringIncludeDelimiters('  foo--bar  baz  ', ' -');
    assert.Equal(split, CreateSparseArray('', ' ', 'foo', '-', 'bar', ' ', 'baz', ' ', ''), 'Reduce multiple delimters to just one');

    split = sibmei.SplitStringIncludeDelimiters('foo- bar', ' -');
    assert.Equal(split, CreateSparseArray('foo', '-', '', ' ', 'bar'), 'Do not reduce adjacent delimiters');
}  //$end


function TestPrevPow2 (assert, plugin) {
    //$module(TestUtilities)
    pow = sibmei.PrevPow2(1025);
    assert.Equal(pow, 1024, 'Previous Power of two of 1025 is 1024');

    pow = sibmei.PrevPow2(8);
    assert.Equal(pow, 8, 'Previous Power of two of 8 is 8');

    pow = sibmei.PrevPow2(7);
    assert.Equal(pow, 4, 'Previous Power of two of 7 is 4');
}  //$end


function TestGetTemplateElementsByTagName (assert, plugin) {
    template = @Element('Foo', @Attrs('n', 0),
        @Element('Bar', null,
            @Element('Foo', @Attrs('n', 1))
        ),
        @Element('Foo', @Attrs('n', 2), 'Text child')
    );

    fooElements = sibmei.GetTemplateElementsByTagName(template, 'Foo');
    assert.Equal(fooElements.Length, 3, 'Expected number of <foo> elements');
    for n = 0 to fooElements.Length
    {
        fooElement = fooElements[n];
        assert.Equal(fooElement[1].n, n, 'Expected order');
    }
}  //$end


function TestBeamIsInterlockingWithTuplet (assert, plugin) {
    score = OpenSibFile(Self._SibTestFileDirectory & 'tuplet-beams.sib', true);
    staff1 = score.NthStaff(1);

    assert.Equal(false, _InterlockingResult(staff1,  1, 1, 0, 6), 'bar 1');
    assert.Equal(false, _InterlockingResult(staff1,  2, 1, 0, 6), 'bar 2');
    assert.Equal(false, _InterlockingResult(staff1,  3, 1, 0, 6), 'bar 3');
    assert.Equal(false, _InterlockingResult(staff1,  4, 1, 0, 1), 'bar 4, beam 1');
    assert.Equal(true , _InterlockingResult(staff1,  4, 1, 2, 3), 'bar 4, beam 2');
    assert.Equal(true , _InterlockingResult(staff1,  5, 1, 0, 1), 'bar 5, beam 1');
    assert.Equal(false, _InterlockingResult(staff1,  5, 1, 2, 3), 'bar 5, beam 2');
    assert.Equal(true , _InterlockingResult(staff1,  6, 1, 0, 2), 'bar 6, beam 1');
    assert.Equal(false, _InterlockingResult(staff1,  6, 1, 3, 4), 'bar 6, beam 2');
    assert.Equal(false, _InterlockingResult(staff1,  7, 1, 0, 1), 'bar 7, beam 1');
    assert.Equal(true , _InterlockingResult(staff1,  7, 1, 2, 4), 'bar 7, beam 2');
    assert.Equal(false, _InterlockingResult(staff1,  8, 1, 0, 1), 'bar 8');
    assert.Equal(false, _InterlockingResult(staff1,  9, 1, 0, 1), 'bar 9, beam 1');
    assert.Equal(false, _InterlockingResult(staff1,  9, 1, 2, 3), 'bar 9, beam 2');
    assert.Equal(false, _InterlockingResult(staff1,  9, 1, 4, 5), 'bar 9, beam 3');
    assert.Equal(false, _InterlockingResult(staff1, 10, 1, 1, 2), 'bar 10');
    assert.Equal(false, _InterlockingResult(staff1, 11, 1, 0, 1), 'bar 11, beam 1');
    assert.Equal(false, _InterlockingResult(staff1, 11, 1, 3, 4), 'bar 11, beam 2');
    assert.Equal(false, _InterlockingResult(staff1, 12, 1, 0, 1), 'bar 12');
}  //$end


function _InterlockingResult (staff, barNumber, voiceNumber, from, until) {
    bar = staff.NthBar(barNumber);
    noteRests = CreateSparseArray();
    i = 0;
    for each NoteRest noteRest in bar
    {
        if (noteRest.VoiceNumber = voiceNumber)
        {
            if (i >= from and i <= until)
            {
                noteRests.Push(noteRest);
            }
            i = i + 1;
        }
    }
    return sibmei.BeamIsInterlockingWithTuplet(noteRests);
} //$end
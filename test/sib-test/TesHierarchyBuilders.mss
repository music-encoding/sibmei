function TestHierarchyBuilders (suite) {
    //$module(TestUtilities)
    suite
        .Add('TestBeamFitsInTupletHierarchy')
        ;
} //$end


function TestBeamFitsInTupletHierarchy (assert, plugin) {
    score = OpenSibFile(Self._SibTestFileDirectory & 'tuplet-beams.sib', true);
    staff1 = score.NthStaff(1);

    assert.Equal(true, _HierarchyTestResult(staff1,  1, 1, 0, 6), 'bar 1');
    assert.Equal(true, _HierarchyTestResult(staff1,  2, 1, 0, 6), 'bar 2');
    assert.Equal(true, _HierarchyTestResult(staff1,  3, 1, 0, 6), 'bar 3');
    assert.Equal(true, _HierarchyTestResult(staff1,  4, 1, 0, 1), 'bar 4, beam 1');
    assert.Equal(false, _HierarchyTestResult(staff1,  4, 1, 2, 3), 'bar 4, beam 2');
    assert.Equal(false, _HierarchyTestResult(staff1,  5, 1, 0, 1), 'bar 5, beam 1');
    assert.Equal(true, _HierarchyTestResult(staff1,  5, 1, 2, 3), 'bar 5, beam 2');
    assert.Equal(false, _HierarchyTestResult(staff1,  6, 1, 0, 2), 'bar 6, beam 1');
    assert.Equal(true, _HierarchyTestResult(staff1,  6, 1, 3, 4), 'bar 6, beam 2');
    assert.Equal(true, _HierarchyTestResult(staff1,  7, 1, 0, 1), 'bar 7, beam 1');
    assert.Equal(false, _HierarchyTestResult(staff1,  7, 1, 2, 4), 'bar 7, beam 2');
    assert.Equal(true, _HierarchyTestResult(staff1,  8, 1, 0, 1), 'bar 8');
    assert.Equal(true, _HierarchyTestResult(staff1,  9, 1, 0, 1), 'bar 9, beam 1');
    assert.Equal(true, _HierarchyTestResult(staff1,  9, 1, 2, 3), 'bar 9, beam 2');
    assert.Equal(true, _HierarchyTestResult(staff1,  9, 1, 4, 5), 'bar 9, beam 3');
    assert.Equal(true, _HierarchyTestResult(staff1, 10, 1, 1, 2), 'bar 10');
    assert.Equal(true, _HierarchyTestResult(staff1, 11, 1, 0, 1), 'bar 11, beam 1');
    assert.Equal(true, _HierarchyTestResult(staff1, 11, 1, 3, 4), 'bar 11, beam 2');
    assert.Equal(true, _HierarchyTestResult(staff1, 12, 1, 0, 1), 'bar 12');
}  //$end


function _HierarchyTestResult (staff, barNumber, voiceNumber, from, until) {
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
    return sibmei.BeamFitsInTupletHierarchy(noteRests);
} //$end


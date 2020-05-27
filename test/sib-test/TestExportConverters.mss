function TestExportConverters (suite) {
    //$module(TestExportConverters)
    suite
        .Add('TestSlurValueConverter')
        .Add('TestDiatonicPitchConverter')
        .Add('TestOffsetConverter')
        .Add('TestDurationConverter')
        .Add('TestPitchesInKeySignature')
        .Add('TestHasVisibleAccidentalConverter')
        .Add('TestAccidentalConverter')
        .Add('TestOctavaConverter')
        .Add('TestNamedTimeSignatureConverter')
        .Add('TestKeySignatureConverter')
        .Add('TestClefConverter')
        .Add('TestBracketConverter')
        .Add('TestPositionToTimestampConverter')
        .Add('TestConvertTimeStamp')
        ;
} //$end

function TestSlurValueConverter (assert, plugin) {
    //$module(TestExportConverters)
    output = sibmei.ConvertSlurStyle('line.staff.slur.up.dotted');
    assert.Equal(output[0], 'above', 'Direction should be up');
    assert.Equal(output[1], 'dotted', 'Style should be dotted');

    output = sibmei.ConvertSlurStyle('line.staff.slur.down');
    assert.Equal(output[0], 'below', 'Direction should be down');
    assert.Equal(output[1], ' ', 'Style should be empty');
} //$end

function TestDiatonicPitchConverter(assert, plugin) {
    //$module(TestNoteNameConverter)
    output = sibmei.ConvertDiatonicPitch(35);
    assert.Equal(output[0], 'c', '35 is Diatonic C');
    assert.Equal(output[1], 4, '35 is octave 4');

    output = sibmei.ConvertDiatonicPitch(50);
    assert.Equal(output[0], 'd', '50 is Diatonic D');
    assert.Equal(output[1], 6, '50 is octave 6');
}  //$end

function TestOffsetConverter(assert, plugin) {
    //$module(TestNoteNameConverter)
    EnsureActiveScoreExists();
    output = sibmei.ConvertOffsetsToMillimeters(100);
    assert.Equal(output, '5.4688mm', 'Offset of 100 1/32nds of a space is 5mm');
}  //$end

function TestDurationConverter(assert, plugin) {
    //$module(TestNoteNameConverter)
    output = sibmei.ConvertDuration(1024);
    assert.Equal(output[0], 1, '1024 has an MEI duration of 1');
    assert.Equal(output[1], ' ', '1024 has no dotted duration');

    output = sibmei.ConvertDuration(384);
    assert.Equal(output[0], 4, '384 is a dotted quarter');
    assert.Equal(output[1], 1, '384 has one dot');

    output = sibmei.ConvertDuration(2048);
    assert.Equal(output[0], 'breve', '2048 is a breve');
    assert.Equal(output[1], ' ', '2048 is not a dotted duration');

    output = sibmei.ConvertDuration(3584);
    assert.Equal(output[0], 'breve', '2048 is a breve');
    assert.Equal(output[1], 2, '3584 is a double-dotted duration');
}  //$end

function TestPitchesInKeySignature (assert, plugin) {
    //$module(TestExportConverters.mss)
    output = sibmei.PitchesInKeySignature(1);
    assert.Equal(output.Length, 1, 'The key signature should have one sharp');
    assert.Equal(output[0], 'F', 'The sharp should be F');

    output = sibmei.PitchesInKeySignature(-1);
    assert.Equal(output.Length, 1, 'The key signature should have one flat');
    assert.Equal(output[0], 'B', 'The sharp should be B');

    output = sibmei.PitchesInKeySignature(0);
    assert.Equal(output.Length, 0, 'The key signature should have no sharps or flats');

    output = sibmei.PitchesInKeySignature(7);
    assert.Equal(output.Length, 7, 'The key signature should have 7 sharps');
    assert.Equal(output[6], 'B', 'The last should be a B sharp');

    output = sibmei.PitchesInKeySignature(-7);
    assert.Equal(output.Length, 7, 'The key signature should have 7 flats');
    assert.Equal(output[6], 'F', 'The last should be a F flat');
}  //$end

function TestAccidentalConverter (assert, plugin) {
    //$module(TestExportConverters.mss)
    fe = Sibelius.FileExists(_SibTestFileDirectory & 'accidentals.sib');
    if (fe = False)
    {
        trace('Cannot find ' & _SibTestFileDirectory & 'accidentals.sib. Skipping test.');
        return null;
    }

    score = OpenSibFile(_SibTestFileDirectory & 'accidentals.sib', True);
    staff = score.NthStaff(1);
    bar1 = staff[1];

    noterest1 = bar1.NthBarObject(0);
    note1 = noterest1[0];
    output = sibmei.ConvertAccidental(note1);
    assert.Equal(output[0], 'f', 'The note is a B flat.');
    assert.OK(output[1], 'The 2nd note in the 1st bar has a visible B flat');

    noterest2 = bar1.NthBarObject(1);
    note2 = noterest2[0];
    output = sibmei.ConvertAccidental(note2);
    assert.Equal(output[0], 'n', 'The note is a B natural');
    assert.OK(output[1], 'The 2nd note in the 1st bar has a visible B natural');

    noterest3 = bar1.NthBarObject(2);
    note3 = noterest3[0];
    output = sibmei.ConvertAccidental(note3);
    assert.Equal(output[0], 's', 'The note is a G sharp');
    assert.OK(output[1], 'The accidental on G sharp should be visible');

    noterest4 = bar1.NthBarObject(3);
    note4 = noterest4[0];
    output = sibmei.ConvertAccidental(note4);
    assert.Equal(output[0], 'n', 'The note is a G natural');
    assert.OK(output[1], 'The accidental on G natural should be visible');

    bar2 = staff[2];
    noterest5 = bar1.NthBarObject(0);
    note5 = noterest5[0];
    output = sibmei.ConvertAccidental(note5);
    assert.Equal(output[0], 'ff', 'The note is a B double-flat');
    assert.OK(output[1], 'The B double-flat should be visible');

    noterest6 = bar2.NthBarObject(1);
    note6 = noterest6[0];
    output = sibmei.ConvertAccidental(note6);
    assert.Equal(output[0], 'ff', 'The note is a B double-flat');
    assert.NotOK(output[1], 'The B double-flat has already been shown, so it should not be visible');

    bar4 = staff[4];
    noterest7 = bar4.NthBarObject(2);
    note7 = noterest7[0];
    output = sibmei.ConvertAccidental(note7);
    assert.Equal(output[0], 'x', 'The note is a G double-sharp (croix)');
    assert.OK(output[1], 'The croix should be visible');

    noterest8 = bar4.NthBarObject(3);
    note8 = noterest8[0];
    output = sibmei.ConvertAccidental(note8);
    assert.Equal(output[0], 'ss', 'The note is an invisible G double-sharp. There is no croix for invisible accidentals');
    assert.NotOK(output[1], 'The G double-sharp has already been shown, so it should not be visible');
}  //$end

function TestHasVisibleAccidentalConverter (assert, plugin) {
    //$module(TestExportConverters.mss)
    filePath = _SibTestFileDirectory & 'accidentals.sib';
    score = OpenSibFile(filePath, True);

    staff = score.NthStaff(1);
    bar1 = staff[1];

    noterest1 = bar1.NthBarObject(0);
    note1 = noterest1[0];
    output = sibmei.HasVisibleAccidental(note1);
    assert.OK(output, 'The 1st note in the 1st bar has a visible B flat');

    noterest2 = bar1.NthBarObject(1);
    note2 = noterest2[0];
    output = sibmei.HasVisibleAccidental(note2);
    assert.OK(output, 'The 2nd note in the 1st bar has a visible B natural');

    bar5 = staff[5];
    noterest3 = bar5.NthBarObject(0);
    note3 = noterest3[0];
    output = sibmei.HasVisibleAccidental(note3);
    assert.NotOK(output, 'The 1st note in the 5th bar does not have a visible accidental');

    noterest4 = bar5.NthBarObject(2);
    note4 = noterest4[0];
    output = sibmei.HasVisibleAccidental(note4);
    assert.NotOK(output, 'The 3rd note in the 5th bar does not have a visible accidental');

    bar2 = staff[2];
    noterest5 = bar2.NthBarObject(1);
    note5 = noterest5[0];
    output = sibmei.HasVisibleAccidental(note5);
    assert.NotOK(output, 'The 2nd note in the 2nd bar does not have a visible accidental');

    bar3 = staff[3];
    noterest6 = bar3.NthBarObject(0);
    note6 = noterest6[0];
    output = sibmei.HasVisibleAccidental(note6);
    assert.OK(output, 'The 1st note in the 3rd bar has a visible natural.');

    noterest7 = bar5.NthBarObject(3);
    note7 = noterest7[0];
    output = sibmei.HasVisibleAccidental(note7);
    assert.OK(output, 'The 3rd note in the 5th bar has a visible B quarter-flat.');

    bar6 = staff[6];
    noterest8 = bar6.NthBarObject(0);
    note8 = noterest8[0];
    output = sibmei.HasVisibleAccidental(note8);
    assert.OK(output, 'The 1st note in the 6th bar has a visible C double-sharp.');

    noterest9 = bar6.NthBarObject(3);
    note9 = noterest9[0];
    output = sibmei.HasVisibleAccidental(note9);
    assert.NotOK(output, 'The 3rd note in the 6th bar does not have a visible C quarter-sharp.');

    bar7 = staff[7];
    noterest10 = bar7.NthBarObject(1);
    note10 = noterest10[0];
    output = sibmei.HasVisibleAccidental(note10);
    assert.OK(output, 'The 2nd note in the 7th bar has a visible F natural');
    noterest11 = bar7.NthBarObject(2);
    note11 = noterest11[0];
    output = sibmei.HasVisibleAccidental(note11);
    assert.NotOK(output, 'The 3rd note in the 7th bar has a hidden C sharp');
}  //$end

function TestOctavaConverter (assert, plugin) {
    //$module(TestExportConverters.mss)
    oct = sibmei.ConvertOctava('line.staff.octava.minus15');
    assert.Equal(oct[0], '15', 'The octava should be two octaves below');
    assert.Equal(oct[1], 'below', 'The octava should be below');
}  //$end

function TestNamedTimeSignatureConverter (assert, plugin) {
    //$module(TestExportConverters.mss)
    common_ts = sibmei.ConvertNamedTimeSignature(CommonTimeString);
    assert.Equal(common_ts, 'common', 'The Time Signature should be common');

    cut_ts = sibmei.ConvertNamedTimeSignature(AllaBreveTimeString);
    assert.Equal(cut_ts, 'cut', 'The Time Signature should be cut');

    other_ts = sibmei.ConvertNamedTimeSignature('4\n4');
    assert.Equal(other_ts, ' ', 'The function should return an empty string for other time signatures');
}  //$end

function TestKeySignatureConverter (assert, plugin) {
    //$module(TestExportConverters.mss)
    keyC = sibmei.ConvertKeySignature(0);
    assert.Equal(keyC, '0', 'The Key of C has 0 sharps or flats');

    atonalK = sibmei.ConvertKeySignature(-8);
    assert.Equal(atonalK, '0', 'Atonal key signatures have 0 sharps or flats');

    keyG = sibmei.ConvertKeySignature(1);
    assert.Equal(keyG, '1s', 'The key of G has 1 sharp');

    keyF = sibmei.ConvertKeySignature(-1);
    assert.Equal(keyF, '1f', 'The key of F has 1 flat');
}  //$end

function TestClefConverter (assert, plugin) {
    //$module(TestExportConverters.mss)
    gClef = sibmei.ConvertClef('clef.treble');
    assert.Equal(gClef[0], 'G', 'The clef shape of a treble is G');
    assert.Equal(gClef[1], '2', 'The clef line of a treble is 2');
    assert.Equal(gClef[2], ' ', 'No displacement on this clef');
    assert.Equal(gClef[3], ' ', 'No direction on this clef');

    gDown = sibmei.ConvertClef('clef.treble.down.8');
    assert.Equal(gDown[0], 'G', 'The clef shape of an octava treble is G');
    assert.Equal(gDown[1], '2', 'The clef line of an octava treble is 2');
    assert.Equal(gDown[2], '8', 'An octave displacement on this clef');
    assert.Equal(gDown[3], 'below', 'Below direction on this clef');

    mezzoS = sibmei.ConvertClef('clef.soprano.mezzo');
    assert.Equal(mezzoS[0], 'C', 'The clef shape of a mezzo is C');
    assert.Equal(mezzoS[1], '2', 'The clef line of a mezzo is 2');
    assert.Equal(mezzoS[2], ' ', 'No displacement on this clef');
    assert.Equal(mezzoS[3], ' ', 'No direction on this clef');

    baritoneF = sibmei.ConvertClef('clef.baritone.f');
    assert.Equal(baritoneF[0], 'F', 'The clef shape of a baritone F is F');
    assert.Equal(baritoneF[1], '3', 'The clef line of a baritone F is 3');
    assert.Equal(baritoneF[2], ' ', 'No displacement on this clef');
    assert.Equal(baritoneF[3], ' ', 'No direction on this clef');
}  //$end

function TestBracketConverter (assert, plugin) {
    //$module(TestExportConverters.mss)
    bkt = sibmei.ConvertBracket(BracketFull);
    assert.Equal(bkt, 'bracket', 'Should convert a bracket');

    brace = sibmei.ConvertBracket(BracketBrace);
    assert.Equal(brace, 'brace', 'Should convert a brace');

    line = sibmei.ConvertBracket(BracketSub);
    assert.Equal(line, 'line', 'Should convert a sub-bracket to a line.');
}  //$end

function TestPositionToTimestampConverter (assert, plugin) {
    //$module(TestExportConverters.mss)
    score = CreateEmptyTestScore(1, 3);

    bar1 = score.SystemStaff.NthBar(1);
    bar1.AddTimeSignature(4, 4, false, false);
    position = 256;
    tstamp = sibmei.ConvertPositionToTimestamp(position, bar1);
    assert.Equal(tstamp, 2, 'The note is on the second beat in 4/4');

    bar2 = score.SystemStaff.NthBar(2);
    bar2.AddTimeSignature(6, 8, false, false);
    position = 128;
    tstamp = sibmei.ConvertPositionToTimestamp(position, bar2);
    assert.Equal(tstamp, 2, 'A note in position 128 is on the second beat in 6/8');

    tstamp = sibmei.ConvertPositionToTimestamp(64, bar2);
    assert.Equal(tstamp, 1.5, 'A note in position 64 is on beat 1.5 in 6/8.');

    position = 0;
    tstamp = sibmei.ConvertPositionToTimestamp(0, bar2);
    assert.Equal(tstamp, 1, 'A note in position 0 is on beat 1 in 6/8');

    bar3 = score.SystemStaff.NthBar(3);
    bar3.AddTimeSignature(12, 8, false, false);

    position = 384;
    tstamp = sibmei.ConvertPositionToTimestamp(position, bar3);
    assert.Equal(tstamp, 4, 'A note in position 384 is on beat 3 in 12/8');
}  //$end

function TestConvertTimeStamp (assert, plugin) {
    //$module(TestExportConverters.mss)

    //Case 1: only seconds with milliseconds
    time1 = 4500;
    tstamp1 = sibmei.ConvertTimeStamp(time1);
    assert.Equal(tstamp1, '00:00:04.5', '4500 milliseconds are 4.5 seconds');

    //Case 2: minutes, seconds with milliseconds
    time2 = 75200;
    tstamp2 = sibmei.ConvertTimeStamp(time2);
    assert.Equal(tstamp2, '00:01:15.2', '75200 milliseconds are should be converted to 00:01:15.2');

    //Case 3: hours, minutes, seconds with milliseconds
    time3 = 3845800;
    tstamp3 = sibmei.ConvertTimeStamp(time3);
    assert.Equal(tstamp3, '01:04:05.8', '3845800 milliseconds are should be converted to 01:04:05.8');

    //Case 4: a very long piece (over 10 hours)
    time4 = 39634700;
    tstamp4 = sibmei.ConvertTimeStamp(time4);
    assert.Equal(tstamp4, '11:00:34.7', '39634700 milliseconds are should be converted to 11:00:34.7');

}   //$end

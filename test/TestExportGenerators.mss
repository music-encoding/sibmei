function TestExportGenerators (suite) {
    //$module(TestExportGenerators.mss)
    suite
        .Add('TestGenerateMEIHeader')
        .Add('TestGenerateMEIMusic')
        .Add('TestGenerateMusicWithLyrics')
        .Add('TestGenerateMusicWithEndings')
        .Add('TestGenerateStaffGroups')
        ;
} //$end

function TestGenerateMEIHeader (assert, plugin) {
    //$module(TestExportGenerators.mss)
    libmei.destroy();

    score = Sibelius.New('Blank');
    score.Title = 'My great title';
    score.PartName = 'A part name';
    score.Subtitle = 'A subtitle';
    score.Dedication = 'Dedicated to everyone everywhere';
    score.Composer = 'John Composer';
    score.Lyricist = 'Jean Lyricist';
    score.Arranger = 'Giovanni Arranger';
    score.Copyist = 'Juan Copyist';
    score.Artist = 'Joan Artist';
    score.Publisher = 'Joel Publisher';
    score.InstrumentChanges = 'The value of instrument changes goes here';
    score.Copyright = 'Copyright © 2015 John Composer and Friends';
    score.OpusNumber = '1';
    score.ComposerDates = '1900-1910';
    score.YearOfComposition = '2015';
    score.OtherInformation = 'Hello World!';
    
    sibmei2._property:ActiveScore = score;

    m = sibmei2.GenerateMEIHeader();

    mei = libmei.Mei();
    libmei.setDocumentRoot(mei);
    libmei.AddChild(mei, m);

    d = libmei.getDocument();
    e = libmei.meiDocumentToFile(d, '/tmp/header.mei');
    assert.True(e, 'The file /tmp/header.mei was successfully generated');

    libmei.destroy();

    Sibelius.CloseWindow(False);
}  //$end

function TestGenerateMEIMusic (assert, plugin) {
    //$module(TestExportGenerators.mss)
    libmei.destroy();

    score = Sibelius.New('Treble Staff');
    staff = score.NthStaff(1);
    barCount = staff.BarCount;

    counter = 0;
    for j = 0 to barCount - 11
    {
        extrabar = staff.NthBar(10);
        extrabar.Delete();
    }

    bar = staff.NthBar(1);
    // middle C
    bar.AddNote(0, 60, 256);

    // CMaj Chord
    bar.AddNote(256, 60, 256);
    bar.AddNote(256, 64, 256);
    bar.AddNote(256, 67, 256);

    // E-flat
    bar.AddNote(512, 63, 256);

    // E-flat with gestural accidental
    bar.AddNote(768, 63, 256);

    bar = staff.NthBar(2);
    n1 = bar.AddNote(0, 60, 128);
    n1.ParentNoteRest.Beam = StartBeam;
    n2 = bar.AddNote(128, 62, 128);
    n3 = bar.AddNote(256, 60, 64);
    n3.Beam = ContinueBeam;

    n4 = bar.AddNote(320, 62, 64);
    n4.Beam = StartBeam;

    bar = staff.NthBar(3);
    n1 = bar.AddNote(0, 74, 768);
    n2 = bar.AddNote(768, 72, 128);
    n2.Beam = StartBeam;
    n3 = bar.AddNote(896, 71, 128);
    bar.AddLyric(0, 1024, 'mè,', 1, 3, 1);

    bar = staff.NthBar(4);
    n1 = bar.AddNote(0, 74, 256, True);
    n1a = bar.AddNote(0, 77, 256, True);
    n1b = bar.AddNote(0, 72, 256, True);
    n2 = bar.AddNote(256, 74, 256);
    n2a = bar.AddNote(256, 77, 256);
    n2b = bar.AddNote(256, 72, 256);
    n3 = bar.AddNote(512, 72, 512, True);

    slur1 = bar.AddLine(0, 768, 'line.staff.slur.up');

    bar = staff.NthBar(5);
    n1 = bar.AddNote(0, 72, 512, True);
    n2 = bar.AddNote(512, 72, 256);

    bar = staff.NthBar(6);
    t1 = bar.AddTuplet(0, 1, 3, 2, 128);
    n1 = t1.AddNote(0, 72, 128);
    n2 = t1.AddNote(128, 72, 128);
    n3 = t1.AddNote(256, 72, 128);

    sibmei2._property:ActiveScore = score;
    music = sibmei2.GenerateMEIMusic();

    m = libmei.Mei();
    libmei.AddChild(m, music);

    libmei.setDocumentRoot(m);

    d = libmei.getDocument();
    e = libmei.meiDocumentToFile(d, '/tmp/testmusic.mei');
    libmei.destroy();
    
    //assert.True(e, 'The file /tmp/testmusic.mei was successfully generated');
}  //$end

function TestGenerateMusicWithLyrics (assert, plugin) {
    //$module(TestExportGenerators.mss)
    libmei.destroy();

    score = Sibelius.New('Treble Staff');
    staff = score.NthStaff(1);
    barCount = staff.BarCount;

    counter = 0;
    for j = 0 to barCount - 11
    {
        extrabar = staff.NthBar(10);
        extrabar.Delete();
    }

    bar = staff.NthBar(1);
    n1 = bar.AddNote(0, 60, 256);
    n2 = bar.AddNote(256, 60, 256);
    n3 = bar.AddNote(512, 60, 256);
    n4 = bar.AddNote(768, 60, 256);

    l1 = bar.AddLyric(0, 256, 'So', 0, 1, 1);
    l1v2 = bar.AddLyric(0, 512, 'Sa', 0, 2, 1);
    l1v2.StyleId = 'text.staff.space.hypen.lyrics.verse2';

    l2 = bar.AddLyric(256, 256, 'na', 0, 1, 1);
    // l2v2 = bar.AddLyric(256, 256, 'ne', 0, 2, 1);
    // l2v2.StyleId = 'text.staff.space.hypen.lyrics.verse2';

    l3 = bar.AddLyric(512, 256, 'mé', 0, 1, 1);
    l3v2 = bar.AddLyric(512, 256, 'mà', 0, 1, 1);
    l3v2.StyleId = 'text.staff.space.hypen.lyrics.verse2';

    l4 = bar.AddLyric(768, 256, 'tu', 1, 1, 1);
    l4v2 = bar.AddLyric(768, 256, 'tü', 1, 1, 1);
    l4v2.StyleId = 'text.staff.space.hypen.lyrics.verse2';

    sibmei2._property:ActiveScore = score;
    music = sibmei2.GenerateMEIMusic();

    m = libmei.Mei();
    libmei.AddChild(m, music);

    libmei.setDocumentRoot(m);

    d = libmei.getDocument();
    e = libmei.meiDocumentToFile(d, '/tmp/testlyrics.mei');
    libmei.destroy();

}  //$end

function TestGenerateMusicWithEndings (assert, plugin) {
    //$module(TextExportGenerators.mss)
    libmei.destroy();

    score = Sibelius.New('Solo Instruments/Piano');
    staff = score.NthStaff(1);
    barCount = staff.BarCount;

    bar = staff.NthBar(1);
    n1 = bar.AddNote(0, 72, 1024);

    bar = staff.NthBar(2);
    b1 = bar.AddLine(0, 1024, 'line.system.repeat.1st');
    n1 = bar.AddNote(0, 72, 1024);

    bar = staff.NthBar(3);
    b2 = bar.AddLine(0, 1024, 'line.system.repeat.1st_n_2nd');
    n2 = bar.AddNote(0, 72, 1024);

    bar = staff.NthBar(4);
    b3 = bar.AddLine(0, 1024, 'line.system.repeat.2nd');
    n3 = bar.AddNote(0, 72, 1024);

    bar = staff.NthBar(5);
    b4 = bar.AddLine(0, 1024, 'line.system.repeat.2nd.closed');
    n4 = bar.AddNote(0, 72, 1024);

    bar = staff.NthBar(6);
    b5 = bar.AddLine(0, 1024, 'line.system.repeat.3rd');
    n5 = bar.AddNote(0, 72, 1024);

    bar = staff.NthBar(7);
    b6 = bar.AddLine(0, 1024, 'line.system.repeat.closed');
    n6 = bar.AddNote(0, 72, 1024);

    bar = staff.NthBar(8);
    b7 = bar.AddLine(0, 1024, 'line.system.repeat.open');
    n7 = bar.AddNote(0, 72, 1024);

    sibmei2._property:ActiveScore = score;
    music = sibmei2.GenerateMEIMusic();

    m = libmei.Mei();
    libmei.AddChild(m, music);

    libmei.setDocumentRoot(m);

    d = libmei.getDocument();
    e = libmei.meiDocumentToFile(d, '/tmp/testendings.mei');
    libmei.destroy();
}  //$end

function TestGenerateStaffGroups (assert, plugin) {
    //$module(TestExportGenerators.mss)
    libmei.destroy();

    score = Sibelius.New('Orchestral/Orchestra, Romantic');
    sibmei2._property:ActiveScore = score;
    staffgroups = sibmei2.GenerateStaffGroups(score);

    // this is not valid MEI, but it should render correctly.
    m = libmei.Mei();
    libmei.AddChild(m, staffgroups);

    libmei.setDocumentRoot(m);

    d = libmei.getDocument();
    e = libmei.meiDocumentToFile(d, '/tmp/staffgroups.mei');
    assert.True(e, 'The file /tmp/staffgroups.mei was successfully generated');

    libmei.destroy();
}  //$end

// function TestRandomIDGenerator (assert, plugin) {
//     //$module(TestExportGenerators.mss)
//     randomnum = sibmei2.GenerateRandomID();
//     assert.Equal(randomnum.Length, 14, 'MEI Short IDs are 14 characters long.');
// }  //$end

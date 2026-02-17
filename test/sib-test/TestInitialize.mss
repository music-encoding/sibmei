function TestInitialize (suite) {
    // Test global values created in Initialize.mss
    suite
        .Add('TestDurByDuration')
        .Add('TestDotsByDuration')
    ;
} //$end


function TestDurByDuration (assert, plugin) {
    pairs = CreateDictionary(
        128, 8,
        128 + 64, 8,
        128 + 64 + 32, 8,
        1024, 1,
        2048, 'breve',
        4096, 'long',
        4096 + 2048, 'long'
    );
    for each Name duration in pairs
    {
        dur = pairs[duration];
        assert.Equal(DurByDuration[duration], dur, duration & ' => @dur=' & dur);
    }
}  //$end


function TestDotsByDuration (assert, plugin) {
    pairs = CreateDictionary(
        128, '',
        128 + 64, 1,
        128 + 64 + 32, 2,
        128 + 64 + 32 + 16, 3,
        1024, '',
        2024, '',
        4096, '',
        4096 + 2048, 1
    );
    for each Name duration in pairs
    {
        dots = pairs[duration];
        if ('' = dots)
        {
            assert.Equal('', DotsByDuration[duration], duration & ' => no dots');
        }
        else
        {
            assert.Equal(DotsByDuration[duration], dots, duration & ' => @dots=' & dots);
        }
    }
}  //$end

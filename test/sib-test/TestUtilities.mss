function TestUtilities (suite) {
    //$module(TestUtilities)
    suite
        .Add('TestMSplitString')
        .Add('TestSplitStringIncludeDelimiters')
        .Add('TestPrevPow2')
        .Add('TestGetTemplateElementsByTagName')
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

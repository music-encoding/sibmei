function TestUtilities (suite) {
    //$module(TestUtilities)
    suite
        .Add('TestMSplitString')
        .Add('TestSplitStringIncludeDelimiters')
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


function TestGetTemplateElementsByTagName (assert, plugin) {
    template = @Element('foo', @Attrs('n', 0),
        @Element('bar', null,
            @Element('foo', @Attrs('n', 1))
        ),
        @Element('foo', @Attrs('n', 2), 'Text child')
    );

    fooElements = sibmei.GetTemplateElementsByTagName(template, 'foo');
    assert.Equal(fooElements.Length, 3, 'Expected number of <foo> elements');
    for n = 0 to fooElements.Length
    {
        fooElement = fooElements[n];
        assert.Equal(fooElement[1].n, n, 'Expected order');
    }
}  //$end

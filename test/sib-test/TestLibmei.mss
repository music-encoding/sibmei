function TestLibmei (suite) {
    //$module(TestLibmei.mss)
    suite
        .Add('TestElementCreate')
        .Add('TestNamedElementCreate')
        .Add('TestAttributeCreate')
        .Add('TestChildElementAdd')
        .Add('TestChildElementRemove')
        .Add('TestDocumentObjectsCreated')
        .Add('TestDocumentObjectsDestroyed')
        .Add('TestGetElementById')
        .Add('TestMEIXMLOutput')
        .Add('TestMEIFileWriting')
        .Add('TestRemoveKeyFromDictionary')
        .Add('TestGetSetId')
        .Add('TestEncodeEntities')
        ;
} //$end

function TestElementCreate (assert, plugin) {
    //$module(TestLibmei.mss)
    el = CreateElement('note', null);
    nm = GetName(el);
    assert.Equal(nm, 'note', 'The name of the element should be note');
    assert.OK(null != GetId(el), 'The ID should not be null');

    InitXml();
}  //$end

function TestNamedElementCreate (assert, plugin) {
    //$module(TestLibmei.mss)
    el = CreateElement('note');
    nm = GetName(el);
    assert.Equal(nm, 'note', 'The named element creator should create a note');
    assert.OK(null != GetId(el), 'The ID should not be null');

    InitXml();
}  //$end

function TestAttributeCreate (assert, plugin) {
    //$module(TestLibmei.mss)
    el = CreateElement('note');
    AddAttribute(el, 'pname', 'c');
    at = GetAttribute(el, 'pname');
    assert.Equal(at, 'c', 'The attribute value should be c');

    InitXml();
}  //$end

function TestChildElementAdd (assert, plugin) {
    //$module(TestLibmei.mss)
    parent = CreateElement('note');
    child = CreateElement('accid');
    AddChild(parent, child);
    children = GetChildren(parent);
    assert.Equal(children.Length, 1, 'The parent should have one child');
    accid = children[0];
    assert.Equal(GetName(child), 'accid', 'The name of the child should be accid');

    InitXml();
}  //$end

function TestChildElementRemove (assert, plugin) {
    //$module(TestLibmei.mss)
    parent = CreateElement('note');
    child1 = CreateElement('accid');
    child2 = CreateElement('accid');
    c2id = child2._id;

    AddChild(parent, child1);
    AddChild(parent, child2);

    assert.Equal(parent.children.Length, 2, 'The parent should have two children');

    RemoveChild(parent, child1);
    assert.Equal(parent.children.Length, 1, 'After removal, the parent should only have one child');
    assert.Equal(parent.children[0], c2id, 'The child that remains should be child 2');

    InitXml();
}  //$end

function TestDocumentObjectsCreated (assert, plugin) {
    //$module(TestLibmei.mss)
    t = Self._property:MEIDocument;
    f = Self._property:MEIFlattened;
    assert.OK(null != t, 'The MEI Tree should not be null');
    assert.OK(null != f, 'The flattened tree should not be null');
}  //$end

function TestDocumentObjectsDestroyed (assert, plugin) {
    //$module(TestLibmei.mss)
    root = CreateElement('mei');
    SetDocumentRoot(root);

    m = GetDocumentRoot();
    assert.OK(null != m, 'The document root should not be null');

    t = Self._property:MEIDocument;
    f = Self._property:MEIFlattened;
    assert.OK((t.Length > 0), 'There should be elements in the MEI Document Tree');
    assert.OK((f.GetPropertyNames().Length > 0), 'There should be elements in the Flattened MEI Structure');

    InitXml();

    t = Self._property:MEIDocument;
    f = Self._property:MEIFlattened;
    assert.NotOK((t.Length > 0), 'There should not be elements in the MEI Document Tree');
    assert.NotOK((f.GetPropertyNames().Length > 0), 'There should not be elements in the Flattened MEI Structure');

    InitXml();
}  //$end

function TestGetElementById (assert, plugin) {
    //$module(TestLibmei.mss)
    root = CreateElement('mei');
    SetDocumentRoot(root);

    head = CreateElement('meiHead');
    music = CreateElement('music');
    AddChild(root, head);
    AddChild(root, music);

    s = GetElementById(music._id);
    assert.OK(null != s, 'The music element should not be null');

    InitXml();
}  //$end

function TestMEIXMLOutput (assert, plugin) {
    //$module(TestLibmei.mss)
    mei = CreateElement('mei');
    meiHead = CreateElement('meiHead');
    music = CreateElement('music');

    SetDocumentRoot(mei);
    AddChild(mei, meiHead);
    AddChild(mei, music);

    d = Self._property:MEIDocument;
    m = MeiDocumentToString(d);

    assert.OK(null != m, 'The MEI Document output should not be null');
    InitXml();
}  //$end

function TestMEIFileWriting (assert, plugin) {
    //$module(TestLibmei.mss)

    InitXml();

    mei = CreateElement('mei');
    meiHead = CreateElement('meiHead');
    music = CreateElement('music');

    SetDocumentRoot(mei);
    AddChild(mei, meiHead);
    AddChild(mei, music);

    d = GetDocument();
    filePath = Self._property:tempDir & 'foo.mei';
    m = MeiDocumentToFile(d, filePath);

    assert.OK(m, 'The MEI File was successfully written to ' & filePath);

    InitXml();
}  //$end

function TestRemoveKeyFromDictionary (assert, plugin) {
    //$module(TestLibmei.mss)
    d = CreateDictionary('foo', 'bar', 'bif', 'baz');
    assert.OK(d.PropertyExists('foo'), 'The property foo should exist');

    dprime = RemoveKeyFromDictionary(d, 'foo');
    assert.NotOK(dprime.PropertyExists('foo'), 'The property foo should no longer exist');
}  //$end

function TestGetSetId (assert, plugin) {
    //$module(TestLibmei.mss)
    el = CreateElement('mei');
    id = GetId(el);
    assert.OK(null != id, 'The ID should not be null');

    inDocument = GetElementById(id);
    assert.OK(null != inDocument, 'The ID should be in the MEI Document');

    SetId(el, 'newId');
    inDocument = GetElementById(id);
    assert.OK(null = inDocument, 'The old ID key should return a null when a new ID has been set.');
    newInDocument = GetElementById('newId');
    assert.OK(null != newInDocument, 'The new ID should return the object');

    InitXml();
}  //$end

function TestEncodeEntities (assert, plugin) {
    _AssertEntityEncoding(assert, 'abc&def', 'abc&amp;def');
    _AssertEntityEncoding(assert, '<abc' & Chr(34), '&lt;abc&quot;');
    _AssertEntityEncoding(assert, 'abc', 'abc');
    _AssertEntityEncoding(assert, '', '');
    _AssertEntityEncoding(assert, '&&', '&amp;&amp;');
}  //$end

function _AssertEntityEncoding (assert, string, expectedEncoding) {
    assert.Equal(EncodeEntities(string), expectedEncoding, string);
}  //$end

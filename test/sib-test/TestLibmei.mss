function TestLibmei (suite) {
    //$module(TestLibmei.mss)
    suite
        .Add('TestElementCreate')
        .Add('TestNamedElementCreate')
        .Add('TestElementCreateWithExistingID')
        .Add('TestAttributeCreate')
        .Add('TestChildElementAdd')
        .Add('TestChildElementRemove')
        .Add('TestDocumentObjectsCreated')
        .Add('TestDocumentObjectsDestroyed')
        .Add('TestGetElementByName')
        .Add('TestMEIXMLOutput')
        .Add('TestMEIFileWriting')
        .Add('TestRemoveKeyFromDictionary')
        .Add('TestGetSetId')
        ;
} //$end

function TestElementCreate (assert, plugin) {
    //$module(TestLibmei.mss)
    el = libmei.CreateElement('note', null);
    nm = libmei.GetName(el);
    assert.Equal(nm, 'note', 'The name of the element should be note');
    assert.OK(null != libmei.GetId(el), 'The ID should not be null');

    libmei.destroy();
}  //$end

function TestNamedElementCreate (assert, plugin) {
    //$module(TestLibmei.mss)
    el = libmei.Note();
    nm = libmei.GetName(el);
    assert.Equal(nm, 'note', 'The named element creator should create a note');
    assert.OK(null != libmei.GetId(el), 'The ID should not be null');

    libmei.destroy();
}  //$end

function TestElementCreateWithExistingID (assert, plugin) {
    //$module(TestLibmei.mss)
    el = libmei.CreateElement('note', 'm-123');
    id = libmei.GetId(el);
    assert.Equal(id, 'm-123', 'The ID of the element should be m-123');

    libmei.destroy();
}  //$end

function TestAttributeCreate (assert, plugin) {
    //$module(TestLibmei.mss)
    el = libmei.Note();
    libmei.AddAttribute(el, 'pname', 'c');
    at = libmei.GetAttribute(el, 'pname');
    assert.Equal(at, 'c', 'The attribute value should be c');

    libmei.destroy();
}  //$end

function TestChildElementAdd (assert, plugin) {
    //$module(TestLibmei.mss)
    parent = libmei.Note();
    child = libmei.Accid();
    libmei.AddChild(parent, child);
    children = libmei.GetChildren(parent);
    assert.Equal(children.Length, 1, 'The parent should have one child');
    accid = children[0];
    assert.Equal(libmei.GetName(child), 'accid', 'The name of the child should be accid');

    libmei.destroy();
}  //$end

function TestChildElementRemove (assert, plugin) {
    //$module(TestLibmei.mss)
    parent = libmei.Note();
    child1 = libmei.Accid();
    child2 = libmei.Accid();
    c2id = child2._id;

    libmei.AddChild(parent, child1);
    libmei.AddChild(parent, child2);

    assert.Equal(parent.children.Length, 2, 'The parent should have two children');

    libmei.RemoveChild(parent, child1);
    assert.Equal(parent.children.Length, 1, 'After removal, the parent should only have one child');
    assert.Equal(parent.children[0], c2id, 'The child that remains should be child 2');

    libmei.destroy();
}  //$end

function TestDocumentObjectsCreated (assert, plugin) {
    //$module(TestLibmei.mss)
    t = libmei._property:MEIDocument;
    f = libmei._property:MEIFlattened;
    assert.OK(null != t, 'The MEI Tree should not be null');
    assert.OK(null != f, 'The flattened tree should not be null');
}  //$end

function TestDocumentObjectsDestroyed (assert, plugin) {
    //$module(TestLibmei.mss)
    root = libmei.Mei();
    libmei.setDocumentRoot(root);

    m = libmei.getDocumentRoot();
    assert.OK(null != m, 'The document root should not be null');

    t = libmei._property:MEIDocument;
    f = libmei._property:MEIFlattened;
    assert.OK((t.Length > 0), 'There should be elements in the MEI Document Tree');
    assert.OK((f.GetPropertyNames().Length > 0), 'There should be elements in the Flattened MEI Structure');

    libmei.destroy();

    t = libmei._property:MEIDocument;
    f = libmei._property:MEIFlattened;
    assert.NotOK((t.Length > 0), 'There should not be elements in the MEI Document Tree');
    assert.NotOK((f.GetPropertyNames().Length > 0), 'There should not be elements in the Flattened MEI Structure');

    libmei.destroy();
}  //$end

function TestGetElementByName (assert, plugin) {
    //$module(TestLibmei.mss)
    root = libmei.Mei();
    libmei.setDocumentRoot(root);

    head = libmei.CreateElement('meiHead', 'm-head');
    music = libmei.CreateElement('music', 'm-music');
    libmei.AddChild(root, head);
    libmei.AddChild(root, music);

    s = libmei.getElementById('m-music');
    assert.OK(null != s, 'The music element should not be null');

    libmei.destroy();
}  //$end

function TestMEIXMLOutput (assert, plugin) {
    //$module(TestLibmei.mss)
    mei = libmei.Mei();
    meiHead = libmei.MeiHead();
    music = libmei.Music();

    libmei.setDocumentRoot(mei);
    libmei.AddChild(mei, meiHead);
    libmei.AddChild(mei, music);

    d = libmei._property:MEIDocument;
    m = libmei.meiDocumentToString(d);

    assert.OK(null != m, 'The MEI Document output should not be null');
    libmei.destroy();
}  //$end

function TestMEIFileWriting (assert, plugin) {
    //$module(TestLibmei.mss)

    libmei.destroy();

    mei = libmei.Mei();
    meiHead = libmei.MeiHead();
    music = libmei.Music();

    libmei.setDocumentRoot(mei);
    libmei.AddChild(mei, meiHead);
    libmei.AddChild(mei, music);

    d = libmei.getDocument();
    filePath = Self._property:tempDir & 'foo.mei';
    m = libmei.meiDocumentToFile(d, filePath);

    assert.OK(m, 'The MEI File was successfully written to ' & filePath);

    libmei.destroy();
}  //$end

function TestRemoveKeyFromDictionary (assert, plugin) {
    //$module(TestLibmei.mss)
    d = CreateDictionary('foo', 'bar', 'bif', 'baz');
    assert.OK(d.PropertyExists('foo'), 'The property foo should exist');

    dprime = libmei.removeKeyFromDictionary(d, 'foo');
    assert.NotOK(dprime.PropertyExists('foo'), 'The property foo should no longer exist');
}  //$end

function TestGetSetId (assert, plugin) {
    //$module(TestLibmei.mss)
    el = libmei.Mei();
    id = libmei.GetId(el);
    assert.OK(null != id, 'The ID should not be null');

    inDocument = libmei.getElementById(id);
    assert.OK(null != inDocument, 'The ID should be in the MEI Document');

    libmei.SetId(el, 'newId');
    inDocument = libmei.getElementById(id);
    assert.OK(null = inDocument, 'The old ID key should return a null when a new ID has been set.');
    newInDocument = libmei.getElementById('newId');
    assert.OK(null != newInDocument, 'The new ID should return the object');

    libmei.destroy();
}  //$end

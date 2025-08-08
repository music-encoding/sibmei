function TestXml (suite) {
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
        .Add('TestElementsUsedInTemplates')
        ;
} //$end

function TestElementCreate (assert, plugin) {
    el = CreateElement('note', null);
    nm = GetName(el);
    assert.Equal(nm, 'note', 'The name of the element should be note');
    assert.OK(null != GetId(el), 'The ID should not be null');

    ResetXml();
}  //$end

function TestNamedElementCreate (assert, plugin) {
    el = CreateElement('note');
    nm = GetName(el);
    assert.Equal(nm, 'note', 'The named element creator should create a note');
    assert.OK(null != GetId(el), 'The ID should not be null');

    ResetXml();
}  //$end

function TestAttributeCreate (assert, plugin) {
    el = CreateElement('note');
    AddAttribute(el, 'pname', 'c');
    at = GetAttribute(el, 'pname');
    assert.Equal(at, 'c', 'The attribute value should be c');

    ResetXml();
}  //$end

function TestChildElementAdd (assert, plugin) {
    parent = CreateElement('note');
    child = CreateElement('accid');
    AddChild(parent, child);
    children = GetChildren(parent);
    assert.Equal(children.Length, 1, 'The parent should have one child');
    accid = children[0];
    assert.Equal(GetName(child), 'accid', 'The name of the child should be accid');

    ResetXml();
}  //$end

function TestChildElementRemove (assert, plugin) {
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

    ResetXml();
}  //$end

function TestDocumentObjectsCreated (assert, plugin) {
    t = Self._property:MEIDocument;
    f = Self._property:MEIFlattened;
    assert.OK(null != t, 'The MEI Tree should not be null');
    assert.OK(null != f, 'The flattened tree should not be null');
}  //$end

function TestDocumentObjectsDestroyed (assert, plugin) {
    root = CreateElement('mei');
    SetDocumentRoot(root);

    m = GetDocumentRoot();
    assert.OK(null != m, 'The document root should not be null');

    t = Self._property:MEIDocument;
    f = Self._property:MEIFlattened;
    assert.OK((t.Length > 0), 'There should be elements in the MEI Document Tree');
    assert.OK((f.GetPropertyNames().Length > 0), 'There should be elements in the Flattened MEI Structure');

    ResetXml();

    t = Self._property:MEIDocument;
    f = Self._property:MEIFlattened;
    assert.NotOK((t.Length > 0), 'There should not be elements in the MEI Document Tree');
    assert.NotOK((f.GetPropertyNames().Length > 0), 'There should not be elements in the Flattened MEI Structure');

    ResetXml();
}  //$end

function TestGetElementById (assert, plugin) {
    root = CreateElement('mei');
    SetDocumentRoot(root);

    head = CreateElement('meiHead');
    music = CreateElement('music');
    AddChild(root, head);
    AddChild(root, music);

    s = GetElementById(music._id);
    assert.OK(null != s, 'The music element should not be null');

    ResetXml();
}  //$end

function TestMEIXMLOutput (assert, plugin) {
    mei = CreateElement('mei');
    meiHead = CreateElement('meiHead');
    music = CreateElement('music');

    SetDocumentRoot(mei);
    AddChild(mei, meiHead);
    AddChild(mei, music);

    d = Self._property:MEIDocument;
    m = MeiDocumentToString(d);

    assert.OK(null != m, 'The MEI Document output should not be null');
    ResetXml();
}  //$end

function TestMEIFileWriting (assert, plugin) {

    ResetXml();

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

    ResetXml();
}  //$end

function TestRemoveKeyFromDictionary (assert, plugin) {
    d = CreateDictionary('foo', 'bar', 'bif', 'baz');
    assert.OK(d.PropertyExists('foo'), 'The property foo should exist');

    dprime = RemoveKeyFromDictionary(d, 'foo');
    assert.NotOK(dprime.PropertyExists('foo'), 'The property foo should no longer exist');
}  //$end

function TestGetSetId (assert, plugin) {
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

    ResetXml();
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

function TestElementsUsedInTemplates (assert, plugin) {
    for each handlerMap in CreateSparseArray(
        LineHandlers.StyleId,
        LineHandlers.StyleAsText,
        LyricHandlers.StyleId,
        LyricHandlers.StyleAsText,
        SymbolHandlers.Index,
        SymbolHandlers.Name,
        TextHandlers.StyleId,
        TextHandlers.StyleAsText
    )
    {
        for each Name styleId in handlerMap
        {
            handlerDict = handlerMap[styleId];
            if (null != handlerDict['template'])
            {
                _TestTemplate(assert, handlerDict.template, styleId);
            }
        }
    }
} //$end

function _TestTemplate(assert, template, styleId) {
    if (0.0 = styleId and null != styleId)
    {
        // Found `styleId` to be an integer, i.e. we're dealing with a symbol.
        // Strings are cast to 0.0 when compared to numbers, unless they can be
        // parsed as a number, in which case they however are != null.
        // If an integer is equal to 0.0, it is 0 and also equal to null.
        usageDescription = ' Used for symbol with index ' & styleId;
    }
    else
    {
        usageDescription = 'Used for ' & styleId;
    }
    tagName = template[0];
    properties = Schema[tagName];
    if (null = properties)
    {
        return assert.OK(false, tagName & ' is not a valid element name.' & usageDescription);
    }
    if (null != template[1])
    {
        for each Name attributeName in template[1]
        {
            assert.OK(
                // If ' ' is assigned as attribute value, this explicitly
                // suppresses the attribute from being added.
                properties.attributes[attributeName] or template[1].@attributeName = ' ',
                'expect ' & tagName & '/@' & attributeName & ' to be legal.' & usageDescription
            );
        }
    }
    childCount = utils.max(template.Length - 2, 0);
    for childIndex = 0 to childCount
    {
        child = template[childIndex + 2];
        if (IsObject(child) and null = child._property:templateAction)
        {
            childName = child[0];
            if (assert.OK(
                properties.children[childName],
                'expect ' & tagName & '/' & childName & ' to be legal.' & usageDescription
            ))
            {
                _TestTemplate(assert, child, styleId);
            }

        }
    }
} //$end

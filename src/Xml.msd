    XMLComment "(comment) {
    commentObj = CreateElement('<!--', null);
    commentObj.text = comment;
    return commentObj;
}"
CreateElement "(tagname) {
    element = CreateDictionary(
        'name', tagname,
        'attrs', CreateDictionary(),
        'children', CreateSparseArray(),
        'text', '',
        'tail', '',
        '_id', GenerateRandomID(),
        '_parent', null);

    f = Self._property:MEIFlattened;
    f[element._id] = element;

    return element;
}"
GetChildren "(element) {
        c = CreateSparseArray();
        for each child_id in element.children {
            child = Self.MEIFlattened[child_id];
            c.Push(child);
        }
        return c;
}"
SetChildren "(element, childarr) {
        element.children = childarr;
}"
AddChildAtPosition "(element, child, position) {
        AddChild(element, child);
        c = element.children;
        // shift all children that are at a higher index than `position`
        for i = c.Length - 1 to position step -1 {
            c[i] = c[i - 1];
        }
        element.children[position] = child._id;
}"
AddChild "(element, child) {
        cid = child._id;
        child._parent = element._id;
        element.children.Push(cid);
        // The following might be redundant, but in case a child is removed from
        // one parent and added to another, it's safer to re-register the ID.
        Self.MEIFlattened[cid] = child;
}"
RemoveChild "(element, child) {
    child._parent = null;
    UnregisterId(child._id);
    newarr = CreateSparseArray();

    for each elid in element.children
    {
        if (elid != child._id)
        {
            newarr.Push(elid);
        }
    }

    element.children = newarr;
}"
GetAttributes "(element) {
    return element.attrs;
}"
AddAttribute "(element, attrname, attrval) {
    a = element.attrs;
    // check and replace any newlines
    val = _encodeEntities(attrval);
    a[attrname] = val;
}"
AddAttributeValue "(element, attrname, attrval) {
    // appends a value to an existing attribute. Used, for example,
    // in appending multiple articulations to @artic on note.
    a = element.attrs;

    if (a.PropertyExists(attrname))
    {
        origval = a[attrname];
        newval = _encodeEntities(attrval);
        val = origval & ' ' & newval;
    }
    else
    {
        val = attrval;
    }

    element.attrs[attrname] = val;
}"
GetAttribute "(element, attrname) {
        attrs = element.attrs;
        if (attrs.PropertyExists(attrname))
        {
            return attrs[attrname];
        }
        else
        {
            return False;
        }
}"
GetId "(element) {
        return element._id;
}"
SetId "(element, newId) {
    UnregisterId(element._id);
    element._id = newId;
    Self.MEIFlattened[newId] = element;
}"
UnregisterId "(id) {
    olddict = Self._property:MEIFlattened;
    newdict = RemoveKeyFromDictionary(olddict, id);
    Self._property:MEIFlattened = newdict;
}"
RemoveAttribute "(element, attrname) {
    // since there are no delete functions
    // for dictionaries, we set the attribute
    // to a blank space and this will get
    // removed when converted to XML.
    element.attrs[attrname] = ' ';
}"
GetName "(element) {
    return element.name;
}"
SetText "(element, val) {
    element.text = _encodeEntities(val);
}"
GetText "(element) {
    return element.text;
}"
SetTail "(element, val) {
    element.tail = _encodeEntities(val);
}"
GetTail "(element) {
    return element.tail;
}"

    InitXml "() {
        // cleans up
        Self._property:MEIFlattened = CreateDictionary();
        Self._property:MEIDocument = CreateSparseArray();
        Self._property:MEIID = 0;
    }"

    SetDocumentRoot "(el) {
        d = Self._property:MEIDocument;
        d.Push(el);
    }"

    GetDocumentRoot "() {
        d = Self._property:MEIDocument;
        return d[0];
    }"

    GetDocument "() {
        return Self._property:MEIDocument;
    }"

    GetElementById "(id) {
        d = Self._property:MEIFlattened;
        if (d.PropertyExists(id))
        {
            return d[id];
        }
        else
        {
            return null;
        }
    }"

    CreateXmlTag "(name, id, attributesList, isTerminal) {
    if (name = '<!--')
    {
        // handle XML comments
        return name;
    }

    attrstring = '';
    spacer = '';

    if (id != null)
    {
        attrstring = 'xml:id=' & Chr(34) & id & Chr(34);
    }

    if (attributesList != null)
    {
        spacer = ' ';
        for each Pair attr in attributesList
        {
            if (attr.Value != ' ')
            {
                if (attrstring = '')
                {
                    // Don't add initial space
                    attrstring = attr.Name & '=' & Chr(34) & attr.Value & Chr(34);
                }
                else
                {
                    attrstring = attrstring & spacer & attr.Name & '=' & Chr(34) & attr.Value & Chr(34);
                }
            }
        }
    }

    if (isTerminal)
    {
        return '<' & name & spacer & attrstring & '/>';
    }
    else
    {
        return '<' & name & spacer & attrstring & '>';
    }
}"
    ChildHasTail "(children) {
    for each child in children
    {
        if (Length(GetTail(child)) > 0)
        {
            return true;
        }
    }
    return false;
}"
    ConvertDictToXml "(meiel, indent) {
    // The indent parameter includes the leading line break

    xmlout = '';
    terminalTag = true;

    nm = GetName(meiel);
    at = GetAttributes(meiel);
    ch = GetChildren(meiel);
    tx = GetText(meiel);
    tl = GetTail(meiel);
    id = GetId(meiel);

    // comments are simple so they're handled specially.
    if (nm = '<!--')
    {
        xmlout = indent & nm & ' ' & tx & ' -->';
        return xmlout;
    }

    if (ch.Length > 0 or Length(tx) > 0)
    {
        terminalTag = false;
    }

    xmlout = indent & CreateXmlTag(nm, id, at, terminalTag);

    hasTextChild = Length(tx) > 0 or ChildHasTail(ch);

    if (hasTextChild)
    {
        xmlout = xmlout & tx;
        // Adding formatting whitespace might mess up text content
        indent = '';
    }

    if (ch.Length > 0)
    {
        if (indent != '')
        {
            innerIndent = indent & '    ';
        }
        else
        {
            innerIndent = '';
        }

        for each child in ch
        {
            xmlout = xmlout & ConvertDictToXml(child, innerIndent);
        }
    }

    // ConvertDictToXml takes care of adding the />
    // for tags that do not have children. We'll
    // take care of the terminal tag here for those
    // that do.
    if (not terminalTag)
    {
        xmlout = xmlout & indent & '</' & nm & '>';
    }

    if (Length(tl) > 0)
    {
        xmlout = xmlout & tl;
    }

    return xmlout;
}"

    _exportMeiDocument "(meidoc) {
        RNG_URL = 'https://music-encoding.org/schema/' & MeiVersion & '/mei-CMN.rng';
        xdecl = '<?xml version=' & Chr(34) & '1.0' & Chr(34) & ' encoding=' & Chr(34) & 'UTF-16' & Chr(34) & ' ?>';
        schema = '\n<?xml-model href=' & Chr(34) & RNG_URL & Chr(34) & ' type=' & Chr(34) & 'application/xml' & Chr(34) & ' schematypens=' & Chr(34) & 'http://relaxng.org/ns/structure/1.0' & Chr(34) & ' ?>';
        schematron = '\n<?xml-model href=' & Chr(34) & RNG_URL & Chr(34) & ' type=' & Chr(34) & 'application/xml' & Chr(34) & ' schematypens=' & Chr(34) & 'http://purl.oclc.org/dsdl/schematron' & Chr(34) & ' ?>';
        meiout = xdecl & schema & schematron & ConvertDictToXml(meidoc[0], Chr(10));

        return meiout;
    }"

    MeiDocumentToFile "(meidoc, filename) {
        meiout = _exportMeiDocument(meidoc);
        if (Sibelius.CreateTextFile(filename)) {
            return Sibelius.AppendTextFile(filename, meiout, true);
        } else {
            return false;
        }
}"

    MeiDocumentToString "(meidoc) {
        return _exportMeiDocument(meidoc);
    }"
    _encodeEntities "(string)
    {
        /*
            Returns an entity-encoded version of the string.
        */
        if (string = '')
        {
            return string;
        }

        nc = Chr(10);
        quote = Chr(34);
        apos = Chr(39);
        lthan = Chr(60);
        gthan = Chr(62);
        amp = Chr(38);

        // &amp; must go first so it doesn't replace it in the character encoding
        string = utils.Replace(string, amp, '&amp;', true);
        string = utils.Replace(string, nc, '&#10;', true);
        string = utils.Replace(string, quote, '&quot;', true);
        string = utils.Replace(string, apos, '&apos;', true);
        string = utils.Replace(string, lthan, '&lt;', true);
        string = utils.Replace(string, gthan, '&gt;', true);

        return string;
    }"

GenerateRandomID "() {
    id = Self._property:MEIID + 1;
    Self._property:MEIID = id;
    id = 'm-' & id;
    return id;
}"

RemoveKeyFromDictionary "(dict, key) {
    newdict = CreateDictionary();
    for each Pair p in dict
    {
        if (p.Name != key)
        {
            newdict[p.Name] = p.Value;
        }
    }

    return newdict;
}"

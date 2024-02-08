function InitTextHandlers() {
    noAttributes = null;

    Self._property:TextHandlers = CreateDictionary(
        'StyleId', CreateDictionary(),
        'StyleAsText', CreateDictionary()
    );

    RegisterTextHandlers('StyleId', CreateDictionary(
        'text.staff.expression', CreateSparseArray('Dynam', noAttributes, FormattedText),
        'text.staff.plain', CreateSparseArray('AnchoredText', noAttributes, FormattedText),
        'text.staff.space.figuredbass', 'FiguredBassTextHandler',
        'text.staff.technique', CreateSparseArray('Dir', CreateDictionary('label', 'technique'), FormattedText),
        'text.system.page_aligned.composer', CreateSparseArray('AnchoredText', noAttributes, FormattedText),
        'text.system.page_aligned.subtitle', CreateSparseArray(
            'AnchoredText',
            noAttributes,
            CreateSparseArray('Title', CreateDictionary('type', 'subordinate'), FormattedText)
        ),
        'text.system.page_aligned.title', CreateSparseArray(
            'AnchoredText',
            noAttributes,
            CreateSparseArray('Title', noAttributes, FormattedText)
        ),
        'text.system.tempo', CreateSparseArray('Tempo', noAttributes, FormattedText)
    ), Self);
}  //$end


function RegisterTextHandlers (styleIdType, textHandlerDict, plugin) {
    RegisterHandlers(TextHandlers[styleIdType], textHandlerDict, plugin);
}  //$end

function InitTextSubstituteMap() {
    tempSubstituteMap = CreateDictionary(
        'Title', CreateSparseArray('Title'),
        'Subtitle', CreateSparseArray('Title', CreateDictionary('type', 'subordinate')),
        // <dedication> is only allowed on <titlePage> and <creation>, so use
        // generic element
        'Dedication', CreateSparseArray('Seg', CreateDictionary('type', 'Dedication')),
        // <composer>, <arranger>, <lyricist>, <userRestrict> and <publisher>
        // are only allowed in a few places, e.g. metadata or title pages.
        // We therfore use more generic elements
        'Composer', CreateSparseArray('PersName', CreateDictionary('role', 'Composer')),
        'Arranger', CreateSparseArray('PersName', CreateDictionary('role', 'Arranger')),
        'Lyricist', CreateSparseArray('PersName', CreateDictionary('role', 'Lyricist')),
        'Artist', CreateSparseArray('PersName', CreateDictionary('role', 'Artist')),
        // <useRestrict> is only allowed on <titlePage>, so use generic element
        'Copyright', CreateSparseArray('Seg', CreateDictionary('type', 'Copyright')),
        // <publisher> is only allowed in a few places, so use generic element
        // We don't even know if it's a person or an institution
        'Publisher', CreateSparseArray('Seg', CreateDictionary('type', 'Publisher')),
        'MoreInfo', CreateSparseArray('Seg', CreateDictionary('type', 'MoreInfo')),
        'PartName', CreateSparseArray('Seg', CreateDictionary('type', 'PartName'))
    );

    textSubstituteMap = CreateDictionary();

    // The keys in the above table are the names of the properties on the Score
    // objects. The same name can be used for referencing them in text, but the
    // reference is case insensitive, so we register them as all-uppercase in
    // final map.
    for each Name name in tempSubstituteMap {
        tempSubstituteMap[name]._property:propertyName = name;
        textSubstituteMap[utils.UpperCase(name)] = tempSubstituteMap[name];
    }

    return textSubstituteMap;
}  //$end


function FiguredBassTextHandler (this, textObject) {
    // 'text.staff.space.figuredbass'
    harm = GenerateControlEvent(textObject, libmei.Harm());

    // uniquely, for figured bass we do not use the startid here,
    // since a figure can change halfway through a note. So we remove
    // the startid and replace it with corresp, pointing to the
    // same ID.
    startidValue = libmei.GetAttribute(harm, 'startid');
    libmei.RemoveAttribute(harm, 'startid');
    libmei.AddAttribute(harm, 'corresp', startidValue);

    fb = libmei.Fb();
    libmei.AddChild(harm, fb);
    ConvertFbFigures(fb, textObject);
    return harm;
}  //$end


function AddFormattedText (parentElement, textObject) {
    textWithFormatting = textObject.TextWithFormatting;
    if (textWithFormatting.NumChildren < 2 and CharAt(textWithFormatting[0], 0) != '\\')
    {
        // We have a simple text element without special style properties
        if (parentElement.name = 'div')
        {
            p = libmei.P();
            libmei.SetText(p, textObject.Text);
            libmei.AddChild(parentElement, p);
        }
        else
        {
            libmei.SetText(parentElement, textObject.Text);
        }
        return parentElement;
    }

    // At this point we know that we have text with style changes and/or text
    // substitutions
    nodes = CreateSparseArray();

    state = CreateDictionary(
        'currentText', null,
        'style', CreateDictionary(),
        // TODO: Also track the active character style (mainly
        // `\ctext.character.musictext\`, and custom styles)
        'meiNodes', nodes
    );

    for each component in textObject.TextWithFormatting
    {
        switch (Substring(component, 0, 2))
        {
            case ('\\n')
            {
                PushStyledText(state);
                nodes.Push(libmei.Lb());
            }
            case ('\\N')
            {
                PushStyledText(state);
                // TODO: Add <p> if it is allowed within parentElement (use libmei.GetName())
                nodes.Push(libmei.Lb());
            }
            case ('\\B')
            {
                SwitchTextStyle(state, 'fontweight', 'bold');
            }
            case ('\\b')
            {
                SwitchTextStyle(state, 'fontweight', 'normal');
            }
            case ('\\I')
            {
                SwitchTextStyle(state, 'fontstyle', 'italic');
            }
            case ('\\i')
            {
                SwitchTextStyle(state, 'fontstyle', 'normal');
            }
            case ('\\U')
            {
                SwitchTextStyle(state, 'underline', 'underline_on');
            }
            case ('\\u')
            {
                SwitchTextStyle(state, 'underline', 'underline_off');
            }
            case ('\\f')
            {
                font = GetTextCommandArg(component);
                if (font = '_')
                {
                    ResetTextStyles(state);
                }
                else
                {
                    SwitchTextStyle(state, 'fontfam', font);
                }
            }
            case ('\\c')
            {
                // TODO: Can we sensibly handle a character style change? The
                // only built-in one seem to be `text.character.musictext`. We
                // might want to allow Extensions to handle custom character
                // styles.
                ;
            }
            case ('\\s')
            {
                fontsize = ConvertOffsetsToMEI(GetTextCommandArg(component));
                SwitchTextStyle(state, 'fontsize', fontsize);
            }
            case ('\\v')
            {
                // Vertical scale change (vertical stretching). Probably not
                // possible to handle
                ;
            }
            case ('\\h')
            {
                // Horizontal scale change (horizontal stretching). Probably not
                // possible to handle
                ;
            }
            case ('\\t')
            {
                // Tracking. Probably not possible to handle.
                ;
            }
            case ('\\p')
            {
                SwitchTextStyle(state, 'baseline', GetTextCommandArg(component));
            }
            case ('\\$')
            {
                AppendTextSubstitute(state, GetTextCommandArg(component));
            }
            case ('\\\\')
            {
                // According to the documentation, 'backslashes themselves are
                // represented by \\ , to avoid conflicting with the above
                // commands'. Though Sibelius does not seem to allow inputting
                // this, let's still cover it in case Avid fixes this.

                // We strip one leading backspace.
                state.currentText = state.currentText & Substring(component, 1);
            }
            default
            {
                // This is regular text
                state.currentText = state.currentText & component;
            }
        }
    }

    PushStyledText(state);

    nodeCount = nodes.Length;
    precedingElement = null;

    nodeIndex = 0;
    while (nodeIndex < nodeCount)
    {
        node = nodes[nodeIndex];
        if (IsObject(node))
        {
            // We have an element
            libmei.AddChild(parentElement, node);
            precedingElement = node;
        }
        else
        {
            // We have a text node
            text = node;
            // If there are multiple adjacent text nodes, we need to join them
            while (nodeIndex < nodeCount and not IsObject(nodes[nodeIndex + 1]))
            {
                nodeIndex = nodeIndex + 1;
                text = text & nodes[nodeIndex];
            }

            if (precedingElement = null)
            {
                libmei.SetText(parentElement, text);
            }
            else
            {
                libmei.SetTail(precedingElement, text);
            }
        }
        nodeIndex = nodeIndex + 1;
    }
}  //$end


function GetTextCommandArg (command) {
    // Remove leading part, e.g. the '\$' or '\s' and trailing '\'
    return Substring(command, 2, Length(command) - 3);
}  //$end


function ResetTextStyles (state) {
    textNotYetPushed = true;
    style = state.style;

    for each Name property in style
    {
        if (textNotYetPushed and null != style[property])
        {
            // Style changes because we reset this property from non-null value
            // to null. Therefore push the existing text with the old style
            // before resetting it.
            textNotYetPushed = false;
            PushStyledText(state);
        }
        style[property] = null;
    }
}  //$end


function SwitchTextStyle (state, property, value) {
    if (state.style[property] != value)
    {
        // Style changes, so append current text before modifying style state
        PushStyledText(state);
    }
    state.style[property] = value;
}  //$end


function PushStyledText (state) {
    // Any text that has accumulated as `state.currentText` while parsing the
    // styled text is converted to MEI nodes and pushed to `state.meiNodes`,
    // respecting the styling state (`state.style`). `state.currentText` is
    // reset.

    if (state.currentText = '')
    {
        return null;
    }

    styleAttributes = GetStyleAttributes(state);
    if (null = styleAttributes)
    {
        // We attach unstyled text without wrapping it in <rend>
        state.meiNodes.Push(state.currentText);
    }
    else
    {
        rend = libmei.Rend();
        for each Name attName in styleAttributes
        {
            libmei.AddAttribute(rend, attName, styleAttributes[attName]);
        }
        libmei.SetText(rend, state.currentText);
        state.meiNodes.Push(rend);
    }

    state.currentText = '';
}  //$end


function GetStyleAttributes (state) {
    // Returns a dictionary with attribute names and values.
    // Returns null if there are no style attributes.

    style = state.style;
    styleAttributes = CreateDictionary();
    rendValues = CreateSparseArray();

    noStyles = true;

    for each Name property in state.style
    {
        value = style[property];
        switch (value)
        {
            case (null)
            {
                ; // Nothing to add
            }
            case ('underline_on')
            {
                rendValues.Push('underline');
            }
            case ('underline_off')
            {
                ; // Nothing to add
            }
            case ('normal') // baseline
            {
                ; // Nothing to add
            }
            case ('subscript')
            {
                rendValues.Push('sub');
            }
            case ('superscript')
            {
                rendValues.Push('sup');
            }
            default
            {
                noStyles = false;
                styleAttributes[property] = value;
            }
        }
    }

    if (rendValues.Length > 0)
    {
        noStyles = false;
        styleAttributes['rend'] = rendValues.Join(' ');
    }

    if (noStyles)
    {
        return null;
    }
    return styleAttributes;
}  //$end


function AppendTextSubstitute (state, substituteName) {
    score = Self._property:ActiveScore;

    textSubstituteTemplate = TextSubstituteMap[utils.UpperCase(substituteName)];
    if (null = textSubstituteTemplate)
    {
        // No known substitution. Sibelius renders those literally.
        state.currentText = state.currentText & '\\$' & substituteName & '\\';
        return null;
    }

    propertyName = textSubstituteTemplate.propertyName;

    substitutedText = score.@propertyName;
    if (substitutedText = '')
    {
        return null;
    }

    PushStyledText(state);

    element = MeiFactory(textSubstituteTemplate, null);
    state.meiNodes.Push(element);

    styleAttributes = GetStyleAttributes(state);
    rendElement = null;
    if (null = styleAttributes)
    {
        libmei.SetText(element, substitutedText);
    }
    else
    {
        rendElement = libmei.Rend();
        libmei.AddChild(element, rendElement);
        for each Name attName in styleAttributes
        {
            libmei.AddAttribute(rendElement, attName, styleAttributes[attName]);
        }
        libmei.SetText(rendElement, substitutedText);
    }
}  //$end

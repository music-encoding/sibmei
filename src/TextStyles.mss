function InitTextHandlers() {
    // QUESTION: We could also take an argument and throw all text handlers from
    // extensions into the same dictionary

    Self._property:TextHandlers = CreateDictionary(
        'text.staff.expression', 'ExpressionTextHandler',
        'text.system.page_aligned.title', 'PageTitleHandler',
        'text.system.page_aligned.composer', 'PageComposerTextHandler',
        'text.staff.space.figuredbass', 'FiguredBassTextHandler'
    );

    Self._property:TextSubstituteMap = CreateDictionary(
        'Title', CreateSparseArray('Title'),
        // <composer>, <arranger>, <lyricist>, <userRestrict> and <publisher>
        // are only allowed in a few places, e.g. metadata or title pages.
        // We therfore use mor generic elements
        'Composer', CreateSparseArray('PersName', 'role', 'Composer'),
        'Arranger', CreateSparseArray('PersName', 'role', 'Arranger'),
        'Lyricist', CreateSparseArray('PersName', 'role', 'Lyricist'),
        'Artist', CreateSparseArray('PersName', 'role', 'Artist'),
        // <useRestrict> is only allowed on <titlePage>, so use generic element
        'Copyright', CreateSparseArray('Seg', 'type', 'Copyright'),
        // <publisher> is only allowed in a few places, so use generic element
        // We don't even know if it's a person or an institution
        'Publisher', CreateSparseArray('Seg', 'type', 'Publisher'),
        'MoreInfo', CreateSparseArray('Seg', 'type', 'MoreInfo'),
        'PartName', CreateSparseArray('Seg', 'type', 'PartName')
    );
}  //$end


function HandleText (textObject) {
    // TODO: Move this to a global initialization function
    InitTextHandlers();
    Trace('handle text');
    if (null != Self._property:Extension and null != Extension.TextHandlers)
    {
        // TODO: We need to check for both StyleId *and* StyleAsText so we can
        // handle custom styles
        textHandler = Extension.TextHandlers[textObject.StyleId];
        if (null != textHandler)
        {
            return Extension.@textHandler(textObject);
        }
    }

    textHandler = TextHandlers[textObject.StyleId];
    if (null != textHandler)
    {
        return @textHandler(textObject);
    }
}  //$end


function ExpressionTextHandler (textObj) {
    dynam = AddBarObjectInfoToElement(textObj, libmei.Dynam());
    AddFormattedText(dynam, textObj);
    return dynam;
}  //$end


function PageTitleHandler (textObject) {
    atext = libmei.AnchoredText();
    title = libmei.Title();

    libmei.AddChild(atext, title);
    libmei.SetText(title, text);

    return atext;
}  //$end


function PageComposerTextHandler (textObject) {
    // 'text.system.page_aligned.composer'
    return AddBarObjectInfoToElement(textObj, CreateAnchoredText(textObj));
}  //$end


function TempoTextHandler (textObject) {
    // 'text.system.tempo'
    tempo = libmei.Tempo();
    libmei.AddChild(tempo, CreateAnchoredText(textObj));
    return tempo;
}  //$end


function FiguredBassTextHandler (textObject) {
    // 'text.staff.space.figuredbass'
    harm = AddBarObjectInfoToElement(textObj, libmei.Harm());
    fb = libmei.Fb();
    libmei.AddChild(harm, fb);
    ConvertFbFigures(fb, textObj);
    return harm;
}  //$end


function CreateAnchoredText (textObj) {
    //$module(ExportConverters.mss)
    anchoredText = libmei.AnchoredText();
    libmei.SetText(anchoredText, ConvertSubstitution(textObj.Text));
    return anchoredText;
}  //$end


function AddFormattedText (parentElement, textObj) {
    textWithFormatting = textObj.TextWithFormatting;
    if (textWithFormatting.NumChildren < 2 and CharAt(textWithFormatting, 0) != '\\')
    {
        parentElement.SetText(textObj.Text);
        return null;
    }

    state = CreateDictionary(
        'currentText', null,
        'rendAttributes', null,
        'rendFlags', null,
        'nodes', null,
        'paragraphs', null
    );

    for each component in textObj.TextWithFormatting
    {
        switch (Substring(component, 0, 2))
        {
            case ('\\n')
            {
                state.nodes.Push(libmei.Lb());
            }
            case ('\\N')
            {
                // TODO: Add <p> if it is allowed within parentElement (look at .name)
                state.nodes.Push(libmei.Lb());
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
                SwitchTextStyle(state, 'rend', 'underline', true);
            }
            case ('\\u')
            {
                SwitchTextStyle(state, 'rend', 'underline', false);
            }
            case ('\\f')
            {
                SwitchFont(state, GetTextCommandArg(component));
            }
            case ('\\c')
            {
                // TODO: Can we sensibly handle a character style change? The
                // only built-in one seem to be `text.character.musictext`
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
                SwitchBaselineAdjust(state, GetTextCommandArg(component));
            }
            case ('\\$') {
                AddTextSubstitute(state, substituteName);
            }
            case ('\\\\')
            {
                // According to the documentation, 'backslashes themselves are
                // represented by \\ , to avoid conflicting with the above
                // commands'. Though that does not seem to work, but in case
                // Avid fixes this at some point, let's just assume it works.
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
}  //$end


function NewTextParagraph (state) {
    ;
}  //$end


function GetTextCommandArg (command) {
    // Remove leading part, e.g. the '\$' or '\s' and trailing '\'
    return Substring(2, Length(command) - 3);
}  //$end


function SwitchBaselineAdjust (state, param) {
    sup = (param = 'superscript');
    sub = (param = 'subscript');
    if (sup != state.rendFlags['sup'] or sub != state.rendFlags['sub']) {
        AppendStyledText(state);
    }
    state.rendFlags['sup'] = sup;
    state.rendFlags['sub'] = sub;
}  //$end


function SwitchFont (state, fontName) {
    if (fontName = '_')
    {
        // Before resetting the style, we have to add text preceding the '\f_\'
        // style reset – but only if the style reset actually changes something.

        textNotYetAppended = true;

        if (null != state.rendAttributes)
        {
            for each Name attName in state.rendAttributes
            {
                if (textNotYetAppended and state.rendAttributes[attName] != null)
                {
                    AppendStyledText(state);
                    textNotYetAppended = false;
                }
                state.rendAttributes[attName] = null;
            }
        }
        if (null != state.rendFlags)
        {
            for each Name flagName in state.rendFlags
            {
                if (textNotYetAppended and state.rendFlags[flagName])
                {
                    AppendStyledText(state);
                    textNotYetAppended = false;
                }
                state.rendFlags[flagName] = false;
            }
        }
    }
    else
    {
        SwitchTextStyle(state, 'fontfam', fontName);
    }
}  //$end


function SwitchTextStyle (state, attName, value) {
    if (state.rendAttributes[attName] != value)
    {
        // Style changes, so append current text before modifying style state
        AppendStyledText(state);
    }
    state.rendAttributes[attName] = value;
}  //$end


function SwitchRendFlags (state, flagName, value) {
    if (state.rendFlags[flagName] != value)
    {
        AppendStyledText(state);
    }
    state.rendFlags[flagName] = value;
}  //$end


function AppendStyledText (state) {
    if (null != state.currentText)
    {
        rendAttributes = GetRendAttributes(state);
        if (null = rendAttributes)
        {
            nodes = state.nodes;
            if (null = nodes)
            {
                state.nodes = CreateSparseArray(currentText);
            }
            else
            {
                currentNode = nodes[nodes.Length - 1];
                if (IsObject(currentNode))
                {
                    // This is an element
                    newTail = libmei.GetTail(currentElement) & state.currentText;
                    libmei.SetTail(currentElement, newTail);
                }
                else
                {
                    // currentNode is plain text
                    nodes[nodes.Length - 1] = currentNode & state.currentText;
                }
            }
        }
        else
        {
            rend = libmei.Rend();
            for each Name attName in rendAttributes
            {
                rend.AddAttribute(attName, rendAttributes[attName]);
            }
            // TODO: Continue this
        }
    }

    state.currentText = '';
}  //$end


function GetRendAttributes (state) {
    rendAttributes = null;

    if (null != state.rendAttributes)
    {
        for each Name attName in state.rendAttributes
        {
            value = state.rendAttributes[attName];
            if (null != value)
            {
                if (null = rendAttributes) {
                    rendAttributes = CreateDictionary();
                }
                rendAttributes[attName] = value;
            }
        }
    }

    if (null != state.rendFlags)
    {
        rendFlags = null;
        for each Name flagName in state.rendFlags
        {
            flagActive = state.rendFlags[flagName];
            if (flagActive)
            {
                if (null != rendFlags)
                {
                    rendFlags = CreateSparseArray();
                }
                rendFlags.Push(flagName);
            }
        }
        if (null != rendFlags)
        {
            if (null = rendAttributes) {
                rendAttributes = CreateDictionary();
            }
            rendAttributes['rend'] = rendFlags.Join(' ');
        }
    }

    return rendAttributes;
}  //$end


function AppendTextSubstitute (state, substituteName) {
    score = Self._property:ActiveScore;
    substitutedText = score.@substituteName;
    if (substitutedText = '') {
        // TODO: Also check for all-whitespace text
        return null;
    }

    textSubstituteInfo = TextSubstituteMap[substituteName];
    if (null = textSubstituteInfo)
    {
        // No known substitution. Sibelius renders those literally.
        state.currentText = state.currentText & '\\$' & substituteName & '\\';
        return null;
    }

    elementName = textSubstituteInfo[0];
    element = libmei.@elementName();
    state.nodes.Push(element);
    for i = 1 to textSubstituteInfo.Length step 2
    {
        libmei.AddAttribute(textSubstituteInfo[i], textSubstituteInfo[i + 1]);
    }

    /*
    // Use this instead of a Dictionary mapping?  May be a little clearer and
    // allows allows the analysis script to check it properly.
    element = null;

    switch (substituteName)
    {
        case ('Title')
        {
            element = libmei.Title();
        }
        case ('Composer')
        {
            element = libmei.Composer();
        }
        case ('Arranger')
        {
            element = libmei.Arranger();
        }
        case ('Lyricist')
        {
            element = libmei.Lyricist();
        }
        case ('MoreInfo')
        {
            element = libmei.Seg();
            libmei.AddAttribute(element, 'type', 'MoreInfo');
        }
        case ('Artist')
        {
            element = libmei.PersName();
            libmei.AddAttribute(element, 'role', 'Artist');
        }
        case ('Copyright')
        {
            // <useRestrict> is only allowed on <titlePage>, so use generic element
            element = libmei.Seg();
            libmei.AddAttribute(element, 'type', 'Copyright');
        }
        case ('Publisher')
        {
            // <publisher> is only allowed in a few places, so use generic element
            // We don't even know if it's a person or an institution
            element = libmei.Seg();
            libmei.AddAttribute(element, 'type', 'Publisher');
        }
        case ('PartName')
        {
            element = libmei.Seg();
            libmei.AddAttribute(element, 'type', 'PartName');
        }
        default
        {
            state.currentText = state.currentText & '\\$' & substituteName & '\\';
            return null;
        }
    }*/


    rendAttributes = GetRendAttributes(state);
    rendElement = null;
    if (null = rendAttributes)
    {
        libmei.SetText(element, substitutedText);
    }
    else
    {
        rendElement = libmei.Rend();
        libmei.AddChild(element, rendElement);
        for each Name attName in rendAttributes
        {
            libmei.AddAttribute(rendElement, attName, rendAttributes[attName]);
        }
        libmei.SetText(rendElement, substitutedText);
    }
}  //$end

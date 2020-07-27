function InitTextHandlers() {
    // QUESTION: We could also take an argument and throw all text handlers from
    // extensions into the same dictionary

    Self._property:TextHandlers = CreateDictionary(
        'text.staff.expression', 'ExpressionTextHandler',
        'text.system.page_aligned.title', 'PageTitleHandler',
        'text.system.page_aligned.subtitle', 'PageTitleHandler',
        'text.system.page_aligned.composer', 'PageComposerTextHandler',
        'text.system.tempo', 'TempoTextHandler',
        'text.staff.space.figuredbass', 'FiguredBassTextHandler'
    );

    Self._property:TextSubstituteMap = CreateDictionary(
        'Title', CreateSparseArray('Title'),
        'Subtitle', CreateSparseArray('Title', CreateDictionary('type', 'subordinate')),
        'Dedication', CreateSparseArray('Dedication'),
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
}  //$end


function HandleText (textObject) {
    // TODO: Move InitTextHandlers() call to a global initialization function
    InitTextHandlers();
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


function ExpressionTextHandler (textObject) {
    dynam = AddBarObjectInfoToElement(textObject, libmei.Dynam());
    AddFormattedText(dynam, textObject);
    return dynam;
}  //$end


function PageTitleHandler (textObject) {
    anchoredText = libmei.AnchoredText();
    title = libmei.Title();
    if (textObject.StyleId = 'text.system.page_aligned.subtitle')
    {
        libmei.AddAttribute(title, 'type', 'subordinate');
    }

    libmei.AddChild(anchoredText, title);
    AddFormattedText(title, textObject);

    return anchoredText;
}  //$end


function PageComposerTextHandler (textObject) {
    // 'text.system.page_aligned.composer'
    return AddBarObjectInfoToElement(textObject, CreateAnchoredText(textObject));
}  //$end


function TempoTextHandler (textObject) {
    // 'text.system.tempo'
    tempo = libmei.Tempo();
    libmei.AddChild(tempo, CreateAnchoredText(textObject));
    return tempo;
}  //$end


function FiguredBassTextHandler (textObject) {
    // 'text.staff.space.figuredbass'
    harm = AddBarObjectInfoToElement(textObject, libmei.Harm());
    fb = libmei.Fb();
    libmei.AddChild(harm, fb);
    ConvertFbFigures(fb, textObject);
    return harm;
}  //$end


function CreateAnchoredText (textObj) {
    //$module(ExportConverters.mss)
    anchoredText = libmei.AnchoredText();
    AddFormattedText(anchoredText, textObj);
    return anchoredText;
}  //$end


function AddFormattedText (parentElement, textObj) {
    textWithFormatting = textObj.TextWithFormatting;
    if (textWithFormatting.NumChildren < 2 and CharAt(textWithFormatting[0], 0) != '\\')
    {
        libmei.SetText(parentElement, textObj.Text);
        return null;
    }

    nodes = CreateSparseArray();

    state = CreateDictionary(
        'currentText', null,
        'rendAttributes', CreateDictionary(),
        'rendFlags', CreateDictionary(),
        // TODO: Also track the active character style (mainly
        // `\ctext.character.musictext\`, and custom styles)
        'nodes', nodes,
        'paragraphs', null
    );

    for each component in textObj.TextWithFormatting
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
                SwitchBaselineAdjust(state, GetTextCommandArg(component));
            }
            case ('\\$') {
                AppendTextSubstitute(state, GetTextCommandArg(component));
            }
            case ('\\\\')
            {
                // According to the documentation, 'backslashes themselves are
                // represented by \\ , to avoid conflicting with the above
                // commands'. Though that does not seem to work, let's just
                // assume it does in case Avid fixes this.

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
            while (nodeIndex < nodeCount and not IsObject(nodes[nodeIndex + 1])) {
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


function NewTextParagraph (state) {
    // TODO!
    ;
}  //$end


function GetTextCommandArg (command) {
    // Remove leading part, e.g. the '\$' or '\s' and trailing '\'
    return Substring(command, 2, Length(command) - 3);
}  //$end


function SwitchBaselineAdjust (state, param) {
    sup = (param = 'superscript');
    sub = (param = 'subscript');
    if (sup != state.rendFlags['sup'] or sub != state.rendFlags['sub']) {
        // Style changed, push the previous text before changing the style
        PushStyledText(state);
    }
    state.rendFlags['sup'] = sup;
    state.rendFlags['sub'] = sub;
}  //$end


function ResetTextStyles (state, infoOnly) {
    // If `infoOnly` is `true`, does not make any changes, only tells us if
    // there are re-settable styles
    if (null != state.rendAttributes)
    {
        for each Name attName in state.rendAttributes
        {
            if (infoOnly and state.rendAttributes[attName] != null)
            {
                return true;
            }
            state.rendAttributes[attName] = null;
        }
    }

    if (null != state.rendFlags)
    {
        for each Name flagName in state.rendFlags
        {
            if (infoOnly and state.rendFlags[flagName])
            {
                return true;
            }
            state.rendFlags[flagName] = false;
        }
    }
    return false;
}  //$end


function SwitchFont (state, fontName) {
    if (fontName = '_')
    {
        // Before resetting the style, we have to add text preceding the '\f_\'
        // style reset – but only if the style reset actually changes something.
        if (ResetTextStyles(state, true))
        {
            PushStyledText(state);
            ResetTextStyles(state, false);
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
        PushStyledText(state);
    }
    state.rendAttributes[attName] = value;
}  //$end


function SwitchRendFlags (state, flagName, value) {
    if (state.rendFlags[flagName] != value)
    {
        PushStyledText(state);
    }
    state.rendFlags[flagName] = value;
}  //$end


function PushStyledText (state) {
    if (state.currentText = '')
    {
        return null;
    }

    styleAttributes = GetStyleAttributes(state);
    if (null = styleAttributes)
    {
        // We attach unstyled text without wrapping it in <rend>
        state.nodes.Push(state.currentText);
    }
    else
    {
        rend = libmei.Rend();
        for each Name attName in styleAttributes {
            libmei.AddAttribute(rend, attName, styleAttributes[attName]);
        }
        libmei.SetText(rend, state.currentText);
        state.nodes.Push(rend);
    }

    state.currentText = '';
}  //$end


function GetStyleAttributes (state) {
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
        rendAttValue = '';
        firstRendFlag = true;
        for each Name flagName in state.rendFlags
        {
            flagActive = state.rendFlags[flagName];
            if (flagActive)
            {
                if (firstRendFlag = true)
                {
                    rendAttValue = rendAttValue & flagName;
                    firstRendFlag = false;
                }
                else
                {
                    rendAttValue = rendAttValue & ' ' & flagName;
                }
            }
        }
        if (rendAttValue != '')
        {
            if (null = rendAttributes) {
                rendAttributes = CreateDictionary();
            }
            rendAttributes['rend'] = rendAttValue;
        }
    }

    return rendAttributes;
}  //$end


function AppendTextSubstitute (state, substituteName) {
    score = Self._property:ActiveScore;

    textSubstituteInfo = TextSubstituteMap[substituteName];
    if (null = textSubstituteInfo)
    {
        // No known substitution. Sibelius renders those literally.
        state.currentText = state.currentText & '\\$' & substituteName & '\\';
        return null;
    }

    substitutedText = score.@substituteName;
    if (substitutedText = '') {
        // TODO: Also check for all-whitespace text
        return null;
    }

    element = DataToMEI(textSubstituteInfo);
    state.nodes.Push(element);

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

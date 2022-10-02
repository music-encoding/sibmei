function InitTextHandlers() {
    // QUESTION: We could also take an argument and throw all text handlers from
    // extensions into the same dictionary

    textHandlers = CreateDictionary(
        'StyleId', CreateDictionary(),
        'StyleAsText', CreateDictionary()
    );

    RegisterHandlers(textHandlers, CreateDictionary(
        'StyleId', CreateDictionary(
            'text.staff.expression', 'ExpressionTextHandler',
            'text.system.page_aligned.title', 'PageTitleHandler',
            'text.system.page_aligned.subtitle', 'PageTitleHandler',
            'text.system.page_aligned.composer', 'PageComposerTextHandler',
            'text.staff.plain', 'CreateAnchoredText'
            'text.staff.space.figuredbass', 'FiguredBassTextHandler',
            'text.staff.technique', 'CreateDirective',
            'text.system.tempo', 'TempoTextHandler',
        )
    ), Self);

    return textHandlers;
}  //$end

function InitTextSubstituteMap() {
    return CreateDictionary(
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
}  //$end


function HandleText (textObject) {
    // Step through the different ID types ('StyleId' and 'StyleAsText') and
    // check for text handlers for this type
    textHandlers = Self._property:TextHandlers;
    for each Name idType in textHandlers
    {
        handlersForIdType = textHandlers.@idType;
        idValue = textObject.@idType;
        if(handlersForIdType.MethodExists(idValue))
        {
            return handlersForIdType.@idValue(textObject);
        }
    }
}  //$end


function ExpressionTextHandler (this, textObject) {
    dynam = GenerateControlEvent(textObject, 'Dynam');
    AddFormattedText(dynam, textObject);
    return dynam;
}  //$end


function PageTitleHandler (this, textObject) {
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


function PageComposerTextHandler (this, textObject) {
    // 'text.system.page_aligned.composer'
    anchoredText = libmei.AnchoredText();
    AddFormattedText(anchoredText, textObject);
    return anchoredText;
}  //$end


function TempoTextHandler (this, textObject) {
    // 'text.system.tempo'
    tempo = GenerateControlEvent(textObject, 'Tempo');
    AddFormattedText(tempo, textObject);
    return tempo;
}  //$end


function FiguredBassTextHandler (this, textObject) {
    // 'text.staff.space.figuredbass'
    harm = GenerateControlEvent(textObject, 'Harm');
    fb = libmei.Fb();
    libmei.AddChild(harm, fb);
    ConvertFbFigures(fb, textObject);
    return harm;
}  //$end


function CreateAnchoredText (this, textObject) {
    anchoredText = libmei.AnchoredText();
    AddFormattedText(anchoredText, textObject);
    return anchoredText;
}  //$end

function CreateDirective (this, textObject) {
    directive = GenerateControlEvent(textObject, 'Dir');
    AddFormattedText(directive, textObject);
    styleIdPrefix = 'text.staff.';
    text_style = Substring(textObject.StyleId, Length(styleIdPrefix));
    libmei.AddAttribute(directive, 'class', text_style);
    return directive;
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

    textSubstituteTemplate = TextSubstituteMap[substituteName];
    if (null = textSubstituteTemplate)
    {
        // No known substitution. Sibelius renders those literally.
        state.currentText = state.currentText & '\\$' & substituteName & '\\';
        return null;
    }

    substitutedText = score.@substituteName;
    if (substitutedText = '')
    {
        return null;
    }

    PushStyledText(state);

    element = MeiFactory(textSubstituteTemplate);
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

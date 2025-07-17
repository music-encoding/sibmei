function ProcessScore () {
    //$module(ExportProcessors.mss)
    // processors are a bit like a workflow manager -- they orchestrate the
    // generators, which in turn use the converters to convert specific values from sibelius
    // to MEI.
    mei = libmei.Mei();
    libmei.setDocumentRoot(mei);

    libmei.AddAttribute(mei, 'xmlns:xlink', 'http://www.w3.org/1999/xlink');
    libmei.AddAttribute(mei, 'xmlns', 'http://www.music-encoding.org/ns/mei');
    libmei.AddAttribute(mei, 'meiversion', MeiVersion);

    header = GenerateMEIHeader();
    libmei.AddChild(mei, header);

    music = GenerateMEIMusic();
    libmei.AddChild(mei, music);

}  //$end


function ProcessSystemStaff (systf) {
    for each bar in systf
    {
        for each bobj in bar
        {
            switch (bobj.Type)
            {
                case ('SpecialBarline')
                {
                    spclbarlines = Self._property:SpecialBarlines;
                    if (spclbarlines.PropertyExists(bar.BarNumber) = False)
                    {
                        spclbarlines[bar.BarNumber] = CreateSparseArray();
                    }

                    spclbarlines[bar.BarNumber].Push(ConvertBarline(bobj.BarlineInternalType));
                }
                case ('SystemTextItem')
                {
                    if (bobj.OnNthBlankPage < 0)
                    {
                        ProcessFrontMatter(bobj);
                    }

                    systemtext = Self._property:SystemText;

                    if (systemtext.PropertyExists(bar.BarNumber) = False)
                    {
                        systemtext[bar.BarNumber] = CreateSparseArray();
                    }

                    systemtext[bar.BarNumber].Push(bobj);
                }
                case ('Graphic')
                {
                    Log('Found a graphic!');
                    Log('is object? ' & IsObject(bobj));
                }
                case ('RepeatTimeLine')
                {
                    RegisterVolta(bobj);
                }
            }
        }
    }
}  //$end

function ProcessFrontMatter (bobj) {
    //$module(ExportProcessors.mss)
    /*
        For example, if page 2 (0-indexed) is the first page of music,
        then 'OnNthPage' will be 2, but the system staff items for
        the first page of text will be -2, so 2 + (-2) = 0 + 1;
    */
    bar = bobj.ParentBar;
    text = '';

    pnum = (bar.OnNthPage + bobj.OnNthBlankPage) + 1;
    frontmatter = Self._property:FrontMatter;

    if (frontmatter.PropertyExists(pnum) = False)
    {
        pb = libmei.Pb();
        libmei.AddAttribute(pb, 'n', pnum);
        frontmatter[pnum] = CreateSparseArray(pb);
    }

    text = AddFormattedText(null, libmei.Div(), bobj);
    frontmatter[pnum].Push(text);

}  //$end

function RegisterVolta (bobj) {
    //$module(ExportProcessors.mss)
    voltabars = Self._property:VoltaBars;
    style = MSplitString(bobj.StyleId, '.');

    if (style[2] = 'repeat')
    {
        voltabars[bobj.ParentBar.BarNumber] = bobj;
    }
}  //$end

function ProcessVolta (mnum) {
    //$module(ExportProcessors.mss)
    voltabars = Self._property:VoltaBars;

    if (voltabars.PropertyExists(mnum))
    {
        voltaElement = libmei.Ending();

        Self._property:VoltaElement = voltaElement;

        voltaObject = voltabars[mnum];
        voltainfo = ConvertEndingValues(voltaObject.StyleId);

        libmei.AddAttribute(voltaElement, 'n', voltainfo[0]);
        libmei.AddAttribute(voltaElement, 'label', voltainfo[1]);
        libmei.AddAttribute(voltaElement, 'type', voltainfo[2]);

        if (voltaObject.EndBarNumber != mnum)
        {
            Self._property:ActiveVolta = voltaObject;
        }

        return voltaElement;
    }
    else
    {
        if (Self._property:ActiveVolta != null)
        {
            // we have an unresolved volta, so
            // we'll keep the previous parentElement
            // active.
            activeVolta = Self._property:ActiveVolta;
            voltaElement = Self._property:VoltaElement;

            // if the end bar is the current bar OR if the end
            // bar is the next bar, but the end position is 0, we're escaping the
            // volta the next time around.
            if ((activeVolta.EndBarNumber = mnum) or
                (activeVolta.EndBarNumber = (mnum + 1) and activeVolta.EndPosition = 0))
            {
                Self._property:ActiveVolta = null;
                Self._property:VoltaElement = null;
            }
            return null;
        }
    }

    return null;
}  //$end

function ProcessEndingLines (bar) {
    //$module(ExportProcessors.mss)
    lineResolver = Self._property:LineEndResolver;
    for voiceNumber = 1 to 5
    {
        endingLines = lineResolver[LayerHash(bar, voiceNumber)];
        if (endingLines != null)
        {
            for each line in endingLines
            {
                meiLine = line._property:mobj;
                endidSearchStrategy = meiLine.attrs['endid'];
                if ('' = endidSearchStrategy)
                {
                    end_obj = null;
                }
                else
                {
                    end_obj = GetNoteObjectAtPosition(line, endidSearchStrategy, 'EndPosition');
                }

                if (end_obj = null)
                {
                    meiLine.attrs.endid = ' ';
                }
                else
                {
                    libmei.AddAttribute(meiLine, 'endid', '#' & end_obj._id);
                }
            }
        }
    }
}  //$end


function ProcessBarObjects (bar) {
    // Processes all BarObjects in bar, except for NoteRest, BarRest, Tuplet and
    // Clef.
    for each bobj in bar
    {
        switch (bobj.Type)
        {
            case('GuitarFrame')
            {
                GenerateChordSymbol(bobj);
            }
            case('Slur')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('CrescendoLine')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('DiminuendoLine')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('OctavaLine')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('GlissandoLine')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('Trill')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('ArpeggioLine')
            {
                GenerateArpeggio(bobj);
            }
            case('RepeatTimeLine')
            {
                RegisterVolta(bobj);
            }
            case('Line')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('Text')
            {
                HandleStyle(TextHandlers, bobj);
            }
            case('SymbolItem')
            {
                HandleSymbol(bobj);
            }
        }
    }
} //$end

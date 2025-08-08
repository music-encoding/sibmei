function ProcessScore () {
    //$module(ExportProcessors.mss)
    // processors are a bit like a workflow manager -- they orchestrate the
    // generators, which in turn use the converters to convert specific values from sibelius
    // to MEI.
    mei = CreateElement('mei');
    SetDocumentRoot(mei);

    AddAttribute(mei, 'xmlns:xlink', 'http://www.w3.org/1999/xlink');
    AddAttribute(mei, 'xmlns', 'http://www.music-encoding.org/ns/mei');
    AddAttribute(mei, 'meiversion', MeiVersion);

    header = GenerateMEIHeader();
    AddChild(mei, header);

    music = GenerateMEIMusic();
    AddChild(mei, music);

}  //$end


function ProcessFrontMatter (musicEl) {
    if (SystemStaff.BarCount = 0)
    {
        return '';
    }

    frontmatter = CreateDictionary();
    bar = SystemStaff.NthBar(1);

    for each SystemTextItem bobj in bar
    {
        if (bobj.OnNthBlankPage < 0)
        {
            pnum = (bar.OnNthPage + bobj.OnNthBlankPage) + 1;

            if (frontmatter.PropertyExists(pnum) = false)
            {
                pb = CreateElement('pb');
                AddAttribute(pb, 'n', pnum);
                frontmatter[pnum] = CreateSparseArray(pb);
            }

            pElement = AddFormattedText(null, CreateElement('p'), bobj);
            divElement = CreateElement('div');
            AddChild(divElement, pElement);
            frontmatter[pnum].Push(divElement);
        }
    }

    frontpages = frontmatter.GetPropertyNames();

    if (frontpages.Length > 0)
    {
        // sort the front pages
        // Log('front: ' & frontmatter);
        sorted_front = utils.SortArray(frontpages, false);
        frontEl = CreateElement('front');
        for each pnum in sorted_front
        {
            pgels = frontmatter[pnum];

            for each el in pgels
            {
                AddChild(frontEl, el);
            }
        }

        AddChild(musicEl, frontEl);
    }
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
                    AddAttribute(meiLine, 'endid', '#' & end_obj._id);
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
            case('Line')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('Text')
            {
                if (bobj.Text != '')
                {
                    HandleStyle(TextHandlers, bobj);
                }
            }
            case('SymbolItem')
            {
                HandleSymbol(bobj);
            }
        }
    }
} //$end

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


function ProcessPageAndSystemBreaks (bar) {
    if (bar.NthBarInSystem > 0)
    {
        // We're only interested in bars that start a new system
        return '';
    }

    barNum = bar.BarNumber;
    if (barNum > 1)
    {
        precedingBar = SystemStaff.NthBar(barNum - 1);
        pageNumOfPrecdingBar = precedingBar.OnNthPage + 1;
    }
    else
    {
        precedingBar = null;
        pageNumOfPrecdingBar = -1;
    }

    if (null != precedingBar and precedingBar.NumBlankPages > 0)
    {
        ProcessBlankPages(
            precedingBar,
            pageNumOfPrecdingBar + 1,
            pageNumOfPrecdingBar + precedingBar.NumBlankPages
        );
    }

    pageNumOfCurrentBar = bar.OnNthPage + 1;

    if (bar.NumBlankPagesBefore != 0)
    {
        ProcessBlankPages(
            bar,
            pageNumOfCurrentBar - bar.NumBlankPagesBefore,
            pageNumOfCurrentBar - 1
        );
    }

    if (pageNumOfPrecdingBar = pageNumOfCurrentBar)
    {
        // Continuing on the same page, only generate system break
        GenerateSystemAndPageBreaks(true, '');
    }
    else
    {
        // Start new page with page and system breaks
        GenerateSystemAndPageBreaks(true, pageNumOfCurrentBar);
    }
} //$end


function ProcessBlankPages (bar, startPageNum, endPageNum) {
    // Processes any blank pages associated with `bar`

    // OnNthPage is a 0-based index, but we work with 1-based page numbers
    referencePageNumber = bar.OnNthPage + 1;
    bobjsByPageNum = CreateSparseArray();
    for each SystemTextItem bobj in bar
    {
        pageNum = referencePageNumber + bobj.OnNthBlankPage;
        bobjsOnPage = bobjsByPageNum[pageNum];
        if (null = bobjsOnPage)
        {
            bobjsOnPage = CreateSparseArray();
            bobjsByPageNum[pageNum] = bobjsOnPage;
        }
        bobjsOnPage.Push(bobj);
    }

    for pageNum = startPageNum to endPageNum + 1
    {
        GenerateSystemAndPageBreaks(false, pageNum);

        // <head> elements must be the first children of <div> for valid MEI.
        // As the order in which Sibelius iterates over blank page text is
        // arbitrary anyway, collect them separately and write them first.
        headingsOnPage = CreateSparseArray();
        nonHeadingTextOnPage = CreateSparseArray();

        bobjsOnPage = bobjsByPageNum[pageNum];
        if (null != bobjsOnPage)
        {
            for each bobj in bobjsOnPage
            {
                element = HandleStyle(TextHandlers, bobj);
                if (null != element)
                {
                    element['bobj'] = bobj;
                    if (element.name = 'head')
                    {
                        headingsOnPage.Push(element);
                    }
                    else
                    {
                        nonHeadingTextOnPage.Push(element);
                    }
                }
            }
        }

        if (nonHeadingTextOnPage.Length + headingsOnPage.Length > 0)
        {
            elementsOnPage = headingsOnPage;
            div = CreateElement('div');
            AddChild(SectionElement, div);
            if (null != ActiveVolta)
            {
                RegisterWarning(element.bobj, 'Blank page text is encoded on the wrong page', '<pb n=\'' & pageNum & '\'> starting a \'blank page\' is inside an <ending> element. Text content of that blank page can not be encoded inside this <ending> in schema conformant way, so it is placed after the <ending> element.');
            }
            for each element in headingsOnPage.Concat(nonHeadingTextOnPage)
            {
                AddChild(div, element);
            }
        }
    }
} //$end


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
            case ('RitardLine')
            {
                HandleStyle(LineHandlers, bobj);
            }
            case('SymbolItem')
            {
                HandleSymbol(bobj);
            }
        }
    }
} //$end

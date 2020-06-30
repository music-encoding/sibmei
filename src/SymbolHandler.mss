// TODO: Missing symbols
// '240' double staccato
// '241' tripe staccato
// '242' quadruple staccato

function InitSymbolHandlers () {
    //$module(SymbolHandler.mss)

    symbolHandlers = CreateDictionary(
        'Index', CreateDictionary(),
        'Name', CreateDictionary()
    );

    RegisterHandlers(symbolHandlers, CreateDictionary(
        'Index', CreateDictionary(
            '36', 'HandleControlEvent',                 //inverted mordent
            '37', 'HandleControlEvent',                 //mordent
            '38', 'HandleControlEvent',                 //turn
            '39', 'HandleControlEvent',                 //inverted turn
            '52', 'HandleModifier',                     //heel
            '53', 'HandleModifier',                     //heel (2) (was toe in previous version, but this seems to be wrong)
            '54', 'HandleModifier',                     //toe
            '160', 'HandleModifier',                    //stop
            '162', 'HandleModifier',                    //open
            '163', 'HandleModifier',                    //damp
            '164', 'HandleModifier',                    //damp (2)
            '165', 'HandleModifier',                    //damp (3)
            '166', 'HandleModifier',                    //damp (4)
            '212', 'HandleModifier',                    //ten above
            '214', 'HandleModifier',                    //marc above
            '217', 'HandleModifier',                    //upbow above
            '218', 'HandleModifier',                    //dnbow above
            '233', 'HandleModifier',                    //upbow below
            '234', 'HandleModifier',                    //dnbow below
            '243', 'HandleModifier',                    //snap
            '480', 'HandleModifier',                    //scoop
            '481', 'HandleModifier',                    //fall
            '490', 'HandleModifier',                    //fingernail
            '494', 'HandleModifier',                    //doit
            '495', 'HandleModifier'                     //plop
        ),
        'Name', CreateDictionary(
            'Pedal', 'HandleControlEvent'
        )
    ), Self);

    return symbolHandlers;

}//$end

function InitSymbolMap () {
    //$module(SymbolHandler.mss)
    // Create a dictionary with symbol index number as key (sobj.Index) and a value that determines the element that has to be created
    // 0th element in SparseArray is the element name as function call
    // following Dictionary contains attributes
    // TODO: key, CreateDictionary(Element, CreateDictionary(attname, attvalue))

     return CreateDictionary(
        '36', CreateSparseArray('Mordent', CreateDictionary('form', 'lower')),                  //inverted mordent
        '37', CreateSparseArray('Mordent', CreateDictionary('form','upper')),                   //mordent
        '38', CreateSparseArray('Turn', CreateDictionary('form', 'upper')),                     //turn
        '39', CreateSparseArray('Turn', CreateDictionary('form', 'lower')),                     //inverted turn
        '52', CreateSparseArray('Artic', CreateDictionary('artic','heel')),                     //heel
        '53', CreateSparseArray('Artic', CreateDictionary('artic','heel')),                     //heel (2) (was toe in previous version, but this seems to be wrong)
        '54', CreateSparseArray('Artic', CreateDictionary('artic','toe')),                      //toe
        '160', CreateSparseArray('Artic', CreateDictionary('artic','stop')),                    //stop
        '162', CreateSparseArray('Artic', CreateDictionary('artic','open')),                    //open
        '163', CreateSparseArray('Artic', CreateDictionary('artic','damp')),                    //damp
        '164', CreateSparseArray('Artic', CreateDictionary('artic','damp')),                    //damp (2)
        '165', CreateSparseArray('Artic', CreateDictionary('artic','damp')),                    //damp (3)
        '166', CreateSparseArray('Artic', CreateDictionary('artic','damp')),                    //damp (4)
        '212', CreateSparseArray('Artic', CreateDictionary('artic','ten', 'place','above')),    //ten above
        '214', CreateSparseArray('Artic', CreateDictionary('artic','marc', 'place','above')),   //marc above
        '217', CreateSparseArray('Artic', CreateDictionary('artic','upbow', 'place','above')),  //upbow above
        '218', CreateSparseArray('Artic', CreateDictionary('artic','dnbow', 'place','above')),  //dnbow above
        '233', CreateSparseArray('Artic', CreateDictionary('artic','upbow', 'place','below')),  //upbow below
        '234', CreateSparseArray('Artic', CreateDictionary('artic','dnbow', 'place','below')),  //dnbow below
        '243', CreateSparseArray('Artic', CreateDictionary('artic','snap')),                    //snap
        '480', CreateSparseArray('Artic', CreateDictionary('artic','scoop')),                   //scoop
        '481', CreateSparseArray('Artic', CreateDictionary('artic','fall')),                    //fall
        '490', CreateSparseArray('Artic', CreateDictionary('artic','fingernail')),              //fingernail
        '494', CreateSparseArray('Artic', CreateDictionary('artic','doit')),                    //doit
        '495', CreateSparseArray('Artic', CreateDictionary('artic','plop')),                    //plop
        'Pedal', CreateSparseArray('Pedal', CreateDictionary('dir', 'down', 'func', 'sustain')) //Pedal
    );  

}   //$end


function HandleSymbol (sobj) {
    //$module(SymbolHandler.mss)
    Log('symbol index: ' & sobj.Index & ' name: ' & sobj.Name);
    Log(sobj.VoiceNumber);
    voicenum = sobj.VoiceNumber;
    bar = sobj.ParentBar;

    if (voicenum = 0)
    {
        // assign it to the first voice, since we don't have any notes in voice/layer 0.
        sobj.VoiceNumber = 1;
        warnings = Self._property:warnings;
        warnings.Push(utils.Format(_ObjectAssignedToAllVoicesWarning, bar.BarNumber, voicenum, 'Symbol'));
    }

    // trills are special
    if (sobj.Index = '32')
    {
        // trill
        trill = GenerateTrill(sobj);
        mlines = Self._property:MeasureObjects;
        mlines.Push(trill._id);
    }

    // get SymbolIndexHandlers and SymbolIndexMap
    symbolHandlers = Self._property:SymbolHandlers;
    symbolMap = Self._property:SymbolMap;

    // look for symbol index in symbolHandlers.Index
    if(symbolHandlers.Index.MethodExists(sobj.Index))
    {
        symbId = sobj.Index;
        symbolHandlers.Index.@symbId(sobj, symbolMap[symbId]);
    }
    else
    {
        // look for symbol name in symbolHandlers.Name
        if(symbolHandlers.Name.MethodExists(sobj.Name))
        {
            symbName = sobj.Name;
            symbolHandlers.Name.@symbName(sobj, symbolMap[symbName]);
        }
    }
    
} //$end

function HandleModifier(this, sobj, mapValue){
    //$module(SymbolHandler.mss)

    makeElement = mapValue[0];

    nobj = GetNoteObjectAtPosition(sobj);

    if (nobj != null)
    {
        modifier = libmei.@makeElement();

        // add attributes
        if (mapValue.Length = 2)
        {
            atts = mapValue[1];
            for each Pair att in atts
            {
                libmei.AddAttribute(modifier, att.Name, att.Value);
            }
        }

        libmei.AddChild(nobj, modifier);
    }
    else
    {
        warnings = Self._property:warnings;
        warnings.Push(utils.Format(_ObjectCouldNotFindAttachment, bar.BarNumber, voicenum, sobj.Name));
    }

}   //$end

function HandleControlEvent(this, sobj, mapValue){
    //$module(SymbolHandler.mss)

    makeElement = mapValue[0];

    symbol = libmei.@makeElement();

    // add attributes if necessary
    if (mapValue.Length = 2)
    {
        atts = mapValue[1];
        for each Pair att in atts
        {
            libmei.AddAttribute(symbol, att.Name, att.Value);
        }
    }

    symbol = AddBarObjectInfoToElement(sobj, symbol);
    mlines = Self._property:MeasureObjects;
    mlines.Push(symbol._id);

}   //$end
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
            '209', 'HandleModifier',                    //staccato above
            '210', 'HandleModifier',                    //staccatissimo above
            '211', 'HandleModifier',                    //spiccato above
            '212', 'HandleModifier',                    //ten above
            '214', 'HandleModifier',                    //marc above
            '217', 'HandleModifier',                    //upbow above
            '218', 'HandleModifier',                    //dnbow above
            '220', 'HandleControlEvent',                // square fermata above
            '221', 'HandleControlEvent',                // round fermata above
            '222', 'HandleControlEvent',                // triangular fermata above
            '225', 'HandleModifier',                    // staccato below
            '226', 'HandleModifier',                    // staccatissimo below
            '227', 'HandleModifier',                    // spiccato below
            '230', 'HandleModifier',                    // marcato below
            '236', 'HandleControlEvent',                // square fermata below
            '237', 'HandleControlEvent',                // round fermata below
            '238', 'HandleControlEvent',                // triangular fermata below
            '233', 'HandleModifier',                    //upbow below
            '234', 'HandleModifier',                    //dnbow below
            '243', 'HandleModifier',                    //snap
            '480', 'HandleModifier',                    //scoop
            '481', 'HandleModifier',                    //fall
            '490', 'HandleModifier',                    //fingernail
            '494', 'HandleModifier',                    //doit
            '495', 'HandleModifier'                     //plop
        )
        // 'Name', CreateDictionary(
        //     'Pedal', 'HandleControlEvent'
        // )
    ), Self);

    return symbolHandlers;

}//$end

function InitSymbolMap () {
    //$module(SymbolHandler.mss)
    // Create a dictionary with symbol index number as key (sobj.Index) and a value that determines the element that has to be created
    // 0th element in SparseArray is the element name as function call
    // see for further instructions Utilities/MeiFactory()

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
        '209', CreateSparseArray('Artic', CreateDictionary('artic','stacc', 'place','above')),  //staccato above
        '210', CreateSparseArray('Artic', CreateDictionary('artic','stacciss', 'place','above')), //staccatissimo above
        '211', CreateSparseArray('Artic', CreateDictionary('artic','spicc', 'place','above')),  //spiccato above
        '212', CreateSparseArray('Artic', CreateDictionary('artic','ten', 'place','above')),    //ten above
        '214', CreateSparseArray('Artic', CreateDictionary('artic','marc', 'place','above')),   //marc above
        '217', CreateSparseArray('Artic', CreateDictionary('artic','upbow', 'place','above')),  //upbow above
        '218', CreateSparseArray('Artic', CreateDictionary('artic','dnbow', 'place','above')),  //dnbow above
        '220', CreateSparseArray('Fermata', CreateDictionary('shape', 'square', 'form', 'norm')),  // square fermata above
        '221', CreateSparseArray('Fermata', CreateDictionary('shape', 'curved', 'form', 'norm')),  // round fermata above
        '222', CreateSparseArray('Fermata', CreateDictionary('shape', 'angular', 'form', 'norm')), // triangular fermata above
        '225', CreateSparseArray('Artic', CreateDictionary('artic','stacc', 'place','below')),     //staccato below
        '226', CreateSparseArray('Artic', CreateDictionary('artic','stacciss', 'place','below')),  //staccatissimo below
        '227', CreateSparseArray('Artic', CreateDictionary('artic','spicc', 'place','below')),     //spiccato below
        '230', CreateSparseArray('Artic', CreateDictionary('artic','marc', 'place','below')),      //marcato below
        '236', CreateSparseArray('Fermata', CreateDictionary('shape', 'square', 'form', 'inv')),   // square fermata below
        '237', CreateSparseArray('Fermata', CreateDictionary('shape', 'curved', 'form', 'inv')),   // round fermata below
        '238', CreateSparseArray('Fermata', CreateDictionary('shape', 'angular', 'form', 'inv')),  // triangular fermata below
        '233', CreateSparseArray('Artic', CreateDictionary('artic','upbow', 'place','below')),  //upbow below
        '234', CreateSparseArray('Artic', CreateDictionary('artic','dnbow', 'place','below')),  //dnbow below
        '243', CreateSparseArray('Artic', CreateDictionary('artic','snap')),                    //snap
        '480', CreateSparseArray('Artic', CreateDictionary('artic','scoop')),                   //scoop
        '481', CreateSparseArray('Artic', CreateDictionary('artic','fall')),                    //fall
        '490', CreateSparseArray('Artic', CreateDictionary('artic','fingernail')),              //fingernail
        '494', CreateSparseArray('Artic', CreateDictionary('artic','doit')),                    //doit
        '495', CreateSparseArray('Artic', CreateDictionary('artic','plop'))                     //plop
        // 'Pedal', CreateSparseArray('Pedal', CreateDictionary('dir', 'down', 'func', 'sustain')) //Pedal
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

function HandleModifier(this, sobj, template){
    //$module(SymbolHandler.mss)

    nobj = GetNoteObjectAtPosition(sobj);

    if (nobj != null)
    {
        modifier = MeiFactory(template);
        libmei.AddChild(nobj, modifier);
        return modifier;
    }
    else
    {
        warnings = Self._property:warnings;
        barNum = sobj.ParentBar.BarNumber;
        voiceNum = sobj.VoiceNumber;
        warnings.Push(utils.Format(_ObjectCouldNotFindAttachment, barNum, voiceNum, sobj.Name));
    }
}   //$end

function HandleControlEvent(this, sobj, template){
    //$module(SymbolHandler.mss)

    symbol = MeiFactory(template);

    symbol = AddControlEventAttributes(sobj, symbol);
    mlines = Self._property:MeasureObjects;
    mlines.Push(symbol._id);

    return symbol;

}   //$end

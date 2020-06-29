// TODO: Missing symbols
// '240' double staccato
// '241' tripe staccato
// '242' quadruple staccato

function InitSymbolHandlers () {
    //$module(SymbolStyles.mss)

    // Create a dictionary with symbol index number as key (sobj.Index) and a value that determines the element that has to be created
    // All the symbols defined here should be created as children of note elements (modifier)
    // Artic() is the element that has to be created like -> modifier = libmei.Artic();
    // Every other SparseArray determines an attribute that needs to be added to modifier
    // E.g.: '52' becomes <artic artic='heel' />

     Self._property:ModifierMap = CreateDictionary(
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
        '495', CreateSparseArray('Artic', CreateDictionary('artic','plop'))                     //plop
    );

    // Create a dictionary with symbol index number as key (sobj.Index) and a value that determines the element that has to be created
    // All the symbols defined here should be created as children of measure (control events)
    // Turn() is the element that has to be created like -> controlEvent = libmei.Turn();
    // Every other SparseArray determines an attribute that needs to be added to modifier
    // E.g.: '36' becomes <turn form='lower' />

    Self._property:ControlEventMap = CreateDictionary(
        '36', CreateSparseArray('Mordent', CreateDictionary('form', 'lower')),      //inverted mordent
        '37', CreateSparseArray('Mordent', CreateDictionary('form','upper')),       //mordent
        '38', CreateSparseArray('Turn', CreateDictionary('form', 'upper')),         //turn
        '39', CreateSparseArray('Turn', CreateDictionary('form', 'lower'))          //inverted turn
    );    

    /*if (Self._property:ModifierMap = null) 
    {
        Self._property:ModifierMap = modifierMap;
    }

    if (Self._property:ControlEventMap = null)
    {
        Self._property:ControlEventMap = controlEventMap;
    }*/

}//$end


function HandleSymbol (sobj) {
    //$module(SymbolStyles.mss)
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

    // load symbol style dictionaries
    modifierMap = Self._property:ModifierMap;
    controlEventMap = Self._property:ControlEventMap;

    // iterate over controlEventMap to process symbols that belong to measure
    if(controlEventMap.PropertyExists(sobj.Index))
    {
        HandleControlEvents(sobj,controlEventMap[sobj.Index]);
    }

    // iterate over modifierMap to process symbols that belong to a single note
    if(modifierMap.PropertyExists(sobj.Index))
    {
        HandleModifier(sobj,modifierMap[sobj.Index]);
    }
    
} //$end

function HandleModifier(sobj, mapValue){
    //$module(SymbolStyles.mss)

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

function HandleControlEvents(sobj, mapValue){
    //$module(SymbolStyles.mss)

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
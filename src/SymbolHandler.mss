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

    RegisterHandlers(symbolHandlers.Index, CreateDictionary(
        //inverted mordent
        36, CreateSparseArray('Mordent', CreateDictionary('form', 'lower')),
        //mordent
        37, CreateSparseArray('Mordent', CreateDictionary('form','upper')),
        //turn
        38, CreateSparseArray('Turn', CreateDictionary('form', 'upper')),
        //inverted turn
        39, CreateSparseArray('Turn', CreateDictionary('form', 'lower')),
        //heel 1
        52, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','heel'))),
        //heel 2
        53, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','heel'))),
        //toe 1
        54, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','toe'))),
        //toe 2
        55, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','toe'))),
        //stop
        160, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','stop'))),
        //open
        162, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','open'))),
        //damp
        163, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','damp'))),
        //damp (2)
        164, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','damp'))),
        //damp (3)
        165, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','damp'))),
        //damp (4)
        166, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','damp'))),
        //staccato above
        209, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','stacc', 'place','above'))),
        //staccatissimo above
        210, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','stacciss', 'place','above'))),
        //spiccato above
        211, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','spicc', 'place','above'))),
        //ten above
        212, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','ten', 'place','above'))),
        //marc above
        214, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','marc', 'place','above'))),
        //upbow above
        217, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','upbow', 'place','above'))),
        //dnbow above
        218, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','dnbow', 'place','above'))),
        // square fermata above
        220, CreateSparseArray('Fermata', CreateDictionary('shape', 'square', 'form', 'norm')),
        // round fermata above
        221, CreateSparseArray('Fermata', CreateDictionary('shape', 'curved', 'form', 'norm')),
        // triangular fermata above
        222, CreateSparseArray('Fermata', CreateDictionary('shape', 'angular', 'form', 'norm')),
        // staccato below
        225, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','stacc', 'place','below'))),
        // staccatissimo below
        226, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','stacciss', 'place','below'))),
        // spiccato below
        227, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','spicc', 'place','below'))),
        // marcato below
        230, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','marc', 'place','below'))),
        // square fermata below
        236, CreateSparseArray('Fermata', CreateDictionary('shape', 'square', 'form', 'inv')),
        // round fermata below
        237, CreateSparseArray('Fermata', CreateDictionary('shape', 'curved', 'form', 'inv')),
        // triangular fermata below
        238, CreateSparseArray('Fermata', CreateDictionary('shape', 'angular', 'form', 'inv')),
        //upbow below
        233, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','upbow', 'place','below'))),
        //dnbow below
        234, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','dnbow', 'place','below'))),
        //snap
        243, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','snap'))),
        //scoop
        480, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','scoop'))),
        //fall
        481, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','fall'))),
        //fingernail
        490, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','fingernail'))),
        //doit
        494, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','doit'))),
        //plop
        495, AsModifier(CreateSparseArray('Artic', CreateDictionary('artic','plop')))
        // 'Pedal', CreateSparseArray('Pedal', CreateDictionary('dir', 'down', 'func', 'sustain')) //Pedal
    ), Self);

    return symbolHandlers;

}//$end


function HandleSymbol (sobj) {
    handler = SymbolHandlers.Index[sobj.Index];
    if (null = handler)
    {
        handler = SymbolHandlers.Name[sobj.Name];
    }
    if (null != handler)
    {
        return handler.HandleObject(sobj);
    }
} //$end

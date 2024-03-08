// TODO: Missing symbols
// '240' double staccato
// '241' tripe staccato
// '242' quadruple staccato

function InitSymbolHandlers () {
    //$module(SymbolHandler.mss)

    Self._property:SymbolHandlers = CreateDictionary(
        'Index', CreateDictionary(),
        'Name', CreateDictionary()
    );

    RegisterSymbolHandlers(CreateDictionary(
        'byProperty', 'Index',
        'withTemplateHandler', 'ModifierTemplateHandler',
        'handlerPlugin', Self
    ), CreateDictionary(
        //heel 1
        52, @Element('Artic', @Attrs('artic','heel')),
        //heel 2
        53, @Element('Artic', @Attrs('artic','heel')),
        //toe 1
        54, @Element('Artic', @Attrs('artic','toe')),
        //toe 2
        55, @Element('Artic', @Attrs('artic','toe')),
        //stop
        160, @Element('Artic', @Attrs('artic','stop')),
        //open
        162, @Element('Artic', @Attrs('artic','open')),
        //damp
        163, @Element('Artic', @Attrs('artic','damp')),
        //damp (2)
        164, @Element('Artic', @Attrs('artic','damp')),
        //damp (3)
        165, @Element('Artic', @Attrs('artic','damp')),
        //damp (4)
        166, @Element('Artic', @Attrs('artic','damp')),
        //staccato above
        209, @Element('Artic', @Attrs('artic','stacc', 'place','above')),
        //staccatissimo above
        210, @Element('Artic', @Attrs('artic','stacciss', 'place','above')),
        //spiccato above
        211, @Element('Artic', @Attrs('artic','spicc', 'place','above')),
        //ten above
        212, @Element('Artic', @Attrs('artic','ten', 'place','above')),
        //marc above
        214, @Element('Artic', @Attrs('artic','marc', 'place','above')),
        //upbow above
        217, @Element('Artic', @Attrs('artic','upbow', 'place','above')),
        //dnbow above
        218, @Element('Artic', @Attrs('artic','dnbow', 'place','above')),
        // staccato below
        225, @Element('Artic', @Attrs('artic','stacc', 'place','below')),
        // staccatissimo below
        226, @Element('Artic', @Attrs('artic','stacciss', 'place','below')),
        // spiccato below
        227, @Element('Artic', @Attrs('artic','spicc', 'place','below')),
        // marcato below
        230, @Element('Artic', @Attrs('artic','marc', 'place','below')),
        //upbow below
        233, @Element('Artic', @Attrs('artic','upbow', 'place','below')),
        //dnbow below
        234, @Element('Artic', @Attrs('artic','dnbow', 'place','below')),
        //snap
        243, @Element('Artic', @Attrs('artic','snap')),
        //scoop
        480, @Element('Artic', @Attrs('artic','scoop')),
        //fall
        481, @Element('Artic', @Attrs('artic','fall')),
        //fingernail
        490, @Element('Artic', @Attrs('artic','fingernail')),
        //doit
        494, @Element('Artic', @Attrs('artic','doit')),
        //plop
        495, @Element('Artic', @Attrs('artic','plop'))
        // square fermata above
    ));

    RegisterSymbolHandlers(CreateDictionary(
        'byProperty', 'Index',
        'withTemplateHandler', 'ControlEventTemplateHandler',
        'handlerPlugin', Self
    ), CreateDictionary(
        220, @Element('Fermata', @Attrs('shape', 'square', 'form', 'norm')),
        // round fermata above
        221, @Element('Fermata', @Attrs('shape', 'curved', 'form', 'norm')),
        // triangular fermata above
        222, @Element('Fermata', @Attrs('shape', 'angular', 'form', 'norm')),
        // square fermata below
        236, @Element('Fermata', @Attrs('shape', 'square', 'form', 'inv')),
        // round fermata below
        237, @Element('Fermata', @Attrs('shape', 'curved', 'form', 'inv')),
        // triangular fermata below
        238, @Element('Fermata', @Attrs('shape', 'angular', 'form', 'inv'))
        // 'Pedal', @Element('Pedal', @Attrs('dir', 'down', 'func', 'sustain')) //Pedal
    ));
}//$end


function RegisterSymbolHandlers (header, handlerDefinitions) {
    RegisterHandlers(SymbolHandlers[header.byProperty], header, handlerDefinitions);
}  //$end


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

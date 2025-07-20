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

    RegisterSymbolHandlers('Index', 'ModifierTemplateHandler', CreateDictionary(
        // heel 1
        52, @Element('artic', @Attrs('artic','heel')),
        // heel 2
        53, @Element('artic', @Attrs('artic','heel')),
        // toe 1
        54, @Element('artic', @Attrs('artic','toe')),
        // toe 2
        55, @Element('artic', @Attrs('artic','toe')),
        // stop
        160, @Element('artic', @Attrs('artic','stop')),
        // open
        162, @Element('artic', @Attrs('artic','open')),
        // damp
        163, @Element('artic', @Attrs('artic','damp')),
        // damp (2)
        164, @Element('artic', @Attrs('artic','damp')),
        // damp (3)
        165, @Element('artic', @Attrs('artic','damp')),
        // damp (4)
        166, @Element('artic', @Attrs('artic','damp')),
        // staccato above
        209, @Element('artic', @Attrs('artic','stacc', 'place','above')),
        // staccatissimo above
        210, @Element('artic', @Attrs('artic','stacciss', 'place','above')),
        // spiccato above
        211, @Element('artic', @Attrs('artic','spicc', 'place','above')),
        // ten above
        212, @Element('artic', @Attrs('artic','ten', 'place','above')),
        // marc above
        214, @Element('artic', @Attrs('artic','marc', 'place','above')),
        // upbow above
        217, @Element('artic', @Attrs('artic','upbow', 'place','above')),
        // dnbow above
        218, @Element('artic', @Attrs('artic','dnbow', 'place','above')),
        // staccato below
        225, @Element('artic', @Attrs('artic','stacc', 'place','below')),
        // staccatissimo below
        226, @Element('artic', @Attrs('artic','stacciss', 'place','below')),
        // spiccato below
        227, @Element('artic', @Attrs('artic','spicc', 'place','below')),
        // marcato below
        230, @Element('artic', @Attrs('artic','marc', 'place','below')),
        // upbow below
        233, @Element('artic', @Attrs('artic','upbow', 'place','below')),
        // dnbow below
        234, @Element('artic', @Attrs('artic','dnbow', 'place','below')),
        // snap
        243, @Element('artic', @Attrs('artic','snap')),
        // scoop
        480, @Element('artic', @Attrs('artic','scoop')),
        // fall
        481, @Element('artic', @Attrs('artic','fall')),
        // fingernail
        490, @Element('artic', @Attrs('artic','fingernail')),
        // doit
        494, @Element('artic', @Attrs('artic','doit')),
        // plop
        495, @Element('artic', @Attrs('artic','plop'))
        // square fermata above
    ));

    RegisterSymbolHandlers('Index', 'ControlEventTemplateHandler', CreateDictionary(
        // trill
        32, @Element('trill'),
        // inverted mordent
        36, @Element('mordent', @Attrs('form', 'lower')),
        // mordent
        37, @Element('mordent', @Attrs('form','upper')),
        // turn
        38, @Element('turn', @Attrs('form', 'upper')),
        // inverted turn
        39, @Element('turn', @Attrs('form', 'lower')),
        // pedal
        48, @Element('pedal', @Attrs('dir', 'down', 'func', 'sustain')),
        49, @Element('pedal', @Attrs('dir', 'down', 'func', 'sustain')),
        50, @Element('pedal', @Attrs('dir', 'up', 'func', 'sustain')),
        // 51, @Element('pedal', @Attrs('dir', 'bounce', 'func', 'sustain', 'glyph.auth', 'smufl', 'glyph.name', 'keyboardPedalUpNotch', 'glyph.num', 'U+E657'))
        220, @Element('fermata', @Attrs('shape', 'square', 'form', 'norm')),
        // round fermata above
        221, @Element('fermata', @Attrs('shape', 'curved', 'form', 'norm')),
        // triangular fermata above
        222, @Element('fermata', @Attrs('shape', 'angular', 'form', 'norm')),
        // square fermata below
        236, @Element('fermata', @Attrs('shape', 'square', 'form', 'inv')),
        // round fermata below
        237, @Element('fermata', @Attrs('shape', 'curved', 'form', 'inv')),
        // triangular fermata below
        238, @Element('fermata', @Attrs('shape', 'angular', 'form', 'inv'))
    ));
}//$end


function RegisterSymbolHandlers (idProperty, handlerMethod, templatesById) {
    RegisterHandlers(Self, SymbolHandlers, idProperty, handlerMethod, templatesById);
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

// TODO: Missing symbols
// '240' double staccato
// '241' tripe staccato
// '242' quadruple staccato


function InitModifierSymbols () {
    //$module(SymbolStyles.mss)

    // Create a dictionary with symbol index number as key (sobj.Index) and a value that determines the element that has to be created
    // All the symbols defined here should be created as children of note elements (modifier)
    // Artic() is the element that has to be created like -> modifier = libmei.Artic();
    // Every other SparseArray determines an attribute that needs to be added to modifier
    // E.g.: '52' becomes <artic artic='heel' />

    modifierMap = CreateDictionary(
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

    return modifierMap;
}  //$end

function InitControlEventSymbols () {
    //$module(SymbolStyles.mss)

    // Create a dictionary with symbol index number as key (sobj.Index) and a value that determines the element that has to be created
    // All the symbols defined here should be created as children of measure (control events)
    // Turn() is the element that has to be created like -> controlEvent = libmei.Turn();
    // Every other SparseArray determines an attribute that needs to be added to modifier
    // E.g.: '36' becomes <turn form='lower' />

    controlEventMap = CreateDictionary(
        '36', CreateSparseArray('Mordent', CreateDictionary('form', 'lower')),      //inverted mordent
        '37', CreateSparseArray('Mordent', CreateDictionary('form','upper')),       //mordent
        '38', CreateSparseArray('Turn', CreateDictionary('form', 'upper')),         //turn
        '39', CreateSparseArray('Turn', CreateDictionary('form', 'lower'))          //inverted turn
    );

    return controlEventMap;

}   //$end

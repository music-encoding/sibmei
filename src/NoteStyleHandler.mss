function InitNoteStyleAttributes () {
    Self._property:NoteStyleAttributes = CreateDictionary(
        'NoteStyle', CreateSparseArray(),
        'NoteStyleName', CreateDictionary()
    );

    // Where possible, the following note styles are encoded with values from
    // data.HEADSHAPE.list. Where this is not possible, the SMuFL glyphs are
    // referenced.
    // TODO: Add SMuFL glyphs for all note styles once it became clear how to
    // do that: https://github.com/music-encoding/music-encoding/pull/1832
    RegisterNoteStyle('NoteStyle', CrossNoteStyle,                0,   0,   @Attrs('head.shape', 'x')); // 1
    RegisterNoteStyle('NoteStyle', DiamondNoteStyle,              0,   0,   @Attrs('head.shape', 'diamond', 'head.fill', 'void')); // 2
    RegisterNoteStyle('NoteStyle', BeatWithoutStemNoteStyle,      0,   0,   @Attrs('head.shape', 'slash', 'stem.len', '0', 'type', 'no-ledgerlines')); // 3
    RegisterNoteStyle('NoteStyle', BeatNoteStyle,                 0,   0,   @Attrs('head.shape', 'slash', 'type', 'no-ledgerlines')); // 4
    RegisterNoteStyle('NoteStyle', CrossOrDiamondNoteStyle,       0,   511, @Attrs('head.shape', 'x')); // 5
    RegisterNoteStyle('NoteStyle', CrossOrDiamondNoteStyle,       512, 0,   @Attrs('head.shape', 'diamond')); // 5
    RegisterNoteStyle('NoteStyle', BlackAndWhiteDiamondNoteStyle, 512, 0,   @Attrs('head.shape', 'diamond')); // 6
    RegisterNoteStyle('NoteStyle', HeadlessNoteStyle,             0,   0,   @Attrs('head.visible', 'false', 'type', 'no-ledgerlines')); // 7
    RegisterNoteStyle('NoteStyle', StemlessNoteStyle,             0,   0,   @Attrs('stem.len', '0')); // 8
    RegisterNoteStyle('NoteStyle', SilentNoteStyle,               0,   0,   @Attrs('vel', '0')); // 9
    RegisterNoteStyle('NoteStyle', CueNoteStyle,                  0,   0,   @Attrs('fontsize', 'small')); // 10
    RegisterNoteStyle('NoteStyle', SlashedNoteStyle,              0,   511, @Attrs('head.shape', 'U+E0CF', 'head.auth', 'smufl')); // 11
    RegisterNoteStyle('NoteStyle', SlashedNoteStyle,              512, 0,   @Attrs('head.shape', 'U+E0D1', 'head.auth', 'smufl')); // 11
    RegisterNoteStyle('NoteStyle', BackSlashedNoteStyle,          0,   511, @Attrs('head.shape', 'U+E0D0', 'head.auth', 'smufl')); // 12
    RegisterNoteStyle('NoteStyle', BackSlashedNoteStyle,          512, 0,   @Attrs('head.shape', 'U+E0D2', 'head.auth', 'smufl')); // 12
    RegisterNoteStyle('NoteStyle', ArrowDownNoteStyle,            0,   511, @Attrs('head.shape', 'U+E0C7', 'head.auth', 'smufl', 'type', 'no-ledgerlines')); // 13
    RegisterNoteStyle('NoteStyle', ArrowDownNoteStyle,            512, 0,   @Attrs('head.shape', 'U+E0C6', 'head.auth', 'smufl', 'type', 'no-ledgerlines')); // 13
    RegisterNoteStyle('NoteStyle', ArrowUpNoteStyle,              0,   511, @Attrs('head.shape', 'U+E0BE', 'head.auth', 'smufl', 'type', 'no-ledgerlines')); // 14
    RegisterNoteStyle('NoteStyle', ArrowUpNoteStyle,              512, 0,   @Attrs('head.shape', 'U+E0BD', 'head.auth', 'smufl', 'type', 'no-ledgerlines')); // 14
    RegisterNoteStyle('NoteStyle', InvertedTriangleNoteStyle,     0,   511, @Attrs('head.shape', 'U+E0C7', 'head.auth', 'smufl')); // 15
    RegisterNoteStyle('NoteStyle', InvertedTriangleNoteStyle,     512, 0,   @Attrs('head.shape', 'U+E0C6', 'head.auth', 'smufl')); // 15
    RegisterNoteStyle('NoteStyle', ShapedNote1NoteStyle,          0,   511, @Attrs('head.shape', 'U+E0BE', 'head.auth', 'smufl')); // 16
    RegisterNoteStyle('NoteStyle', ShapedNote1NoteStyle,          512, 0,   @Attrs('head.shape', 'U+E0BD', 'head.auth', 'smufl')); // 16
    RegisterNoteStyle('NoteStyle', ShapedNote2NoteStyle,          0,   511, @Attrs('head.shape', 'U+E0CA', 'head.auth', 'smufl')); // 17
    RegisterNoteStyle('NoteStyle', ShapedNote2NoteStyle,          512, 0,   @Attrs('head.shape', 'U+E0CB', 'head.auth', 'smufl')); // 17
    RegisterNoteStyle('NoteStyle', ShapedNote3NoteStyle,          0,   511, @Attrs('head.shape', 'U+E0DB', 'head.auth', 'smufl')); // 18
    RegisterNoteStyle('NoteStyle', ShapedNote3NoteStyle,          512, 0,   @Attrs('head.shape', 'U+E0DD', 'head.auth', 'smufl')); // 18
    RegisterNoteStyle('NoteStyle', ShapedNote4StemUpNoteStyle,    0,   511, @Attrs('head.shape', 'U+E0C9', 'head.auth', 'smufl')); // 19
    RegisterNoteStyle('NoteStyle', ShapedNote4StemUpNoteStyle,    512, 0,   @Attrs('head.shape', 'U+E0C8', 'head.auth', 'smufl')); // 19
    // Despite the name `ShapedNote4StemDownNoteStyle`, this style looks just regular, and stems also behave like for regular notes
    RegisterNoteStyle('NoteStyle', ShapedNote4StemDownNoteStyle,  0,   0,   @Attrs()); // 20
    RegisterNoteStyle('NoteStyle', ShapedNote5NoteStyle,          0,   0,   @Attrs('head.shape', 'rectangle')); // 21
    RegisterNoteStyle('NoteStyle', ShapedNote6NoteStyle,          0,   511, @Attrs('head.shape', 'U+E0CD', 'head.auth', 'smufl')); // 22
    RegisterNoteStyle('NoteStyle', ShapedNote6NoteStyle,          512, 0,   @Attrs('head.shape', 'U+E0CC', 'head.auth', 'smufl')); // 22
    RegisterNoteStyle('NoteStyle', ShapedNote7NoteStyle,          0,   511, @Attrs('head.shape', 'U+E0C0', 'head.auth', 'smufl')); // 23
    RegisterNoteStyle('NoteStyle', ShapedNote7NoteStyle,          512, 0,   @Attrs('head.shape', 'U+E0BF', 'head.auth', 'smufl')); // 23
    // For the following styles, ManuScript does not define a variable name.
    // The listed names are taken from the note style dropdown.
    // Cross 2
    RegisterNoteStyle('NoteStyle', 24,                            0,   511, @Attrs('head.shape', 'U+E0A9', 'head.auth', 'smufl')); // 24
    RegisterNoteStyle('NoteStyle', 24,                            512, 0,   @Attrs('head.shape', 'U+E0B3', 'head.auth', 'smufl')); // 24
    // Stick notation: 'black' notehads and brevis noteheads are hidden. Other heads are regular.
    RegisterNoteStyle('NoteStyle', 25,                            0,   511, @Attrs('head.visible', 'false')); // 25
    RegisterNoteStyle('NoteStyle', 25,                            2048, 0,  @Attrs('head.visible', 'false')); // 25
    // Large cross
    RegisterNoteStyle('NoteStyle', 26,                            0,   511, @Attrs('head.shape', 'U+E0A9', 'head.auth', 'smufl', 'fontsize', 'large')); // 26
    RegisterNoteStyle('NoteStyle', 26,                            512, 0,   @Attrs('head.shape', 'U+E0DD', 'head.auth', 'smufl', 'fontsize', 'large')); // 26
    // Large stemless slash
    RegisterNoteStyle('NoteStyle', 27,                            0,   0,   @Attrs('head.shape', 'slash', 'stem.len', '0')); // 27
    // Large slash with stem
    RegisterNoteStyle('NoteStyle', 28,                            0,   0,   @Attrs('head.shape', 'slash')); // 28
    // Cross (ornate)
    RegisterNoteStyle('NoteStyle', 29,                            0,   511, @Attrs('head.shape', 'U+E0AA', 'head.auth', 'smufl')); // 29
    RegisterNoteStyle('NoteStyle', 29,                            512, 0,   @Attrs('head.shape', 'U+E0B7', 'head.auth', 'smufl')); // 29
    // Ping
    RegisterNoteStyle('NoteStyle', 30,                            0,   0,   @Attrs('head.shape', 'U+E115', 'head.auth', 'smufl')); // 30
}  // $end


export function RegisterNoteStyle (idProperty, idValue, minDuration, maxDuration, attributes) {
    // * `idProperty`: may be either `'NoteStyle'` or `'NoteStyleName'`
    // * `idValue`: is an integer if `idProperty = 'NoteStyle'`, or a string if
    //   `idProperty = 'NoteStyleName'`
    // * `minDuration`: the lowest Note Duration the template applies to
    // * `maxDuration`: the highest Duration (inclusive) the template applies
    //   to. If it is 0, the template applies to all Durations higher than
    //   `minDuration`.
    // * `attributes`: Dictionary of attribute name/value pairs

    attributesByDuration = NoteStyleAttributes.@idProperty[idValue];
    if (null = attributesByDuration)
    {
        attributesByDuration = CreateSparseArray();
        NoteStyleAttributes.@idProperty[idValue] = attributesByDuration;
    }

    // Create lookup table by iterating over all possible Durations
    for each duration in DurByDuration.ValidIndices
    {
        if (duration >= minDuration and (maxDuration = 0 or duration <= maxDuration))
        {
            attributesByDuration[duration] = attributes;
        }
    }
}  //$end


function HandleNoteStyle (nobj, noteElement) {
    attributesByDuration = NoteStyleAttributes.NoteStyle[nobj.NoteStyle];
    if (null = attributesByDuration)
    {
        attributesByDuration = NoteStyleAttributes.NoteStyleName[nobj.NoteStyleName];
    }
    if (null != attributesByDuration)
    {
        attributes = attributesByDuration[nobj.Duration];
        if (null != attributes)
        {
            for each Name name in attributes
            {
                noteElement.attrs[name] = attributes[name];
            }
        }
    }
}  // $end

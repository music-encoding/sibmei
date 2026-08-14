function InitNoteStyleAttributes () {
    Self._property:NoteStyleAttributes = CreateDictionary(
        'NoteStyle', CreateSparseArray(),
        'NoteStyleName', CreateDictionary()
    );

    // Where possible, the following note styles are encoded with values from
    // data.HEADSHAPE.list. Where this is not possible, SMuFL codepoints are
    // referenced. In that case, also a more human-readable category is added
    // to the `@type` attribute.
    // TODO: properly encode hidden ledger lines once MEI supports it:
    // https://github.com/music-encoding/music-encoding/pull/1833
    RegisterNoteStyle('NoteStyle', CrossNoteStyle,                0,   0,   @Attrs('head.shape', 'x')); // 1
    RegisterNoteStyle('NoteStyle', DiamondNoteStyle,              0,   0,   @Attrs('head.shape', 'diamond', 'head.fill', 'void')); // 2
    RegisterNoteStyle('NoteStyle', BeatWithoutStemNoteStyle,      0,   511, @Attrs('head.shape', 'U+E100', 'head.auth', 'smufl', 'stem.len', '0', 'type', 'beat-slash no-ledger')); // 3
    RegisterNoteStyle('NoteStyle', BeatWithoutStemNoteStyle,      512, 0,   @Attrs('head.shape', 'U+E104', 'head.auth', 'smufl', 'stem.len', '0', 'type', 'beat-slash no-ledger')); // 3
    RegisterNoteStyle('NoteStyle', BeatNoteStyle,                 0,   511, @Attrs('head.shape', 'U+E100', 'head.auth', 'smufl', 'type', 'beat-slash no-ledger')); // 4
    RegisterNoteStyle('NoteStyle', BeatNoteStyle,                 512, 0,   @Attrs('head.shape', 'U+E104', 'head.auth', 'smufl', 'type', 'beat-slash no-ledger')); // 4
    RegisterNoteStyle('NoteStyle', CrossOrDiamondNoteStyle,       0,   511, @Attrs('head.shape', 'x')); // 5
    RegisterNoteStyle('NoteStyle', CrossOrDiamondNoteStyle,       512, 0,   @Attrs('head.shape', 'diamond')); // 5
    RegisterNoteStyle('NoteStyle', BlackAndWhiteDiamondNoteStyle, 0,   0,   @Attrs('head.shape', 'diamond')); // 6
    RegisterNoteStyle('NoteStyle', HeadlessNoteStyle,             0,   0,   @Attrs('head.visible', 'false', 'type', 'no-ledger')); // 7
    RegisterNoteStyle('NoteStyle', StemlessNoteStyle,             0,   0,   @Attrs('stem.len', '0')); // 8
    RegisterNoteStyle('NoteStyle', SilentNoteStyle,               0,   0,   @Attrs('vel', '0')); // 9
    // @fontsize='small' is the best we can do, though it may be understood as
    // applying to the entire note, not just the head
    RegisterNoteStyle('NoteStyle', CueNoteStyle,                  0,   0,   @Attrs('fontsize', 'small')); // 10
    RegisterNoteStyle('NoteStyle', SlashedNoteStyle,              0,   0,   @Attrs('head.mod', 'slash')); // 11
    RegisterNoteStyle('NoteStyle', BackSlashedNoteStyle,          0,   0,   @Attrs('head.mod', 'backslash')); // 12
    RegisterNoteStyle('NoteStyle', ArrowDownNoteStyle,            0,   511, @Attrs('head.shape', 'U+E0C7', 'head.auth', 'smufl', 'stem.pos', 'center', 'type', 'isotriangle-down no-ledger')); // 13
    RegisterNoteStyle('NoteStyle', ArrowDownNoteStyle,            512, 0,   @Attrs('head.shape', 'U+E0C6', 'head.auth', 'smufl', 'stem.pos', 'center', 'type', 'isotriangle-down no-ledger')); // 13
    RegisterNoteStyle('NoteStyle', ArrowUpNoteStyle,              0,   511, @Attrs('head.shape', 'isotriangle', 'stem.pos', 'center', 'type', 'no-ledger')); // 14
    RegisterNoteStyle('NoteStyle', ArrowUpNoteStyle,              512, 0,   @Attrs('head.shape', 'isotriangle', 'stem.pos', 'center', 'type', 'no-ledger')); // 14
    RegisterNoteStyle('NoteStyle', InvertedTriangleNoteStyle,     0,   511, @Attrs('head.shape', 'U+E0C7', 'head.auth', 'smufl', 'type', 'isotriangle-down')); // 15
    RegisterNoteStyle('NoteStyle', InvertedTriangleNoteStyle,     512, 0,   @Attrs('head.shape', 'U+E0C6', 'head.auth', 'smufl', 'type', 'isotriangle-down')); // 15
    RegisterNoteStyle('NoteStyle', ShapedNote1NoteStyle,          0,   0,   @Attrs('head.shape', 'isotriangle')); // 16
    RegisterNoteStyle('NoteStyle', ShapedNote2NoteStyle,          0,   0,   @Attrs('head.shape', 'semicircle')); // 17
    // This is an alternative diamond style (non-oblique, uniform outlines)
    RegisterNoteStyle('NoteStyle', ShapedNote3NoteStyle,          0,   511, @Attrs('head.shape', 'U+E0DB', 'head.auth', 'smufl', 'type', 'diamond')); // 18
    RegisterNoteStyle('NoteStyle', ShapedNote3NoteStyle,          512, 0,   @Attrs('head.shape', 'U+E0DD', 'head.auth', 'smufl', 'type', 'diamond')); // 18
    // @head.shape='rtriangle' is not used here to be consistent with the
    // related ShapedNote4StemDownNoteStyle style and because the spec is a bit
    // unclear for rtriangle (it mentions a glyph that doesn't quite fit)
    // The 'StemUp' in the the style name does not mean that the stem direction
    // is forced upwards, it means the head is suited for stem up notes.
    RegisterNoteStyle('NoteStyle', ShapedNote4StemUpNoteStyle,    0,   511, @Attrs('head.shape', 'U+E0C9', 'head.auth', 'smufl', 'type', 'triangle-up-right')); // 19
    RegisterNoteStyle('NoteStyle', ShapedNote4StemUpNoteStyle,    512, 0,   @Attrs('head.shape', 'U+E0C8', 'head.auth', 'smufl', 'type', 'triangle-up-right')); // 19
    // ShapedNote5NoteStyle is the same as the default style, so nothing to do
    // RegisterNoteStyle('NoteStyle', ShapedNote5NoteStyle,  0,   0,   @Attrs()); // 20
    RegisterNoteStyle('NoteStyle', ShapedNote6NoteStyle,          0,   0,   @Attrs('head.shape', 'square')); // 21
    RegisterNoteStyle('NoteStyle', ShapedNote7NoteStyle,          0,   0,   @Attrs('head.shape', 'piewedge')); // 22
    // The 'StemDown' in the the style name does not mean that the stem direction
    // is forced downwards, it means the head is suited for stem down notes.
    RegisterNoteStyle('NoteStyle', ShapedNote4StemDownNoteStyle,  0,   511, @Attrs('head.shape', 'U+E0C0', 'head.auth', 'smufl', 'type', 'triangle-down-left')); // 23
    RegisterNoteStyle('NoteStyle', ShapedNote4StemDownNoteStyle,  512, 0,   @Attrs('head.shape', 'U+E0BF', 'head.auth', 'smufl', 'type', 'triangle-down-left')); // 23
    // For the following styles, ManuScript does not define a variable name.
    // The listed names are taken from the note style dropdown.
    // Cross 2
    RegisterNoteStyle('NoteStyle', 24,                            0,   511, @Attrs('head.shape', 'U+E0A9', 'head.auth', 'smufl', 'type', 'x')); // 24
    RegisterNoteStyle('NoteStyle', 24,                            512, 0,   @Attrs('head.shape', 'U+E0B3', 'head.auth', 'smufl', 'type', 'x circled')); // 24
    // Stick notation: 'black' notehads and brevis noteheads are hidden. Other heads are regular.
    RegisterNoteStyle('NoteStyle', 25,                            0,   511, @Attrs('head.visible', 'false')); // 25
    // This is the default, so doesn't have to be encoded
    // RegisterNoteStyle('NoteStyle', 25,                            512,   2047, @Attrs('head.visible', 'true')); // 25
    RegisterNoteStyle('NoteStyle', 25,                            2048, 0,  @Attrs('head.visible', 'false')); // 25
    // Large cross
    RegisterNoteStyle('NoteStyle', 26,                            0,   511, @Attrs('head.shape', 'U+E104', 'head.auth', 'smufl', 'type', 'beat-cross')); // 26
    RegisterNoteStyle('NoteStyle', 26,                            512, 0,   @Attrs('head.shape', 'U+E0DD', 'head.auth', 'smufl', 'type', 'beat-cross')); // 26
    // Large stemless slash
    RegisterNoteStyle('NoteStyle', 27,                            0,   0,   @Attrs('head.shape', 'slash', 'stem.len', '0', 'type', 'no-ledger')); // 27
    // Large slash with stem
    RegisterNoteStyle('NoteStyle', 28,                            0,   0,   @Attrs('head.shape', 'slash', 'type', 'no-ledger')); // 28
    // Cross (ornate)
    RegisterNoteStyle('NoteStyle', 29,                            0,   511, @Attrs('head.shape', 'U+E0AA', 'head.auth', 'smufl', 'type', 'ornate-x')); // 29
    RegisterNoteStyle('NoteStyle', 29,                            512, 0,   @Attrs('head.shape', 'U+E0B7', 'head.auth', 'smufl', 'type', 'ornate-x')); // 29
    // Ping
    RegisterNoteStyle('NoteStyle', 30,                            0,   0,   @Attrs('head.shape', 'circle', 'head.mod', 'centerdot', 'head.fill', 'void')); // 30
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

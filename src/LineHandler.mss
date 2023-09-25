function InitLineHandlers () {
    //$module(LineHandler.mss)

    lineHandlers = CreateDictionary(
        'StyleId', CreateDictionary(),
        'StyleAsText', CreateDictionary()
    );

    handlerMap = CreateDictionary();
    for each Name styleId in Self._property:LineMap
    {
        handlerMap[styleId] = 'HandleLineTemplate';
    }
    RegisterHandlers(lineHandlers, CreateDictionary('StyleId', handlerMap), Self);

    return lineHandlers;
}//$end


function InitLineMap () {
    //$module(LineHandler.mss)
    // Create a dictionary with StyleID as key and a template as value.
    // See Utilities/MeiFactory() for further instructions.

    verticalLine = 'vertical line';

    lineMap = CreateDictionary(
        // Type = 'Line'
        'line.staff.arrow',                    CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'arrow')),
        'line.staff.arrow.black.right',        CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'arrow')),
        'line.staff.arrow.black.right.dashed', CreateSparseArray('Line', CreateDictionary('form', 'dashed', 'endsym', 'arrow')),
        'line.staff.arrow.black.right.left',   CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'arrow', 'endsym', 'arrow')),
        'line.staff.arrow.black.vertical',     CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'arrow')),
        'line.staff.arrow.white.right',        CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'arrowwhite')),
        'line.staff.arrow.white.right.dashed', CreateSparseArray('Line', CreateDictionary('form', 'dashed', 'endsym', 'arrowwhite')),
        'line.staff.arrow.white.right.left',   CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'arrowwhite', 'endsym', 'arrowwhite')),
        'line.staff.arrow.white.vertical',     CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'arrowwhite', 'type', verticalLine)),
        // 'line.staff.bend.hold',                CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        'line.staff.bracket.above',            CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angledown', 'endsym', 'angledown')),
        'line.staff.bracket.above.end',        CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'angledown')),
        'line.staff.bracket.above.start',      CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angledown')),
        'line.staff.bracket.below',            CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angleup', 'endsym', 'angleup')),
        'line.staff.bracket.below.end',        CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'angleup')),
        'line.staff.bracket.below.start',      CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angleup')),
        'line.staff.bracket.vertical',         CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angleleft', 'endsym', 'angleleft')),
        'line.staff.bracket.vertical.2',       CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angleright', 'endsym', 'angleright')),
        'line.staff.dashed',                   CreateSparseArray('Line', CreateDictionary('form', 'dashed')),
        'line.staff.dashed.vertical',          CreateSparseArray('Line', CreateDictionary('form', 'dashed', 'type', verticalLine)),
        'line.staff.dotted',                   CreateSparseArray('Line', CreateDictionary('form', 'dotted')),
        // TODO: Sibelius uses a vertical stroke at the end, but we don't have a fitting @endsym value
        'line.staff.guitareffect',             CreateSparseArray('Line', CreateDictionary('form', 'dashed', 'type', 'guitareffect')),
        // 'line.staff.harmonic.artificial',      CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.harmonic.harp',            CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.harmonic.pinch',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.harmonic.touch',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.harmonics',                CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // The Hauptstimme line type only has a start symbol and an end symbol
        // without an actual line. Therefore set @lwidth to 0.
        // TODO: Add create two separate symbols instead?
        'line.staff.hauptstimme',              CreateSparseArray('Line', CreateDictionary('startsym', 'H', 'endsym', 'angledown')),
        // 'line.staff.letring',                  CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.mute.palm',                CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // TODO: The Nebenstimme line type only has a start symbol and an end symbol without an actual line.
        'line.staff.nebenstimme',              CreateSparseArray('Line', CreateDictionary('startsym', 'N', 'endsym', 'angledown', 'lwidth', '0')),
        // 'line.staff.pick.scrape',              CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        'line.staff.plain',                    CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.rake',                     CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.slide',                    CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.above.1',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.above.2',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.above.3',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.above.4',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.above.5',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.above.6',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.above.7',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.above.8',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.below.1',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.below.2',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.below.3',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.below.4',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.below.5',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.below.6',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.below.7',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.string.below.8',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        'line.staff.vertical',                 CreateSparseArray('Line', CreateDictionary('form', 'solid', 'type', verticalLine)),
        'line.staff.vibrato',                  CreateSparseArray('Line', CreateDictionary('form', 'wavy', 'type', 'vibrato')),
        // 'line.staff.vibrato.bar',              CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        'line.staff.vibrato.wide',             CreateSparseArray('Line', CreateDictionary('form', 'wavy', 'width', 'wide')),

        // Type = 'Hairpin'
        'line.staff.hairpin.crescendo', CreateSparseArray('Hairpin', CreateDictionary('form', 'cres')),
        'line.staff.hairpin.crescendo.dashed', CreateSparseArray('Hairpin', CreateDictionary('form', 'cres', 'lform', 'dashed')),
        'line.staff.hairpin.crescendo.bracketed', CreateSparseArray('Hairpin', CreateDictionary('form', 'cres')),
        'line.staff.hairpin.crescendo.dotted', CreateSparseArray('Hairpin', CreateDictionary('form', 'cres', 'lform', 'dotted')),
        'line.staff.hairpin.crescendo.fromsilence', CreateSparseArray('Hairpin', CreateDictionary('form', 'cres', 'niente', 'true')),
        'line.staff.hairpin.diminuendo', CreateSparseArray('Hairpin', CreateDictionary('form', 'dim')),
        'line.staff.hairpin.diminuendo.bracketed', CreateSparseArray('Hairpin', CreateDictionary('form', 'dim')),
        'line.staff.hairpin.diminuendo.dashed', CreateSparseArray('Hairpin', CreateDictionary('form', 'dim', 'lform', 'dashed')),
        'line.staff.hairpin.diminuendo.dotted', CreateSparseArray('Hairpin', CreateDictionary('form', 'dim', 'lform', 'dotted')),
        'line.staff.hairpin.diminuendo.tosilence', CreateSparseArray('Hairpin', CreateDictionary('form', 'dim', 'niente', 'true')),

        // Type = 'OctavaLine'
        'line.staff.octava.minus15', CreateSparseArray('Octave', CreateDictionary('dis', '15', 'place', 'below')),
        'line.staff.octava.minus8', CreateSparseArray('Octave', CreateDictionary('dis', '8', 'place', 'below')),
        'line.staff.octava.plus15', CreateSparseArray('Octave', CreateDictionary('dis', '15', 'place', 'above')),
        'line.staff.octava.plus8', CreateSparseArray('Octave', CreateDictionary('dis', '8', 'place', 'above')),

        // Type = 'GlissandoLine'
        // TODO: For line.staff.gliss.straight and line.staff.port.straight,
        // Sibelius has an added text 'gliss.' or 'port.' above the line
        'line.staff.gliss.straight', CreateSparseArray('Gliss', CreateDictionary()),
        'line.staff.gliss.wavy', CreateSparseArray('Gliss', CreateDictionary('lform', 'wavy')),
        'line.staff.port.straight', CreateSparseArray('Gliss', CreateDictionary()),

        // Type = 'Slur'
        // 'down' and 'up' don't really mean anything. Sibelius handles both
        // styles in the same way and it doesn't mean the slurs are actually
        // curved upwards or downwards.  Pressing 's' to create a slur will
        // apparently always create a slur with style `line.staff.slur.up`, no
        // matter the resulting curvature.  With ManuScript, there is no way we
        // can find out the actual curvature.
        'line.staff.slur.down', CreateSparseArray('Slur'),
        'line.staff.slur.down.bracketed', CreateSparseArray('Slur', CreateDictionary('type', 'bracketed')),
        'line.staff.slur.down.dashed', CreateSparseArray('Slur', CreateDictionary('lform', 'dashed')),
        'line.staff.slur.down.dotted', CreateSparseArray('Slur', CreateDictionary('lform', 'dotted')),
        'line.staff.slur.up', CreateSparseArray('Slur'),
        'line.staff.slur.up.bracketed', CreateSparseArray('Slur', CreateDictionary('type', 'bracketed')),
        'line.staff.slur.up.dashed', CreateSparseArray('Slur', CreateDictionary('lform', 'dashed')),
        'line.staff.slur.up.dotted', CreateSparseArray('Slur', CreateDictionary('lform', 'dotted')),
        // A slur with this style can apparently not be created vie the UI, but
        // it can be created with ManuScript
        'line.staff.tie', CreateSparseArray('Tie')
    );

    return lineMap;
} //$end


function HandleLine (lobj) {
    //$module(LineHandler.mss)
    voicenum = lobj.VoiceNumber;
    bar = lobj.ParentBar;

    if (voicenum = 0)
    {
        // assign it to the first voice, since we don't have any notes in voice/layer 0.
        lobj.VoiceNumber = 1;
        warnings = Self._property:warnings;
        warnings.Push(utils.Format(_ObjectAssignedToAllVoicesWarning, bar.BarNumber, voicenum, 'Symbol'));
    }

    lineHandlers = Self._property:LineHandlers;
    lineMap = Self._property:LineMap;

    // look for line style ID in lineHandlers.StyleId
    if (lineHandlers.StyleId.MethodExists(lobj.StyleId))
    {
        styleId = lobj.StyleId;
        return lineHandlers.StyleId.@styleId(lobj, lineMap[styleId]);
    }
    // look for line name in lineHandlers.StyleAsText
    if (lineHandlers.StyleAsText.MethodExists(lobj.StyleAsText))
    {
        styleAsText = lobj.StyleAsText;
        return lineHandlers.StyleAsText.@styleAsText(lobj, lineMap[styleAsText]);
    }
} //$end


function HandleLineTemplate(this, lobj, template){
    //$module(LineHandler.mss)

    line = MeiFactory(template);
    AddControlEventAttributes(lobj, line);
    lobj._property:mobj = line;
    PushToHashedLayer(Self._property:LineEndResolver, lobj.EndBarNumber, lobj);

    return line;
}   //$end

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
        'line.staff.vibrato.wide',             CreateSparseArray('Line', CreateDictionary('form', 'wavy', 'width', 'wide'))
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

    return line;
} //$end

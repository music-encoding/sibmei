function InitLineHandlers () {
    //$module(LineHandler.mss)

    lineHandlers = CreateDictionary(
        'StyleId', CreateDictionary(),
        'StyleAsText', CreateDictionary()
    );

    verticalLine = 'vertical line';

    // Commented out line styles are not supported yet.  Some of them might need
    // to be registered to a more specialized line handler than the standard
    // HandleControlEvent().

    RegisterHandlers(lineHandlers.StyleId, CreateDictionary(
        ///////////////////////
        // Lines with @endid //
        ///////////////////////

        // Type = 'Line'
        'line.staff.arrow',                    CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'arrow', 'endid', 'Next')),
        'line.staff.arrow.black.right',        CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'arrow', 'endid', 'Next')),
        'line.staff.arrow.black.right.dashed', CreateSparseArray('Line', CreateDictionary('form', 'dashed', 'endsym', 'arrow', 'endid', 'Next')),
        'line.staff.arrow.black.right.left',   CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'arrow', 'endsym', 'arrow', 'endid', 'Next')),
        'line.staff.arrow.black.vertical',     CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'arrow', 'endid', 'PreciseMatch')),
        'line.staff.arrow.white.right',        CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'arrowwhite', 'endid', 'Next')),
        'line.staff.arrow.white.right.dashed', CreateSparseArray('Line', CreateDictionary('form', 'dashed', 'endsym', 'arrowwhite', 'endid', 'Next')),
        'line.staff.arrow.white.right.left',   CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'arrowwhite', 'endsym', 'arrowwhite', 'endid', 'Next')),
        'line.staff.arrow.white.vertical',     CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'arrowwhite', 'type', verticalLine, 'endid', 'PreciseMatch')),
        // 'line.staff.bend.hold',                CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        'line.staff.bracket.above',            CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angledown', 'endsym', 'angledown', 'endid', 'Previous')),
        'line.staff.bracket.above.end',        CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'angledown', 'endid', 'Previous')),
        'line.staff.bracket.below',            CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angleup', 'endsym', 'angleup', 'endid', 'Previous')),
        'line.staff.bracket.below.end',        CreateSparseArray('Line', CreateDictionary('form', 'solid', 'endsym', 'angleup', 'endid', 'Previous')),
        'line.staff.bracket.vertical',         CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angleleft', 'endsym', 'angleleft', 'endid', 'PreciseMatch')),
        'line.staff.bracket.vertical.2',       CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angleright', 'endsym', 'angleright', 'endid', 'PreciseMatch')),
        'line.staff.dashed.vertical',          CreateSparseArray('Line', CreateDictionary('form', 'dashed', 'type', verticalLine, 'endid', 'PreciseMatch')),
        // TODO: Sibelius uses a vertical stroke at the end, but we don't have a fitting @endsym value
        'line.staff.guitareffect',             CreateSparseArray('Line', CreateDictionary('form', 'dashed', 'type', 'guitareffect', 'endid', 'PreciseMatch')),
        // 'line.staff.harmonic.artificial',      CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.harmonic.harp',            CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.harmonic.pinch',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.harmonic.touch',           CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.harmonics',                CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // The Hauptstimme line type only has a start symbol and an end symbol
        // without an actual line. Therefore set @lwidth to 0.
        // TODO: Add create two separate symbols instead?
        'line.staff.hauptstimme',              CreateSparseArray('Line', CreateDictionary('startsym', 'H', 'endsym', 'angledown', 'endid', 'Previous')),
        // 'line.staff.letring',                  CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // 'line.staff.mute.palm',                CreateSparseArray('Line', CreateDictionary('form', 'solid')),
        // TODO: The Nebenstimme line type only has a start symbol and an end symbol without an actual line.
        'line.staff.nebenstimme',              CreateSparseArray('Line', CreateDictionary('startsym', 'N', 'endsym', 'angledown', 'lwidth', '0', 'endid', 'Previous')),
        // 'line.staff.pick.scrape',              CreateSparseArray('Line', CreateDictionary('form', 'solid')),
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
        'line.staff.vertical',                 CreateSparseArray('Line', CreateDictionary('form', 'solid', 'type', verticalLine, 'endid', 'PreciseMatch')),

        // Type = 'OctavaLine'
        'line.staff.octava.minus15', CreateSparseArray('Octave', CreateDictionary('dis', '15', 'dis.place', 'below', 'endid', 'Previous')),
        'line.staff.octava.minus8', CreateSparseArray('Octave', CreateDictionary('dis', '8', 'dis.place', 'below', 'endid', 'Previous')),
        'line.staff.octava.plus15', CreateSparseArray('Octave', CreateDictionary('dis', '15', 'dis.place', 'above', 'endid', 'Previous')),
        'line.staff.octava.plus8', CreateSparseArray('Octave', CreateDictionary('dis', '8', 'dis.place', 'above', 'endid', 'Previous')),

        // Type = 'GlissandoLine'
        // TODO: For line.staff.gliss.straight and line.staff.port.straight,
        // Sibelius has an added text 'gliss.' or 'port.' above the line
        'line.staff.gliss.straight', CreateSparseArray('Gliss', CreateDictionary('endid', 'Next')),
        'line.staff.gliss.wavy', CreateSparseArray('Gliss', CreateDictionary('lform', 'wavy', 'endid', 'Next')),
        'line.staff.port.straight', CreateSparseArray('Gliss', CreateDictionary('endid', 'Next')),

        // Type = 'Slur'
        // 'down' and 'up' don't really mean anything. Sibelius handles both
        // styles in the same way and it doesn't mean the slurs are actually
        // curved upwards or downwards.  Pressing 's' to create a slur will
        // apparently always create a slur with style `line.staff.slur.up`, no
        // matter the resulting curvature.  With ManuScript, there is no way we
        // can find out the actual curvature.
        'line.staff.slur.down', CreateSparseArray('Slur', CreateDictionary('endid', 'PreciseMatch')),
        'line.staff.slur.down.bracketed', CreateSparseArray('Slur', CreateDictionary('type', 'bracketed', 'endid', 'PreciseMatch')),
        'line.staff.slur.down.dashed', CreateSparseArray('Slur', CreateDictionary('lform', 'dashed', 'endid', 'PreciseMatch')),
        'line.staff.slur.down.dotted', CreateSparseArray('Slur', CreateDictionary('lform', 'dotted', 'endid', 'PreciseMatch')),
        'line.staff.slur.up', CreateSparseArray('Slur', CreateDictionary('endid', 'PreciseMatch')),
        'line.staff.slur.up.bracketed', CreateSparseArray('Slur', CreateDictionary('type', 'bracketed', 'endid', 'PreciseMatch')),
        'line.staff.slur.up.dashed', CreateSparseArray('Slur', CreateDictionary('lform', 'dashed', 'endid', 'PreciseMatch')),
        'line.staff.slur.up.dotted', CreateSparseArray('Slur', CreateDictionary('lform', 'dotted', 'endid', 'PreciseMatch')),
        // A 'slur' with this style can apparently not be created via the UI,
        // but it can be created with ManuScript
        'line.staff.tie', CreateSparseArray('Tie', CreateDictionary('endid', 'PreciseMatch')),

        //////////////////////////
        // Lines without @endid //
        //////////////////////////

        // Type = 'Trill'
        // TODO: @endid should be set, but we need a special mechanism here:
        // The way Sibelius creates trill lines is that the trill line ends at
        // the next note (or rest) that does not belong to the trill any more.
        // @endid should point to the last note in the trill. Setting `endid`
        // to 'Previous' in the template does not work as the it will give us
        // the note we don't want, if the line goes until that note.
        // This means, we need to change the search strategies, or add an
        // an additional one.
        'line.staff.trill', CreateSparseArray('Trill', CreateDictionary()),

        // Type = 'Line'
        // Idea for a different declaration approach
        // 'line.staff.bracket.above.start',      CreateSparseArray('<', 'Line', 'form=', 'solid', 'startsym=', 'angledown', '/>'),
        'line.staff.bracket.above.start',      CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angledown')),
        'line.staff.bracket.below.start',      CreateSparseArray('Line', CreateDictionary('form', 'solid', 'startsym', 'angleup')),
        'line.staff.dashed',                   CreateSparseArray('Line', CreateDictionary('form', 'dashed')),
        'line.staff.dotted',                   CreateSparseArray('Line', CreateDictionary('form', 'dotted')),
        'line.staff.plain',                    CreateSparseArray('Line', CreateDictionary('form', 'solid')),
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
        'line.staff.hairpin.diminuendo.tosilence', CreateSparseArray('Hairpin', CreateDictionary('form', 'dim', 'niente', 'true'))
    ), Self);

    // Line types not handled yet:
    // Type = 'BeamLine'
    //   line.staff.beam
    // Type = 'Bend'
    //   line.staff.bend
    // Type = 'Box'
    //   line.staff.box
    // Type = 'HighLight'
    //   line.highlight
    // Type = 'RitardLine'
    //   line.system.tempo.accel
    //   line.system.tempo.accel.italic
    //   line.system.tempo.accel.italic.textonly
    //   line.system.tempo.accel.molto
    //   line.system.tempo.accel.molto.textonly
    //   line.system.tempo.accel.poco
    //   line.system.tempo.accel.poco.textonly
    //   line.system.tempo.accel.textonly
    //   line.system.tempo.rall
    //   line.system.tempo.rall.italic
    //   line.system.tempo.rall.italic.textonly
    //   line.system.tempo.rall.molto
    //   line.system.tempo.rall.molto.textonly
    //   line.system.tempo.rall.poco
    //   line.system.tempo.rall.poco.textonly
    //   line.system.tempo.rall.textonly
    //   line.system.tempo.rit
    //   line.system.tempo.rit.italic
    //   line.system.tempo.rit.italic.textonly
    //   line.system.tempo.rit.molto
    //   line.system.tempo.rit.molto.textonly
    //   line.system.tempo.rit.poco
    //   line.system.tempo.rit.poco.textonly
    //   line.system.tempo.rit.textonly

    return lineHandlers;
} //$end

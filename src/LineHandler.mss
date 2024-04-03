function InitLineHandlers () {
    //$module(LineHandler.mss)

    Self._property:LineHandlers = CreateDictionary(
        'StyleId', CreateDictionary(),
        'StyleAsText', CreateDictionary()
    );

    verticalLine = 'vertical line';

    // Commented out line styles are not supported yet. Some of them might need
    // to be registered to a more specialized line handler than the standard
    // HandleControlEvent().

    RegisterLineHandlers('StyleId', 'ControlEventTemplateHandler', CreateDictionary(
        ///////////////////////
        // Lines with @endid //
        ///////////////////////

        // Type = 'Line'
        'line.staff.arrow',                         @Element('Line', @Attrs('form', 'solid', 'endsym', 'arrow', 'endid', 'Next')),
        'line.staff.arrow.black.right',             @Element('Line', @Attrs('form', 'solid', 'endsym', 'arrow', 'endid', 'Next')),
        'line.staff.arrow.black.right.dashed',      @Element('Line', @Attrs('form', 'dashed', 'endsym', 'arrow', 'endid', 'Next')),
        'line.staff.arrow.black.right.left',        @Element('Line', @Attrs('form', 'solid', 'startsym', 'arrow', 'endsym', 'arrow', 'endid', 'Next')),
        'line.staff.arrow.black.vertical',          @Element('Line', @Attrs('form', 'solid', 'endsym', 'arrow', 'endid', 'PreciseMatch')),
        'line.staff.arrow.white.right',             @Element('Line', @Attrs('form', 'solid', 'endsym', 'arrowwhite', 'endid', 'Next')),
        'line.staff.arrow.white.right.dashed',      @Element('Line', @Attrs('form', 'dashed', 'endsym', 'arrowwhite', 'endid', 'Next')),
        'line.staff.arrow.white.right.left',        @Element('Line', @Attrs('form', 'solid', 'startsym', 'arrowwhite', 'endsym', 'arrowwhite', 'endid', 'Next')),
        'line.staff.arrow.white.vertical',          @Element('Line', @Attrs('form', 'solid', 'endsym', 'arrowwhite', 'type', verticalLine, 'endid', 'PreciseMatch')),
        // 'line.staff.bend.hold',                     @Element('Line', @Attrs('form', 'solid')),
        'line.staff.bracket.above',                 @Element('Line', @Attrs('form', 'solid', 'startsym', 'angledown', 'endsym', 'angledown', 'endid', 'Previous')),
        'line.staff.bracket.above.end',             @Element('Line', @Attrs('form', 'solid', 'endsym', 'angledown', 'endid', 'Previous')),
        'line.staff.bracket.below',                 @Element('Line', @Attrs('form', 'solid', 'startsym', 'angleup', 'endsym', 'angleup', 'endid', 'Previous')),
        'line.staff.bracket.below.end',             @Element('Line', @Attrs('form', 'solid', 'endsym', 'angleup', 'endid', 'Previous')),
        'line.staff.bracket.vertical',              @Element('Line', @Attrs('form', 'solid', 'startsym', 'angleleft', 'endsym', 'angleleft', 'endid', 'PreciseMatch')),
        'line.staff.bracket.vertical.2',            @Element('Line', @Attrs('form', 'solid', 'startsym', 'angleright', 'endsym', 'angleright', 'endid', 'PreciseMatch')),
        'line.staff.dashed.vertical',               @Element('Line', @Attrs('form', 'dashed', 'type', verticalLine, 'endid', 'PreciseMatch')),
        // TODO: Sibelius uses a vertical stroke at the end, but we don't have a fitting @endsym value
        'line.staff.guitareffect',                  @Element('Line', @Attrs('form', 'dashed', 'type', 'guitareffect', 'endid', 'PreciseMatch')),
        // 'line.staff.harmonic.artificial',           @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.harmonic.harp',                 @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.harmonic.pinch',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.harmonic.touch',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.harmonics',                     @Element('Line', @Attrs('form', 'solid')),
        // The Hauptstimme line type only has a start symbol and an end symbol
        // without an actual line. Therefore set @width to 0.
        'line.staff.hauptstimme',                   @Element('Line', @Attrs('startsym', 'H', 'endsym', 'angledown', 'width', '0', 'endid', 'Previous')),
        // 'line.staff.letring',                       @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.mute.palm',                     @Element('Line', @Attrs('form', 'solid')),
        // The Nebenstimme line type only has a start symbol and an end symbol without an actual line.
        'line.staff.nebenstimme',                   @Element('Line', @Attrs('startsym', 'N', 'endsym', 'angledown', 'width', '0', 'endid', 'Previous')),
        // 'line.staff.pick.scrape',                   @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.rake',                          @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.slide',                         @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.above.1',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.above.2',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.above.3',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.above.4',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.above.5',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.above.6',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.above.7',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.above.8',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.below.1',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.below.2',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.below.3',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.below.4',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.below.5',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.below.6',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.below.7',                @Element('Line', @Attrs('form', 'solid')),
        // 'line.staff.string.below.8',                @Element('Line', @Attrs('form', 'solid')),
        'line.staff.vertical',                      @Element('Line', @Attrs('form', 'solid', 'type', verticalLine, 'endid', 'PreciseMatch')),

        // Type = 'OctavaLine'
        'line.staff.octava.minus15',                @Element('Octave', @Attrs('dis', '15', 'dis.place', 'below', 'endid', 'Previous')),
        'line.staff.octava.minus8',                 @Element('Octave', @Attrs('dis', '8', 'dis.place', 'below', 'endid', 'Previous')),
        'line.staff.octava.plus15',                 @Element('Octave', @Attrs('dis', '15', 'dis.place', 'above', 'endid', 'Previous')),
        'line.staff.octava.plus8',                  @Element('Octave', @Attrs('dis', '8', 'dis.place', 'above', 'endid', 'Previous')),

        // Type = 'GlissandoLine'
        // TODO: For line.staff.gliss.straight and line.staff.port.straight,
        // Sibelius has an added text 'gliss.' or 'port.' above the line
        'line.staff.gliss.straight',                @Element('Gliss', @Attrs('endid', 'Next')),
        'line.staff.gliss.wavy',                    @Element('Gliss', @Attrs('lform', 'wavy', 'endid', 'Next')),
        'line.staff.port.straight',                 @Element('Gliss', @Attrs('endid', 'Next')),

        // Type = 'Slur'
        // 'down' and 'up' don't really mean anything. Sibelius handles both
        // styles in the same way and it doesn't mean the slurs are actually
        // curved upwards or downwards. Pressing 's' to create a slur will
        // apparently always create a slur with style `line.staff.slur.up`, no
        // matter the resulting curvature. With ManuScript, there is no way we
        // can find out the actual curvature.
        'line.staff.slur.down',                     @Element('Slur', @Attrs('endid', 'PreciseMatch')),
        'line.staff.slur.down.bracketed',           @Element('Slur', @Attrs('type', 'bracketed', 'endid', 'PreciseMatch')),
        'line.staff.slur.down.dashed',              @Element('Slur', @Attrs('lform', 'dashed', 'endid', 'PreciseMatch')),
        'line.staff.slur.down.dotted',              @Element('Slur', @Attrs('lform', 'dotted', 'endid', 'PreciseMatch')),
        'line.staff.slur.up',                       @Element('Slur', @Attrs('endid', 'PreciseMatch')),
        'line.staff.slur.up.bracketed',             @Element('Slur', @Attrs('type', 'bracketed', 'endid', 'PreciseMatch')),
        'line.staff.slur.up.dashed',                @Element('Slur', @Attrs('lform', 'dashed', 'endid', 'PreciseMatch')),
        'line.staff.slur.up.dotted',                @Element('Slur', @Attrs('lform', 'dotted', 'endid', 'PreciseMatch')),
        // A 'slur' with this style can apparently not be created via the UI,
        // but it can be created with ManuScript
        'line.staff.tie',                           @Element('Tie', @Attrs('endid', 'PreciseMatch')),

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
        'line.staff.trill',                         @Element('Trill', @Attrs()),

        // Type = 'Line'
        // Idea for a different declaration approach
        // 'line.staff.bracket.above.start',           @Element('<', 'Line', 'form=', 'solid', 'startsym=', 'angledown', '/>'),
        'line.staff.bracket.above.start',           @Element('Line', @Attrs('form', 'solid', 'startsym', 'angledown')),
        'line.staff.bracket.below.start',           @Element('Line', @Attrs('form', 'solid', 'startsym', 'angleup')),
        'line.staff.dashed',                        @Element('Line', @Attrs('form', 'dashed')),
        'line.staff.dotted',                        @Element('Line', @Attrs('form', 'dotted')),
        'line.staff.plain',                         @Element('Line', @Attrs('form', 'solid')),
        'line.staff.vibrato',                       @Element('Line', @Attrs('form', 'wavy', 'type', 'vibrato')),
        // 'line.staff.vibrato.bar',                   @Element('Line', @Attrs('form', 'solid')),
        'line.staff.vibrato.wide',                  @Element('Line', @Attrs('form', 'wavy', 'width', 'wide')),

        // Type = 'Hairpin'
        'line.staff.hairpin.crescendo',             @Element('Hairpin', @Attrs('form', 'cres')),
        'line.staff.hairpin.crescendo.dashed',      @Element('Hairpin', @Attrs('form', 'cres', 'lform', 'dashed')),
        'line.staff.hairpin.crescendo.bracketed',   @Element('Hairpin', @Attrs('form', 'cres')),
        'line.staff.hairpin.crescendo.dotted',      @Element('Hairpin', @Attrs('form', 'cres', 'lform', 'dotted')),
        'line.staff.hairpin.crescendo.fromsilence', @Element('Hairpin', @Attrs('form', 'cres', 'niente', 'true')),
        'line.staff.hairpin.diminuendo',            @Element('Hairpin', @Attrs('form', 'dim')),
        'line.staff.hairpin.diminuendo.bracketed',  @Element('Hairpin', @Attrs('form', 'dim')),
        'line.staff.hairpin.diminuendo.dashed',     @Element('Hairpin', @Attrs('form', 'dim', 'lform', 'dashed')),
        'line.staff.hairpin.diminuendo.dotted',     @Element('Hairpin', @Attrs('form', 'dim', 'lform', 'dotted')),
        'line.staff.hairpin.diminuendo.tosilence',  @Element('Hairpin', @Attrs('form', 'dim', 'niente', 'true'))
    ));

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
} //$end


function RegisterLineHandlers (idProperty, handlerMethod, templatesById) {
    RegisterHandlers(Self, LineHandlers, idProperty, handlerMethod, templatesById);
}  //$end

Version     "2.0.2"
PluginName  "Sibelius to MEI Exporter (CMO Version)"
Author      "Andrew Hankinson, Anna Plaksin"

_InitialProgressTitle "Exporting %s to MEI"
_ExportFileIsNull "You must specify a file to save."
_ScoreError "Please open a score and try again."
_ExportSuccess "The file was exported successfully."
_ExportFailure "The file was not exported because of an error."
_VersionNotSupported "Versions earlier than Sibelius 7 are not supported."
_ExportingBars "Exporting to MEI: Bar %s of %s"

_ObjectAssignedToAllVoicesWarning "Bar %s, voice %s. %s assigned to all voices will be encoded on voice 1. If this is incorrect, you should explicitly assign this object to a voice."
_ObjectHasNoMEISupport "%s is not supported by MEI at this time."
_ObjectIsOnAnIllogicalObject "Bar %s, voice %s. %s is added to a %s object. This will create invalid MEI. You should fix this in your Sibelius file if possible, or edit your MEI file after export."

LOGFILE "/tmp/sibelius.log"

_SegnoSymbols "Segno 1;Segno 2;Segno 3;Segno 4;Segno 5;Hash 1; Hash 2; Hash 3; Hash 4; Hash 5;Looped hash 1;Looped hash 2;Looped hash 3;Loop segno;X;X with 4 dots;Circle with dot;Arrow down;Cross 1;Cross 2;Cross 3;Cross 4;Asterisk 1;Asterisk 2;Asterisk 3;Circle with diagonal line 1;Circle with diagonal line 2;Circle with diagonal line, ‘2’ above;Circle with 2 diagonal lines;Circle with 2 diagonal lines 2"
_userTextStyleNames "Section,Subsection,Grgnum;Mükerrer;Editor initials;Performance instruction;Usûl name;Source;CMO Ref;Makâm;Usûl;Genre;Darb"
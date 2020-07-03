Version     "4.0.0"
PluginName  "Sibelius to MEI 4 Exporter"
Author      "Andrew Hankinson"
ExtensionAPIVersion "1.0.0"

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
_ObjectCouldNotFindAttachment "Bar %s, voice %s. %s could not be attached to a Note object, so it will not appear in the output."

LOGFILE "sibelius.log"

AvailableExtensions
SelectedExtensions

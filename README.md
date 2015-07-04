Sibmei
======

A Sibelius plugin for writing and reading MEI files in Sibelius.


Installation
------------

To install this plugin, copy or symlink the `.plg` files into the appropriate Sibelius plugin directory on your machine. The specific location [depends on your OS and version of Sibelius](http://www.sibelius.com/download/plugins/index.html?help=install).


Usage
------------

Under the “Home” tab of the Sibelius ribbon, select the “Plug-ins” button at the far right. sibmei’s plugins are labelled and grouped together. “Export file to MEI” and “Export folder to MEI” are the two functions intended for general use; the latter is useful for exporting many files at once, and may take a while to complete running if there are many files in your folder.

Known Issues
-------------
Sibelius allows lyrics to be assigned to both chords and rests, which MEI will mark as invalid markup. When it encounters these objects the Sibelius MEI Plugin will translate the lyrics to the chord or rest object, but will also display a warning.

For SymbolItems assigned to all voices (e.g., a non-line based Trill symbol), the plugin will assume that the symbol is assigned to voice 1. If this is incorrect, you should explicitly assign a symbol to a specific voice by right-clicking on the symbol and explicitly choosing the voice to which the symbol should be attached.

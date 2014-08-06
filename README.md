Sibmei
======

A Sibelius plugin for writing and reading MEI files in Sibelius.


Installation
------------

To install this plugin, copy or symlink the `.plg` files into the appropriate Sibelius plugin directory on your machine. The specific location [depends on your OS and version of Sibelius](http://www.sibelius.com/download/plugins/index.html?help=install).


Usage
------------

Under the “Home” tab of the Sibelius ribbon, select the “Plug-ins” button at the far right. sibmei’s plugins are labelled and grouped together. “Export file to MEI” and “Export folder to MEI” are the two functions intended for general use; the latter is useful for exporting many files at once, and may take a while to complete running if there are many files in your folder.


Limitations
------------

Due to the restrictions of Sibelius plugins, post-processing may be required. [libmei](https://github.com/DDMAL/libmei) provides support for writing straight-forward Python scripts to edit MEI files.

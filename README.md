# Sibelius to MEI Plugin

This plugin allows Sibelius to export to the Music Encoding Initiative (MEI) format.

## Download and Installation

The latest release of the plugin can be found on the GitHub releases page: https://github.com/music-encoding/sibmei/releases

To install this plugin, copy or symlink the `.plg` files in the Sibelius Plugin directory on your machine. The specific location [depends on your OS and version of Sibelius](http://www.sibelius.com/download/plugins/index.html?help=install).

## Developing and Contributing

The Sibelius to MEI exporter uses the fantastic [plgToMSS](https://github.com/tido/plgToMSS) tool developed by the Tido team. To contribute to development, you should first install this tool following [their instructions](https://github.com/tido/plgToMSS/blob/master/README.md).

Once installed, you should get the source code for the Sibelius to MEI plugin. This uses the `gulp` tool to automatically watch the source files for changes, builds and installs the plugin in the Sibelius plugin directory. So, to get set up for development you should install Node.js and the Node Package Manager (npm), and then run the following commands:

```
$> npm install -g gulp  // (installs the gulp command globally)
$> cd sibmei            // cd into the sibmei source directory
$> npm install          // installs the packages listed in the sibmei package.json directory
```

You need to create a symbolic link from the Sibelius plugin folder to the build folder in the sibmei directory. The paths are system dependent.

Example for Mac:

````
$> ln -s "~/path/to/sibmei/build/MEI Export" "~/Library/Application Support/Avid/Sibelius 7.5/Plugins/MEI Export"
````

Example for Windows (run as administrator):

````
> mklink /D "%APPDATA%\Avid\Sibelius\Plugins\MEI Export" "%HOMEPATH%\path\to\sibmei\build\MEI Export"
````

Then, to start developing the plugin, you should run `gulp develop`. This will watch the folder for changes, build, and deploy the plugin. **To make your changes active, you will need to "unload" and "reload" the plugin in Sibelius.**

## Unit tests

There are two kinds of tests in two subfolders of the `test` folder:

### sib-test

These unit tests are primarily used to test specific Sibmei functions.  They use the [sib-test](https://github.com/tido/sib-test) plugin, also developed by Tido. You should download and install this plugin first. After unloading and reloading the Testsibmei plugin (as described above), tests can be run by either

* starting Testsibmei from the plugin editing window or
* starting "Sibmei Test Runner" from the menu/ribbon.

### mocha

[Mocha](https://mochajs.org/) is used to test Sibmei's output from a set of test files.  After exporting the test file set with sibmei (Testsibmei will automatically do that), run `npm test` from the root directory of this git repository.

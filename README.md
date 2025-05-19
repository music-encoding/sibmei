# Sibelius to MEI Plugin

This plugin allows Sibelius to export to the Music Encoding Initiative (MEI) format.

## Download and Installation

The latest release of the plugin can be found on the GitHub releases page: https://github.com/music-encoding/sibmei/releases

To install this plugin, copy or symlink the `.plg` files in the Sibelius Plugin directory on your machine. The specific location [depends on your OS and version of Sibelius](http://www.sibelius.com/download/plugins/index.html?help=install).

If you're only interested in running the plugin in Sibelius, this is all you need to do.

## Developing and Contributing

### Install

For working on Sibmei, you need to have [git](https://git-scm.com/downloads) and [node](https://nodejs.org/en/download) installed. Then, on the command line, run:

```shell
git clone git@github.com:music-encoding/sibmei.git
cd sibmei
npm install
```

### Linking the plugin during development

You need to create a symbolic link from the Sibelius plugin folder to the build folder in the sibmei directory. The paths are system dependent.

Example for Mac:

```bash
ln -s "~/path/to/sibmei/build/develop" "~/Library/Application Support/Avid/Sibelius 7.5/Plugins/MEI Export"
```

Example for Windows (run as administrator):

```batch
mklink /D "%APPDATA%\Avid\Sibelius\Plugins\MEI Export" "%HOMEPATH%\path\to\sibmei\build\develop"
```

### Building the plugin

To start the compiler, run:

```shell
npm run develop
```

This will build the plugin and and watch your source files for changes, re-building the plugin as you edit and save.

**To make your changes to the Manuscript code active, you will need to "unload" and "reload" the plugin in Sibelius.** (File => Plug-ins => Edit Plug-ins, then Select the Sibmei plugin, then click Unload, then click Reload).

## Unit tests

There are two kinds of tests in two subfolders of the `test` folder:

### sib-test

These unit tests are primarily used to test specific Sibmei functions. They use the [sib-test](https://github.com/tido/sib-test) plugin, developed by Tido. You should download and install this plugin first. After unloading and reloading Sibmei, (as described above), tests can be run by starting the "Sibmei Test Runner" from the menu/ribbon, or using a keyboard shortcut of your choice that can be assigned in File => Preferences => Keyboard Shortcuts (in "Tab or category" choose Plug-ins, then in "Feature" choose  the Sibmei Test Runner and assign a shortcut).

### mocha

[Mocha](https://mochajs.org/) is used to test Sibmei's output from a set of test files. After exporting the test file set with sibmei (the Sibmei Test Runner will automatically do that), either run `npm test` from the root directory of this git repository or have the Test Runner automatically trigger the tests. The latter requires a `test.bat` or `test.sh` file in the same directory as the Sibmei `*.plg` files, depending on the operating system. Create a file that looks like this:

#### Windows: test.bat

```batch
x:
cd x:\path\to\sibmei
cmd /k npm test
```

#### Mac: test.sh

Help for testing and documenting for Mac welcome!

## Writing Extensions

For project specific handling of text and symbols, [extension plugins](Extensions.md) can be written.
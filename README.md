# Sibelius to MEI Plugin

This plugin allows Sibelius to export to the Music Encoding Initiative (MEI) format.

## Download and Installation

The latest release of the plugin can be found on the GitHub releases page: https://github.com/music-encoding/sibmei/releases

To install this plugin, copy or symlink the `.plg` files in the Sibelius Plugin directory on your machine. The specific location [depends on your OS and version of Sibelius](http://www.sibelius.com/download/plugins/index.html?help=install).

If you're only interested in running the plugin in Sibelius, this is all you need to do.

## Developing and Contributing

These are the instructions for installing the development dependencies and developing the plugin.

**Note that as of 2023, the dependencies are very fragile since some of the packages are outdated. This makes installation a bit of a pain.**

There are two ways around the painful dependency installation: The first is to try and struggle with npm and all the dependencies to see if you can get them to work. I couldn't, but maybe you can.

The second is to use the alternate JavaScript package manager, `yarn`, since it seems to be much better at managing dependencies and get them to run.

Both sets of instructions are provided here, but instructions on how to install `npm` or `yarn` are not provided. You should choose one or the other, not both!

Note that this only affects the process for building the plugin; You should still follow the instructions below for running the unit tests.

### Building using the Yarn method

Yarn provides a few niceities for running scripts from the directory without installing things globally. All of the dependencies are included in the `package.json` file, including the Tido `plgToMSS` utility and `gulp`, so once you have yarn installed you should be able to run (in the source directory):

```
$> yarn install
```

Once this finishes you can test the installation by running:

```
$> yarn run gulp develop
```

This will run a file watcher and as you edit the .mss files it should re-build the plugin for you.

### Building using the NPM method

Previous versions of the plugin had you install packages externally, but in this version you can install everything locally within the development directory, including the Tido plgToMSS code (installed from GitHub) and gulp.

```
$> npm install          // installs the packages listed in the sibmei package.json directory
```

If you have `npx` installed you should now be able to run:

```
$> npx gulp develop
```

And it will load a file watcher, watch your source files for changes, and re-build the plugin as you edit and save.

### Linking the plugin during development

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

[Mocha](https://mochajs.org/) is used to test Sibmei's output from a set of test files.  After exporting the test file set with sibmei (Testsibmei will automatically do that), either run `npm test` from the root directory of this git repository or have Testsibmei automatically trigger the tests.  The latter requires a `test.bat` or `test.sh` file in the same directory as the Sibmei `*.plg` files, depending on the operating system. Create a file that looks like this:

#### Windows: test.bat

```
x:
cd x:\path\to\sibmei
cmd /k npm test
```

#### Mac: test.sh

Help for testing and documenting for Mac welcome!

## Writing Extensions

For project specific handling of text and symbols, [extension plugins](Extensions.md) can be written.
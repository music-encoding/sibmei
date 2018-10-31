var config = {
  // As Sibelius's plugin folder path depends on the OS, Sibelius version and
  // possibly other factors, we just compile everything to ./build. A developer
  // must create a symbolic link to the build folder from the Sibelius plugin
  // folder.
  plgPath:        './build',
  plgCategory:    'MEI Export',
  pluginFilename: 'sibmei2.plg',
  linkLibraries: [
    'libmei.plg', 'sibmei_batch_mxml.plg', 'sibmei_batch_sib.plg', 'sibmei_test_runner.plg',
    'sibmeiTestSibs'
  ],
  importDir:      './import',
  buildDir:       './build',
  srcDir:         './src',
  testDir:        './test/sib-test',
  libDir:         './lib',
};

module.exports = config;

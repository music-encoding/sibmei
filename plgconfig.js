var config = {
  // As Sibelius's plugin folder path depends on the OS, Sibelius version and
  // possibly other factors, we just compile everything to ./build. A developer
  // must create a symbolic link to the build folder from the Sibelius plugin
  // folder.
  plgPath:        './build',
  plgCategory:    'MEI Export',
  pluginFilename: 'sibmei4.plg',
  linkLibraries: [
    'libmei4.plg', 'sibmei4_batch_mxml.plg', 'sibmei4_batch_sib.plg', 'sibmei4_test_runner.plg', 'sibmei4_extension_test.plg'
  ],
  importDir:      './import',
  buildDir:       './build',
  srcDir:         './src',
  testDir:        './test/sib-test',
  libDir:         './lib',
};

module.exports = config;

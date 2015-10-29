var config = {
  plgPath:         process.env.HOME + '/Library/Application Support/Avid/Sibelius 7.5/Plugins',
  plgCategory:    'MEI Export',
  pluginFilename: 'sibmei2.plg',
  linkLibraries: ['libmei.plg', 'sibmei_batch_mxml.plg', 'sibmei_batch_sib.plg'],
  importDir:      './import',
  buildDir:       './build',
  srcDir:         './src',
  testDir:        './test',
  libDir:         './lib',
};

module.exports = config;


var config = {
  plgPath:        process.env.USERPROFILE + '\\AppData\\Roaming\\Avid\\Sibelius\\Plugins',
  plgCategory:    'CMO MEI Export',
  pluginFilename: 'sibmei2.plg',
  linkLibraries: ['libmei.plg', 'sibmei_batch_mxml.plg', 'sibmei_batch_sib.plg'],
  importDir:      '\.\\import',
  buildDir:       '\.\\build',
  srcDir:         '\.\\src',
  //testDir:        '.\\test',
  libDir:         '\.\\lib',
};

module.exports = config;


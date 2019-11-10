/* jshint node:true */
'use strict'

var gulp = require('gulp');
var child = require('child_process');
var c = require('ansi-colors');
var l = require('fancy-log');
var Q = require('q');
var plgconf = require('./plgconfig');

function build()
{
    var deferred = Q.defer();
    l.info(c.blue('Copying "linked" libraries'));
    gulp.src('lib/*.plg')
        .pipe(gulp.dest('build/'));

    var build = child.exec('buildPlg', function(err, stdout, stderr)
    {
        if (err)
        {
            l.error(c.red("Build failed with error code: " + err.code));
        }
        l.info(c.blue('Output: ') + '\n' + stdout);
    });

    var buildTest = child.exec('buildPlg test', function(err, stdout, stderr)
    {
        if (err)
        {
            l.error(c.red("Test Build failed with error code: " + err.code));
        }
        l.info(c.blue('Output: ') + '\n' + stdout);
        deferred.resolve();
    });

    l.info(c.blue('Copying test data'));
    const destPath = plgconf.plgPath + '/' + plgconf.plgCategory + '/sibmeiTestSibs';
    gulp.src('test/sibmeiTestSibs/*.sib', {base: 'test/sibmeiTestSibs'})
        .pipe(gulp.dest(destPath));

    return deferred.promise;
};

function deploy (cb)
{
    var deploy = child.exec('deployPlg', function(err, stdout, stderr)
    {
        if (err)
        {
            l.error(c.red("Deploy failed with error code: " + err.code));
        }
        l.info(c.blue('Output: ') + '\n' + stdout);
    });
    cb();
};

function develop() {
  gulp.watch(['src/**/*', 'test/**/*', 'lib/**/*.plg'], gulp.series(build, deploy))
}

exports.develop = develop;
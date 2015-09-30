/* jshint node:true */
'use strict'

var gulp = require('gulp');
var child = require('child_process');
var gutil = require('gulp-util');
var Q = require('q');

gulp.task('develop:build', function(callback)
{
    var deferred = Q.defer();
    gutil.log(gutil.colors.blue('Copying "linked" libraries'));
    gulp.src('lib/*.plg')
        .pipe(gulp.dest('build/'));

    var build = child.exec('buildPlg', function(err, stdout, stderr)
    {
        if (err)
        {
            gutil.log(gutil.colors.red("Build failed with error code: " + err.code));
        }
        gutil.log(gutil.colors.blue('Output: ') + '\n' + stdout);
    });

    var buildTest = child.exec('buildPlg test', function(err, stdout, stderr)
    {
        if (err)
        {
            gutil.log(gutil.colors.red("Test Build failed with error code: " + err.code));
        }
        gutil.log(gutil.colors.blue('Output: ') + '\n' + stdout);
        deferred.resolve();
    });
    
    return deferred.promise;
});

gulp.task('develop:deploy', ['develop:build'], function()
{
    var deploy = child.exec('deployPlg', function(err, stdout, stderr)
    {
        if (err)
        {
            gutil.log(gutil.colors.red("Deploy failed with error code: " + err.code));
        }
        gutil.log(gutil.colors.blue('Output: ') + '\n' + stdout);
    });
});

gulp.task('develop', function()
{
    gulp.watch(['src/**/*', 'test/**/*', 'lib/**/*.plg'], ['develop:build', 'develop:deploy'])
});

gulp.task('default', function()
{
    gulp.start('develop')
});
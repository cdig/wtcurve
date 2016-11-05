browser_sync = require("browser-sync").create()
del = require "del"
gulp = require "gulp"
gulp_autoprefixer = require "gulp-autoprefixer"
gulp_coffee = require "gulp-coffee"
gulp_notify = require "gulp-notify"
gulp_sass = require "gulp-sass"
gulp_uglify = require "gulp-uglify"

gulp_notify.logLevel(0)

logAndKillError = (err)->
  console.log "\n## Error ##"
  console.log err.toString() + "\n"
  gulp_notify.onError(
    emitError: true
    icon: false
    message: err.message
    title: "👻"
    wait: true
    )(err)
  @emit "end"

gulp.task "coffee", ()->
  gulp.src "public/script.coffee"
    .pipe gulp_coffee()
    .pipe gulp_uglify()
    .on "error", logAndKillError
    .pipe gulp.dest "public"
    .pipe browser_sync.stream
      match: "**/*.js"

gulp.task "scss", ()->
  gulp.src "public/style.scss"
    .pipe gulp_sass
      errLogToConsole: true
      outputStyle: "compressed"
      precision: 1
    .on "error", logAndKillError
    .pipe gulp_autoprefixer
      browsers: "last 5 Chrome versions, last 5 ff versions, IE >= 11, Safari >= 9, iOS >= 9"
      cascade: false
      remove: false
    .pipe gulp.dest "public"
    .pipe browser_sync.stream
      match: "**/*.css"

gulp.task "serve", ()->
  browser_sync.init
    ghostMode: false
    online: true
    server:
      baseDir: "public"
    ui: false

gulp.task "watch", (cb)->
  gulp.watch "public/script.coffee", gulp.series "coffee"
  gulp.watch "public/style.scss", gulp.series "scss"
  cb()

gulp.task "default", gulp.parallel "coffee", "scss", "serve", "watch"

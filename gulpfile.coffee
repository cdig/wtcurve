browser_sync = require("browser-sync").create()
gulp = require "gulp"
gulp_coffee = require "gulp-coffee"

gulp.task "coffee", ()->
  gulp.src "public/script.coffee"
    .pipe gulp_coffee()
    .pipe gulp.dest "public"
    .pipe browser_sync.stream
      match: "**/*.js"

gulp.task "serve", ()->
  browser_sync.init
    ghostMode: false
    online: true
    server:
      baseDir: "public"
    ui: false

gulp.task "watch", (cb)->
  gulp.watch "public/script.coffee", gulp.series "coffee"
  cb()

gulp.task "default", gulp.parallel "coffee", "serve", "watch"

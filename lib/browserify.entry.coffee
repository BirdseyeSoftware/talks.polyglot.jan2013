Underscore = require "underscore"
jQuery = require "jquery"
Rx = require "rx"

if window?
  window.Rx = Rx
  window._ = Underscore
  window.$ = window.jQuery = jQuery
  require "../assets/jquery.macaroon"
  require "rxjs-jquery"
  window.app = app = require "./app"
  app.core = require("./app.core")
  app.main()

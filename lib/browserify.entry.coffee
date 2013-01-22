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
  app.net = require("./app.net")
  app.log = require("./utils").log
  app.faye = require("./app.net").fayeClient
  app.main()

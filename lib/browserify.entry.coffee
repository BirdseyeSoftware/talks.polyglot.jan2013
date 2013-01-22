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
  app.ns =
    utils: require('./utils')
    core: require("./app.core")
    streams: require("./app.streams")
    ui: require("./app.ui")
    net: require("./app.net")
    auth: require("./app.auth")
    log: require("./utils").log
    faye: require("./app.net").fayeClient
  app.main()

Underscore = require "underscore"
jQuery = require "jquery"
Rx = require "rx"

if window?
  window.Rx = Rx
  window._ = Underscore
  window.$ = window.jQuery = jQuery

require "rxjs-jquery"
require "./rx_ui"

# $(->
#   console.log("Hello guys!"))

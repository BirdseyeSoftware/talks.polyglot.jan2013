Underscore = require "underscore"
jQuery = require "jquery"
Rx = require "rx"


if window?
  window.Rx = Rx
  window._ = Underscore
  window.$ = window.jQuery = jQuery

require "rxjs-jquery"

if window?
  #window.rx_ui = require "./rx_ui"
  slides_main = require "./slides_main"
  slides_main.main()


# $(->
#   console.log("Hello guys!"))

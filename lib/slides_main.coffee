rx_ui = require "./rx_ui"
slides_view = require "./slides_view"
slides_network = require "./slides_network"

initEvents = ->
  Reveal.removeEventListeners()
  localEvents = rx_ui.uiSlideEventstream()
  localEvents.subscribe(rx_ui.handleLocalSlideEvent)
  localEvents.subscribe(slides_network.publishSlideEvent)

  remoteSlideStream = slides_network.slideEventsObservable("/slides")
  remoteSlideStream.subscribe(rx_ui.handleRemoteSlideEvent)

main = ->
  $ ->
    slides_view.init()
    $("body").bind("touchstart", (ev) -> ev.preventDefault())
    setTimeout(initEvents, 340)

exports.main = main

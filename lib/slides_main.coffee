rx_ui = require "./rx_ui"
auth = require "./slides_auth"
view = require "./slides_view"
net = require "./slides_network"

initEvents = ->
  Reveal.removeEventListeners()
  localEvents = rx_ui.uiSlideEventstream()
  localEvents.subscribe(rx_ui.handleLocalSlideEvent)
  localEvents.subscribe(net.publishSlideEvent)

  remoteSlideStream = net.slideEventsObservable("/slides")
  remoteSlideStream.subscribe(rx_ui.handleRemoteSlideEvent)

main = ->
  $ ->
    auth.getCurrentUser()
    view.init()
    $("body").bind("touchstart", (ev) -> ev.preventDefault())
    setTimeout(initEvents, 340)

exports.main = main

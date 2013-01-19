rx_ui = require "./rx_ui"
slides_view = require "./slides_view"
slides_network = require "./slides_network"

main = ->
  $(->
    slides_view.init()
    $("body").bind("touchstart", (ev) -> ev.preventDefault())

    localSlideStream = rx_ui.slideEventsObservable("body")
    localSlideStream.subscribe(rx_ui.handleSlideEvent)
    localSlideStream.subscribe(slides_network.publishSlideEvent)

    remoteSlideStream = slides_network.slideEventsObservable("/slides")
    remoteSlideStream.subscribe(rx_ui.handleRemoteSlideEvent)

    )

exports.main = main

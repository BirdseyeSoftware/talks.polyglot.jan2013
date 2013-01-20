core = require "./app.core"
auth = require "./app.auth"
view = require "./app.init"
net = require "./app.net"
streams = require "./app.streams"

initEvents = ->
  Reveal.removeEventListeners()
  localEvents = core.uiSlideEventstream()
  localEvents.subscribe(core.handleLocalSlideEvent)
  localEvents.subscribe(net.publishSlideEvent)

  streams.remoteSlideEventstream.subscribe(core.handleRemoteSlideEvent)

  streams.log.subscribe(([msg, data]) ->
    console.log(msg, data...)
    net.log(msg, data))

main = ->
  $ ->
    auth.getCurrentUser()
    view.init()
    $("body").bind("touchstart", (ev) -> ev.preventDefault())
    setTimeout(initEvents, 340)

exports.main = main

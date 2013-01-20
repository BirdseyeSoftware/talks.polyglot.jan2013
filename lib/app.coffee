core = require "./app.core"
auth = require "./app.auth"
view = require "./app.init"
net = require "./app.net"

initEvents = ->
  Reveal.removeEventListeners()
  localEvents = core.uiSlideEventstream()
  localEvents.subscribe(core.handleLocalSlideEvent)
  localEvents.subscribe(net.publishSlideEvent)

  remoteSlideStream = net.remoteSlideEventstream()
  remoteSlideStream.subscribe(core.handleRemoteSlideEvent)

main = ->
  $ ->
    auth.getCurrentUser()
    view.init()
    $("body").bind("touchstart", (ev) -> ev.preventDefault())
    setTimeout(initEvents, 340)

exports.main = main

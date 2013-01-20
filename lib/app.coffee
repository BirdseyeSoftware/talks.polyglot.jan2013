core = require "./app.core"
auth = require "./app.auth"
view = require "./app.init"
net = require "./app.net"
streams = require "./app.streams"
utils = require "./utils"

initEvents = ->
  localEvents = core.uiSlideEventstream()
  utils.teeSubscribe(localEvents,
    core.handleLocalSlideEvent,
    net.publishSlideEvent)

  streams.remoteSlideEventstream.subscribe(core.handleRemoteSlideEvent)

  streams.log.subscribe(([msg, data]) -> console.log(msg, data...))
  streams.log.subscribe(net.log)

main = ->
  $ ->
    auth.getCurrentUser()
    view.init()
    setTimeout(initEvents, 340)

exports.main = main

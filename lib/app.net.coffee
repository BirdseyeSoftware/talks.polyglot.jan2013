streams = require "./app.streams"
channelNames = require "./channel_names"
utils = require "./utils"
auth = require "./app.auth"

exports.fayeClient = fayeClient = new Faye.Client("/faye")

exports.isMe = isMe = (clientId) -> fayeClient.getClientId() == clientId

initRemoteSlideEventstream = () ->
  fayeClient.subscribe channelNames.slideEvents, ([cid, ev])->
    if not isMe(cid)
      streams.remoteSlideStateChangeStream.onNext(ev)

initRemoteSlideEventstream()

exports.publishSlideEvent = (slideEvent) ->
  slideEvent.user = auth.getCurrentUser()
  fayeClient.publish(channelNames.slideEvents,
    [fayeClient.getClientId(), slideEvent])

exports.log = (msg) ->
  fayeClient.publish('/debug',
    [fayeClient.getClientId(), msg, navigator.userAgent])

exports.listenToRemoteDebug = (subscribers...) ->
  fayeClient.subscribe channelNames.debugEvents, ([cid, ev])->
    if not isMe(cid)
      streams.remoteDebugEventstream.onNext(ev)

  if subscribers
    utils.teeSubscribe(streams.remoteDebugEventstream, subscribers...)

streams = require "./app.streams"
channelNames = require "./channel_names"

fayeClient = new Faye.Client("/faye")
exports.isMe = isMe = (clientId) -> fayeClient.getClientId() == clientId

initRemoteSlideEventstream = () ->
  fayeClient.subscribe channelNames.slideEvents, ([cid, ev])->
    if not isMe(cid)
      streams.remoteSlideEventstream.onNext(ev)

initRemoteSlideEventstream()

exports.publishSlideEvent = (slideEvent) ->
  fayeClient.publish(channelNames.slideEvents,
    [fayeClient.getClientId(), slideEvent])

exports.log = (msg) ->
  fayeClient.publish('/debug',
    [fayeClient.getClientId(), msg, navigator.userAgent])

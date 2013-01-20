Rx = require "rx"

streams = require "./app.streams"

fayeClient = new Faye.Client("/faye")
exports.isMe = isMe = (clientId) -> fayeClient.getClientId() == clientId

# fayeChannelEventstream = (channel) ->
#   subj = new Rx.Subject()
#   subj.callback = (params) -> subj.onNext(params)
#   fayeClient.subscribe(channel, subj.callback)
#   subj

REMOTE_SLIDEEVENT_CHANNEL = '/slides'

# _initRemoteSlideEventstream = () ->
#   fayeChannelEventstream(REMOTE_SLIDEEVENT_CHANNEL).
#     where(([cid, ev]) -> not isMe(cid)).
#     select(([cid, ev]) -> ev).
#     subscribe(streams.remoteSlideEventstream.onNext)

initRemoteSlideEventstream = () ->
  fayeClient.subscribe REMOTE_SLIDEEVENT_CHANNEL, ([cid, ev])->
    if not isMe(cid)
      streams.remoteSlideEventstream.onNext(ev)

initRemoteSlideEventstream()

## pub functions ############################################

exports.publishSlideEvent = (slideEvent) ->
  fayeClient.publish("/slides", [fayeClient.getClientId(), slideEvent])


exports.log = (msg, data) ->
  fayeClient.publish('/debug',
    [fayeClient.getClientId(), msg, data, navigator.userAgent])

# exports.publish = (channel, data) ->
#   fayeClient.publish(channel, data)

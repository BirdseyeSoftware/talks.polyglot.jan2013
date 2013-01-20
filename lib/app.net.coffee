Rx = require "rx"

client = new Faye.Client("/faye")
exports.isMe = isMe = (clientId) -> client.getClientId() == clientId

## Rx Observables ####################################################

fayeChannelEventstream = (channel) ->
  subj = new Rx.Subject()
  subj.callback = (params) -> subj.onNext(params)
  client.subscribe(channel, subj.callback)
  subj

REMOTE_SLIDEEVENT_CHANNEL = '/slides'
exports.remoteSlideEventstream = () ->
  fayeChannelEventstream(REMOTE_SLIDEEVENT_CHANNEL).
    where(([cid, ev]) -> not isMe(cid)).
    select(([cid, ev]) -> ev)

## pub functions ############################################

exports.publishSlideEvent = (slideEvent) ->
  client.publish("/slides", [client.getClientId(), slideEvent])


exports.log = (msg, data) ->
  client.publish('/debug',
    [client.getClientId(), msg, data, navigator.userAgent])

# exports.publish = (channel, data) ->
#   client.publish(channel, data)

Rx = require "rx"
slides_view = require "./slides_view"

client = new Faye.Client("/faye")
exports.isMe = isMe = (clientId) -> client.getClientId == clientId

## Rx Observables ####################################################

exports.fayeSubAsObservable = fayeAsObservable = (channel) ->
  subj = new Rx.Subject()
  subj.callback = (params) -> subj.onNext(params)
  client.subscribe(channel, subj.callback)
  subj

exports.slideEventsObservable = (channel) ->
  exports.
    fayeSubAsObservable(channel).
    where(([cid, ev]) -> not isMe(cid)).
    select(([cid, ev]) -> ev)

## Subscription functions ############################################

exports.publishSlideEvent = (slideEvent) ->
  client.publish("/slides", [client.getClientId(), slideEvent])


# exports.client = client

Rx = require "rx"
Faye = require "faye"

faye = new Faye.NodeAdapter(mount: "/faye", timeout: 45)
exports.publish = (args...) -> faye.getClient().publish(args...)
exports.subscribe = (args...) -> faye.getClient().subscribe(args...)
exports.attach = (args...) -> faye.attach(args...)

faye.asObservable = (event_type) ->
  subj = new Rx.Subject()
  subj.callback = (params...) -> subj.onNext(params)
  faye.bind(event_type, subj.callback)
  subj

faye.bind('subscribe', ([clientId, channel]) ->
  console.log("FAYE subscribe", clientId, channel))

faye.bind('handshake', (clientId) ->
  console.log("FAYE handshake", clientId))

faye.bind('disconnect', ([clientId, channel]) ->
  console.log("FAYE disconnect", clientId, channel))

faye.bind('unsubscribe', ([clientId, channel]) ->
  console.log("FAYE unsubscribe", clientId, channel))

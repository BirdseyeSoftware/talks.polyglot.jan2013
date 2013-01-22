Rx = require "rx"
Faye = require "faye"

{server} = require "./server.core"

faye = new Faye.NodeAdapter(mount: "/faye", timeout: 45)
exports.publish = (args...) -> faye.getClient().publish(args...)
exports.subscribe = (args...) -> faye.getClient().subscribe(args...)
exports.attach = (args...) -> faye.attach(args...)

faye.asObservable = (event_type) ->
  subj = new Rx.Subject()
  subj.callback = (params...) -> subj.onNext(params)
  faye.bind(event_type, subj.callback)
  subj

# faye.asObservable('publish').subscribe(
#   ([clientId, channel]) ->
#     console.log("publish", clientId, channel))

faye.asObservable('subscribe').subscribe(
  ([clientId, channel]) ->
    console.log("subscribe", clientId, channel))

faye.asObservable('handshake').subscribe(
  (clientId) ->
    console.log("handshake", clientId))

faye.asObservable('disconnect').subscribe(
  ([clientId, channel]) ->
    console.log("disconnect", clientId, channel))

faye.asObservable('unsubscribe').subscribe(
  ([clientId, channel]) ->
    console.log("unsubscribe", clientId, channel))

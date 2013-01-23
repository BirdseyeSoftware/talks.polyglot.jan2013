Rx = require "rx"
Faye = require "faye"
config = require "./server.config"

faye = new Faye.NodeAdapter(mount: "/faye", timeout: 45)
exports.publish = publish = (args...) -> faye.getClient().publish(args...)
exports.subscribe =  subscribe = (args...) -> faye.getClient().subscribe(args...)
exports.attach = (args...) -> faye.attach(args...)

faye.asObservable = (event_type) ->
  subj = new Rx.Subject()
  subj.callback = (params...) -> subj.onNext(params)
  faye.bind(event_type, subj.callback)
  subj

faye.bind('subscribe', (clientId, channel) ->
  console.log("FAYE subscribe", clientId, channel))

faye.bind('handshake', (clientId) ->
  console.log("FAYE handshake", clientId))

faye.bind('disconnect', (clientId, channel) ->
  console.log("FAYE disconnect", clientId, channel))

faye.bind('unsubscribe', (clientId, channel) ->
  console.log("FAYE unsubscribe", clientId, channel))

subscribe('/url_submit', ({url, user}) ->
  console.log("url_submit:", user, url)
  if user.id == config.PRESENTER_USER.id
    publish('/url', url))

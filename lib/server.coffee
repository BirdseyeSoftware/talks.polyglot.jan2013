express = require "express"
Faye = require "faye"
Rx = require "rx"

faye = new Faye.NodeAdapter(mount: "/faye", timeout: 45)
server = express()

faye.asObservable = (event_type) ->
  subj = new Rx.Subject()
  subj.callback = (params...) -> subj.onNext(params)
  faye.bind(event_type, subj.callback)
  subj

faye.asObservable('publish').subscribe(
  ([clientId, channel, data]) ->
    console.log("publish", clientId, channel, data)
    if data == 123
      faye.getClient().publish("/foo", 456))

faye.asObservable('subscribe').subscribe(
  ([clientId, channel]) ->
    console.log("subscribe", clientId, channel))

faye.asObservable('handshake').subscribe(
  (clientId) ->
    console.log("handshake", clientId))

server.configure(->
  server.use(express.static(__dirname + '/../assets'))
  server.use(express.static(__dirname + '/../build'))
  server.use(faye)
  console.log("express server ready"))

server.listen(8080)

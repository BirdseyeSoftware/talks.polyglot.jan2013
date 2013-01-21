Rx = require "rx"

net = require "./app.net"

exports.log = new Rx.Subject()
exports.remoteSlideEventstream = new Rx.Subject()
exports.localSlideEventstream = new Rx.Subject()
exports.localSlideStateChangeStream = new Rx.Subject()

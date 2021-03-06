Rx = require "rx"

# net = require "./app.net"

exports.log = new Rx.Subject()

# raw unprocessed events triggered by ui actions
exports.localSlideEventstream = new Rx.Subject()

# local event / state reductions {event, prevState, newState}
exports.localSlideStateChangeStream = new Rx.Subject()

# remote event / state reductions {event, prevState, newState} for one user
exports.remoteUserSlideStateChangeStream = new Rx.Subject()

# remote event / state reductions {event, prevState, newState} for all slaves
exports.remoteSlaveSlideStateChangeStream = new Rx.Subject()

# incoming remote debug events DO NOT REPUBLISH
exports.remoteDebugEventstream = new Rx.Subject()

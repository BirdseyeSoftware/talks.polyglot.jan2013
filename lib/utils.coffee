streams = require "./app.streams"

exports.tee = tee = (val, fns) ->
  for fn in fns
    fn(val)

exports.mktee = (fns...) ->
  (val) -> tee(val, fns)

exports.log = (msg, data...) ->
  streams.log.onNext([msg, data])

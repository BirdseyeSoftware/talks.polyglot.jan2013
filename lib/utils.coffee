_ = require "underscore"
streams = require "./app.streams"

exports.tee = tee = (val, fns) ->
  for fn in fns
    fn(val)

exports.mktee = (fns...) ->
  (val) -> tee(val, fns)

exports.log = (msg, data...) ->
  streams.log.onNext([msg, data])

exports.teeSubscribe = (observable, observers...) ->
  _.map(observers, ((sub) -> observable.subscribe(sub)))

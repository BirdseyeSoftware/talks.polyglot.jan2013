exports.tee = tee = (val, fns) ->
  for fn in fns
    fn(val)

exports.mktee = (fns...) ->
  (val) -> tee(val, fns)

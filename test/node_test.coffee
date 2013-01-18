buster = if window?.buster? then window.buster else require("buster")
rx = require("rx")
#_ = require("underscore")

ob = rx.Observable

buster.testCase "test streams",
  "return": ->
    stream = ob.returnValue("Hello World")
    stream.subscribe((str) ->
      buster.assert str == "Hello World")
    #
    null
  "range": ->
    stream = ob.range(0, 10)
    i = 0
    stream.subscribe((n) ->
      buster.assert i == n, "#{i},#{n}"
      i++)
    #
    null
  "concat": (done) ->
    stream = ob.concat(ob.range(0, 10), ob.range(10, 20))
    i = 0
    stream.subscribe(((n) ->
      buster.assert i == n, "#{i}, #{n}"
      i++),
      null,
      (-> done()))
    #
    null

  "aggregate": (done) ->
    ob.range(0, 4).aggregate((acc, n) -> acc + n).subscribe(
      (result) -> buster.assert.equals(6, result),
      null,
      -> done())
    #
    null

  "takeLast": (done) ->
    stream = ob.range(0, 4).takeLast(1)
    stream.subscribe(
      (result) -> buster.assert(3 == result, "#{result}"),
      null,
      -> done())
    #
    null


# buster.testCase "dummy",
#   "dummy test": ->
#     buster.assert(true, "hey see me pass")

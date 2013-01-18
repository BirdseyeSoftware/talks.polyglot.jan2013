Faye = require "faye"
client = new Faye.Client("http://test.dent.vm1:8080/faye")

class Foo
  constructor: (@v) ->
    @b = 123
client.publish('/foo', new Foo(999))

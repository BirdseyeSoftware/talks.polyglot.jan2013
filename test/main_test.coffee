buster = if window?.buster? then window.buster else require("buster")
#_ = require("underscore")

# buster.testCase "dummy",
#   "assert html slideshow is available test": ->
#     buster.assert(document.getElementById("sec-5-2"))
#     buster.assert(document.getElementById("sec-5-2").nodeName == "H3")
#     buster.assert(true, "hey see me fail")

{getUserKey} = require "./utils"

# one auth msg per user/login
exports.clientAuthenticated = '/authenticated'

# browser registration upon initial page load
exports.clientLoadedSlideshow = '/slideshow/loaded'

# presenter to command audience's slaved browsers: state changes, cmds, etc.
exports.slaveEvents = '/slideshow/slaves'

# for each browser (audience or presenter) to publish local SlideEvents
exports.slideEvents = '/slideshow/events'


# for general debugging from server to client, client to server, client to client
# ... whatever. Subscribers must not republish remote messages they receive!
exports.debugEvents = '/debug'

exports.getUserEventChannelName = (user) ->
  userKey = getUserKey(user, "/")
  "#/slideshow/events/#{userKey}"

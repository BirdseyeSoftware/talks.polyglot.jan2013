# one auth msg per user/login
exports.clientRegistration = '/authenticated'

# browser registration upon initial page load
exports.clientRegistration = '/register'

# presenter to command audience's slaved browsers: state changes, cmds, etc.
exports.slaves = '/slideshow/slaves'

# for each browser (audience or presenter) to publish local SlideEvents
exports.slideEvents = '/slideshow/events'

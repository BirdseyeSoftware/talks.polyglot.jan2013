core = require "./app.core"
ui = require "./app.ui"
auth = require "./app.auth"
view = require "./app.init"
net = require "./app.net"
streams = require "./app.streams"
utils = require "./utils"

################################################################################

EVENTS_TO_REVEAL_FNS =
  EnterFullscreen: Reveal.enterFullscreen
  TogglePause: Reveal.togglePause
  ToggleOverview: Reveal.toggleOverview
  Prev: Reveal.prev
  Next: Reveal.next
  Up:   Reveal.up
  Down: Reveal.down
  Right: Reveal.right
  Left: Reveal.left
  SelectSlide: (ev) ->
    Reveal.slide(ev.h, ev.v)
    Reveal.deactivateOverview()

handleRevealCommand = (slideEvent) ->
  EVENTS_TO_REVEAL_FNS[slideEvent.type]?(slideEvent)

handleRevealCommand = handleRevealCommand

handleRemoteSlideEvent = (slideEvent) ->
  console.log("remote", slideEvent)
  if slideEvent.type in core.movements
    {h, v} = slideEvent.revealIndices
    Reveal.slide(h, v)
  else
    handleRevealCommand(slideEvent)

handleLocalSlideEvent = (slideEvent) ->
  utils.log("local", slideEvent)
  handleRevealCommand(slideEvent)

appendRevealDetails = (ev) ->
  ev.revealIndices = Reveal.getIndices()
  ev

################################################################################

initEvents = ->
  ui.uiSlideEventstream().subscribe(streams.localSlideEventstream)
  utils.teeSubscribe(streams.localSlideEventstream,
    handleLocalSlideEvent,
    (ev) -> net.publishSlideEvent(appendRevealDetails(ev)))

  streams.remoteSlideEventstream.subscribe(handleRemoteSlideEvent)

  streams.log.subscribe(([msg, data]) -> console.log(msg, data...))
  streams.log.subscribe(net.log)

main = ->
  $ ->
    auth.getCurrentUser()
    view.init()
    setTimeout(initEvents, 340)

################################################################################
exports.main = main

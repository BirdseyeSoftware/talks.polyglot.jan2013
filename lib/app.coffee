core = require "./app.core"
{revealjsDomToSlideDeck} = require "./app.revealjs_to_slidedeck"
ui = require "./app.ui"
auth = require "./app.auth"
view = require "./app.init"
net = require "./app.net"
streams = require "./app.streams"
utils = require "./utils"

################################################################################
isFullscreenActive = () ->
  document.fullScreen or document.mozFullScreen or document.webkitIsFullScreen

cancelFullscreen = () ->
  document.exitFullscreen?()
  document.mozCancelFullScreen?()
  document.webkitCancelFullscreen?()

enterFullscreen = () ->
  Reveal.enterFullscreen()

updateRevealForPresentationState = (state) ->
  {h, v} = Reveal.getIndices()
  slide = state.slide
  if slide.h != h or slide.v != v
    Reveal.slide(slide.h, slide.v)

  if state.paused and not Reveal.isPaused()
    Reveal.togglePause()
  else if Reveal.isPaused() and not state.paused
    Reveal.togglePause()

  if state.mode == 'overview'
    Reveal.toggleOverview() if not Reveal.isOverviewActive()
  else
    Reveal.deactivateOverview() if Reveal.isOverviewActive()

  if state.fullscreen and not isFullscreenActive()
    enterFullscreen()
  else if not state.fullscreen and isFullscreenActive()
    cancelFullscreen()

################################################################################

toSlideObj = (slide) ->
  if slide.constructor is core.Slide
    slide
  else
    new core.Slide(slide.id, slide.h, slide.v, slide.offset)

logStateChange = (stateChange, msg='state change:') ->
  if not console?.exception?        #firebug detection
    return
  try
    console.log(msg)
    extraDetails =
      slideBefore: toSlideObj(stateChange.prevState.slide),
      slideAfter: toSlideObj(stateChange.newState.slide)
    console.dir(_.extend(extraDetails, stateChange))
  catch err
    console.error?(err)

window.mainSlideDeck = null

handleRemoteSlideEvent = (stateChange) ->
  logStateChange(stateChange, "remote state change:")
  updateRevealForPresentationState(stateChange.newState)

aggregateStateOnSlideEvent = (prevState, ev) ->
  try
    newState = core.slideEventReducer(prevState, ev)
    updateRevealForPresentationState(newState)
    streams.localSlideStateChangeStream.onNext(
      timestamp: new Date(),
      event: ev,
      prevState: prevState.serialize(),
      newState: newState.serialize())
    newState
  catch err
    net.log(err)
    console?.error?("exception in slide state reducer:",
      err,
      "after event:", ev,
      "previous state: ", prevState,
      "new state:", newState)
    prevState                   # leave it at the old state after erro

initEvents = ->
  window.mainSlideDeck = revealjsDomToSlideDeck()
  ui.uiSlideEventstream().subscribe(streams.localSlideEventstream)

  initState = new core.PresentationState(window.mainSlideDeck)
  streams.localSlideEventstream.aggregate(
    initState, aggregateStateOnSlideEvent).subscribe((finalState)->)

  streams.localSlideStateChangeStream.subscribe(logStateChange)
  streams.localSlideStateChangeStream.subscribe(net.publishSlideEvent)

  streams.remoteSlideEventstream.subscribe(handleRemoteSlideEvent)

  streams.log.subscribe(([msg, data]) -> console?.log?(msg, data...))
  streams.log.subscribe(net.log)

main = ->
  $ ->
    auth.getCurrentUser()
    view.init()
    setTimeout(initEvents, 640)

################################################################################
exports.main = main

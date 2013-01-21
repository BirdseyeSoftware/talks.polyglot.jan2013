core = require "./app.core"
{revealjsDomToSlideDeck} = require "./app.revealjs_to_slidedeck"
ui = require "./app.ui"
#auth = require "./app.auth"
view_bootstrap = require "./app.init"
net = require "./app.net"
streams = require "./app.streams"
utils = require "./utils"

CURRENT_LOCAL_SLIDE_STATE = null

################################################################################
toSlideObj = (slide) ->
  if slide.constructor is core.Slide
    slide
  else
    new core.Slide(slide.id, slide.h, slide.v, slide.offset)

hasFirebug = () ->
  console?.exception? and console.table?

logStateChange = (stateChange, msg='state change:') ->
  if not hasFirebug()
    return
  try
    console.log(msg)
    extraDetails =
      slideBefore: toSlideObj(stateChange.prevState.slide),
      slideAfter: toSlideObj(stateChange.newState.slide)
    console.dir(_.extend(extraDetails, stateChange))
  catch err
    console.error?(err)

logRemoteStateChange = (stateChange) ->
  logStateChange(stateChange, 'remote state change:')

MERGE_REMOTE_EVENT_STREAM = true
handleRemoteSlideEvent = (stateChange) ->
  if MERGE_REMOTE_EVENT_STREAM
    ev = stateChange.event
    ev.isRemote = true
    remoteIdx = _.pick(stateChange.prevState.slide, ['h', 'v'])
    localSlideIdx = _.pick(CURRENT_LOCAL_SLIDE_STATE.slide, ['h', 'v'])
    if remoteIdx != localSlideIdx
      syntheticSyncEvent = core.EVENTS.SelectSlide(remoteIdx.h, remoteIdx.v)
      syntheticSyncEvent.isRemote = true
      syntheticSyncEvent.isSynthetic = true
      streams.localSlideEventstream.onNext(syntheticSyncEvent)

    streams.localSlideEventstream.onNext(ev)
  else
    # This updates the view but doesn't currently affect the state machine / event history.
    # Thus, the next local event will resume from the previous local state.
    ui.updateRevealForPresentationState(stateChange.newState)

aggregateStateOnSlideEvent = (prevState, ev) ->
  try
    newState = core.slideEventReducer(prevState, ev)
    ui.updateRevealForPresentationState(newState)
    streams.localSlideStateChangeStream.onNext(
      timestamp: new Date(),
      event: ev,
      prevState: prevState.serialize(),
      newState: newState.serialize())
    CURRENT_LOCAL_SLIDE_STATE = newState
    newState
  catch err
    net.log(err) #TODO: replace this with an error record
    console?.error?("exception in slide state reducer:",
      err,
      "after event:", ev,
      "previous state: ", prevState,
      "new state:", newState)
    prevState                   # leave it at the old state after erro

loadPresentationState = () ->
  window.mainSlideDeck = deck = revealjsDomToSlideDeck()
  initSlide = deck.get(Reveal.getIndices())
  initState = new core.PresentationState(deck, initSlide)
  CURRENT_LOCAL_SLIDE_STATE = initState
  initState

initEvents = ->
  ui.uiSlideEventstream().subscribe(streams.localSlideEventstream)
  streams.localSlideEventstream.aggregate(
    loadPresentationState(),
    aggregateStateOnSlideEvent).subscribe((finalState)->)

  streams.localSlideStateChangeStream.subscribe(logStateChange)
  streams.localSlideStateChangeStream.
    where((stateChange) -> not stateChange.event.isRemote).
    subscribe(net.publishSlideEvent)

  streams.remoteSlideStateChangeStream.subscribe(logRemoteStateChange)
  streams.remoteSlideStateChangeStream.subscribe(handleRemoteSlideEvent)

  streams.log.subscribe(([msg, data]) -> console?.log?(msg, data...))
  streams.log.subscribe(net.log)

main = ->
  $ ->
    #auth.getCurrentUser()
    view_bootstrap.init()
    setTimeout(initEvents, 300) # delay to ensure reveal dom elems are live

################################################################################
exports.main = main

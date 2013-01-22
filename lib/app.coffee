core = require "./app.core"
{revealjsDomToSlideDeck} = require "./app.revealjs_to_slidedeck"
ui = require "./app.ui"
net = require "./app.net"
streams = require "./app.streams"
utils = require "./utils"

CURRENT_LOCAL_SLIDE_STATE = null
setSlideState = (state) ->
  CURRENT_LOCAL_SLIDE_STATE = state
exports.getCurrentState = () -> CURRENT_LOCAL_SLIDE_STATE

################################################################################

logStateChange = (stateChange, msg='state change:') ->
  if not utils.hasFirebug()
    return
  try
    console.log(msg)
    extraDetails =
      slideBefore: stateChange.prevState.slide,
      slideAfter: stateChange.newState.slide
    console.dir(_.extend(extraDetails, stateChange))
  catch err
    console.error?(err)

logRemoteStateChange = (stateChange) ->
  logStateChange(stateChange, 'remote state change:')

################################################################################

MERGE_REMOTE_EVENT_STREAM = true
handleRemoteSlideEvent = (stateChange) ->
  if MERGE_REMOTE_EVENT_STREAM
    ev = stateChange.event
    ev.isRemote = true
    remoteIdx = _.pick(stateChange.prevState.slide, ['h', 'v'])
    localSlideIdx = _.pick(getCurrentState().slide, ['h', 'v'])
    if remoteIdx.toString() != localSlideIdx.toString()
      # out of sync with remote, msgs must have been dropped.
      # sync first before replaying event.
      syntheticSyncEvent = core.EVENTS.SelectSlide(remoteIdx.h, remoteIdx.v)
      syntheticSyncEvent.isRemote = true
      syntheticSyncEvent.isSynthetic = true
      streams.localSlideEventstream.onNext(syntheticSyncEvent)

    streams.localSlideEventstream.onNext(ev)
  else
    # This updates the view but doesn't affect the state
    # machine / event history. Thus, the next local event will resume
    # from the previous local state.
    ui.updateRevealForPresentationState(stateChange.newState)

aggregateStateOnSlideEvent = (prevState, ev) ->
  try
    newState = core.slideEventReducer(prevState, ev)
    ui.updateRevealForPresentationState(newState)
    streams.localSlideStateChangeStream.onNext(
      new core.StateChange(
        event: ev, prevState: prevState, newState: newState))
    setSlideState(newState)
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
  setSlideState(initState)
  initState

initEventstreamSubscriptions = ->
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
    ui.init()
    setTimeout(initEventstreamSubscriptions, 300) # delay to ensure reveal dom elems are live

################################################################################
exports.main = main

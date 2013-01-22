core = require "./app.core"
{revealjsDomToSlideDeck} = require "./app.revealjs_to_slidedeck"
ui = require "./app.ui"
net = require "./app.net"
streams = require "./app.streams"
utils = require "./utils"

CURRENT_LOCAL_SLIDE_STATE = null
setSlideState = (state) ->
  CURRENT_LOCAL_SLIDE_STATE = state
exports.getCurrentState = getCurrentState = () -> CURRENT_LOCAL_SLIDE_STATE

################################################################################

logStateChange = (stateChange, msg='state change:') ->
  if not utils.consoleDebugEnabled()
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

handleSlaveEvent = (stateChange) ->
  # This updates the view but doesn't affect the state
  # machine / event history. Thus, the next local event will resume
  # from the previous local state.
  ui.updateRevealForPresentationState(stateChange.newState)

handleRemoteSlideEvent = (stateChange) ->
  # this is for stateChanges from one users' multiple devices
  ev = stateChange.event
  ev.isRemote = true
  lastRemoteSlide = stateChange.prevState.slide
  if lastRemoteSlide.id != getCurrentState().slide.id
    # out of sync with remote, msgs must have been dropped.
    # sync first before replaying event.
    syntheticSyncEvent = core.EVENTS.SelectSlide({id: lastRemoteSlide.id})
    syntheticSyncEvent.isRemote = true
    syntheticSyncEvent.isSynthetic = true
    streams.localSlideEventstream.onNext(syntheticSyncEvent)
  ##
  streams.localSlideEventstream.onNext(ev)

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
    console?.warn?("exception in slide state reducer:",
      err,
      "after event:", ev,
      "previous state: ", prevState,
      "new state:", newState)
    console?.error?(err)
    prevState                   # leave it at the old state after erro

loadPresentationState = (initSlide) ->
  window.mainSlideDeck = deck = revealjsDomToSlideDeck()
  if not initSlide
    initSlide = deck.get(Reveal.getIndices())
  initState = new core.PresentationState(deck, initSlide)
  setSlideState(initState)
  initState

initEventstreamSubscriptions = (initSlide) ->
  ui.uiSlideEventstream().subscribe(streams.localSlideEventstream)
  streams.localSlideEventstream.aggregate(
    loadPresentationState(initSlide), aggregateStateOnSlideEvent).
    subscribe((finalState)->)
    # NOTE: live stream aggregation so final callback never called, but required

  streams.localSlideStateChangeStream.subscribe(logStateChange)
  streams.localSlideStateChangeStream.
    where((stateChange) -> not stateChange.event.isRemote).
    subscribe(net.publishSlideStateChange)

  streams.remoteUserSlideStateChangeStream.subscribe(logRemoteStateChange)
  streams.remoteUserSlideStateChangeStream.subscribe(handleRemoteSlideEvent)

  streams.remoteSlaveSlideStateChangeStream.subscribe(handleSlaveEvent)

  streams.log.subscribe(([msg, data]) -> console?.log?(msg, data...))
  streams.log.subscribe(net.log)

main = ->
  $ ->
    ui.init()
    setTimeout(initEventstreamSubscriptions, 300) # delay to ensure reveal dom elems are live)
    # $.ajax('/current_slide/', {timeout: 700}).
    #   done(initEventstreamSubscriptions).
    #   fail((req, err) -> console?.log?(err); initEventstreamSubscriptions())

################################################################################
exports.main = main

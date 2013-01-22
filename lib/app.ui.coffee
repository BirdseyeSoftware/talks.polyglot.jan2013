$ = require "jquery"
Rx = require "rx"
_ = require "underscore"
{EVENTS} = require "./app.core"

fullscreen = require "./app.ui.fullscreen"
{init} = require "./app.ui.init"
{updateRevealForPresentationState} = require "./app.ui.reveal"

################################################################################
# ui event to domain event mappings
EVENT_KEYS =
  ToggleOverview:  [13] # enter
  EnterFullscreen: [70] # f
  TogglePause:     [66, 190] # period, b
  Next:            [32,34,78] # space, n, pgdown
  Prev:            [33, 80]   # pgup, p
  Left:            [37, 72]   # left, h
  Up:              [38, 75] #up, k
  Right:           [39, 76] #right, l
  Down:            [40, 74] #down, j

KEYS_TO_EVENTS = {}
for evtype, keys of EVENT_KEYS
  ev = EVENTS[evtype]
  for kcode in keys
    KEYS_TO_EVENTS[kcode] = ev

DIRS_TO_EVENTS =
  up: EVENTS.Up
  down: EVENTS.Down
  right: EVENTS.Right
  left:  EVENTS.Left

REV_DIRS_TO_EVENTS =
  left: EVENTS.Right
  right: EVENTS.Left
  up: EVENTS.Down
  down: EVENTS.Up

directionToSlideEvent = (dir) -> DIRS_TO_EVENTS[dir]?()
keyEventToSlideEvent = (ev) ->  KEYS_TO_EVENTS[ev.which]?()
dblclickEventToSlideEvent = (ev) ->
  EVENTS.AskQuestion(slideId: window.mainSlideDeck.get(Reveal.getIndices()).id)

################################################################################
# touch ui eventstreams
has_touch_support = `'ontouchstart' in document.documentElement` or window.touch?

touchTypes = [
    "doubletap", "tap",
    "swipe", "hold",
    "drag", "dragstart", "dragend",
    "transform", "transformstart", "transformend"
    "release"]

mkTouchEventstream = ($el, eventTypes=touchTypes) ->
  $el = $($el)
  if not $el.data('hammer')
    $el.hammer()
  Rx.Observable.merge(
    $($el).bindAsObservable(evtype) for evtype in eventTypes)

mkClickEventstream = ($el) ->
  evType = if has_touch_support then 'touchstart' else 'click'
  $($el).liveAsObservable(evType)

################################################################################
# full screen stuff
fullscreenEventToSlideEvent = (isFull) ->
  EVENTS.ExitFullscreen() if not isFull # we skip enter events

mkFullscreenChangeEventstream = () ->
  $(document).bindAsObservable(
    'webkitfullscreenchange mozfullscreenchange fullscreenchange').
    select(fullscreen.isActive)

################################################################################
# domain eventstream observables from ui events

revealOverviewClickEventstream = ->
  mkClickEventstream("div.reveal.overview section:not(.stack)").
    select((ev) ->
        try
          ev.preventDefault()
          ev.stopImmediatePropagation()
          $el = $(ev.currentTarget)
          EVENTS.SelectSlide(
            h: $el.attr('data-index-h'),
            v: ($el.attr('data-index-v') or 0))
        catch er
          null)

revealNavBarClickEventstream = ->
  mkClickEventstream("aside.controls div").
    select((ev) ->
        try
          ev.preventDefault()
          ev.stopImmediatePropagation()
          $el = $(ev.target)
          cls = $el.attr("class").split(" ")[0]
          dir = cls.replace("navigate-", "")
          directionToSlideEvent(dir)
        catch err
          null)

touchEventToSlideEvent = (ev) ->
  switch ev.type
    when "hold" then EVENTS.TogglePause()
    #when "tap" then EVENTS.Next()
  
    when "doubletap" then EVENTS.AskQuestion(slideId: window.mainSlideDeck.get(Reveal.getIndices()).id)
    when "swipe" then REV_DIRS_TO_EVENTS[ev.direction]?()

exports.uiSlideEventstream = () ->
  keyups = $('body').bindAsObservable("keyup")
  dblclicks = $('body').bindAsObservable("dblclick")
  merged = Rx.Observable.merge(
    revealNavBarClickEventstream(),
    revealOverviewClickEventstream(),
    mkFullscreenChangeEventstream().select(fullscreenEventToSlideEvent),
    mkTouchEventstream($('body')).select(touchEventToSlideEvent),
    keyups.select(keyEventToSlideEvent)
    dblclicks.select(dblclickEventToSlideEvent))
  merged.where((n) -> n)         #drop nulls #TODO: log what leads to null

################################################################################
exports.updateRevealForPresentationState = updateRevealForPresentationState
exports.init = init

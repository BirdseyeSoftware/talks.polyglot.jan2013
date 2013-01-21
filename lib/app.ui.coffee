Rx = require "rx"
{EVENTS} = require "./app.core"

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

################################################################################

################################################################################
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
    hammerEventstream($el, evtype) for evtype in eventTypes)

mkClickEventstream = ($el) ->
  evType = if has_touch_support then 'touchstart' else 'click'
  $($el).liveAsObservable(evType)

hammerEventstream = ($el, event_type) ->
  $($el).bindAsObservable(event_type)

################################################################################
revealOverviewClickEventstream = ->
  mkClickEventstream("div.reveal.overview section").
    select((ev) ->
        try
          $el = $(ev.currentTarget)
          EVENTS.SelectSlide($el.attr('data-index-h'),
            $el.attr('data-index-v'))
        catch er
          null)

revealNavBarClickEventstream = ->
  mkClickEventstream("aside.controls div").
    select((ev) ->
        try
          $el = $(ev.target)
          cls = $el.attr("class").split(" ")[0]
          dir = cls.replace("navigate-", "")
          directionToSlideEvent(dir)
        catch err
          null)

touchEventToSlideEvent = (ev) ->
  switch ev.type
    when "hold" then EVENTS.TogglePause()
    when "doubletap" then  EVENTS.ToggleOverview()
    when "swipe" then REV_DIRS_TO_EVENTS[ev.direction]?()

exports.uiSlideEventstream = () ->
  keyups = $('body').bindAsObservable("keyup")
  merged = Rx.Observable.merge(
    revealNavBarClickEventstream(),
    revealOverviewClickEventstream(),
    mkTouchEventstream($('body')).select(touchEventToSlideEvent)
    keyups.select(keyEventToSlideEvent))
  merged.where((n) -> n)         #drop nulls #TODO: log what leads to null

######################################################################

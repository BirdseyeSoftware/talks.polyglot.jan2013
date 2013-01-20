Rx = require "rx"
{EVENTS} = require "./app.core"

EVENT_KEYS =
  ToggleOverview:  [13] # enter
  EnterFullscreen: [70] # f
  TogglePause:     [66, 190] # period, b
  NextSlide:       [32,34,78] # space, n, pgdown
  PrevSlide:       [33, 80]   # pgup, p
  LeftSlide:       [37, 72]   # left, h
  UpSlide:         [38, 75] #up, k
  RightSlide:      [39, 76] #right, l
  DownSlide:       [40, 74] #down, j

KEYS_TO_EVENTS = {}
for evtype, keys of EVENT_KEYS
  ev = EVENTS[evtype]
  for kcode in keys
    KEYS_TO_EVENTS[kcode] = ev

DIRS_TO_EVENTS =
  up: EVENTS.UpSlide
  down: EVENTS.DownSlide
  right: EVENTS.RightSlide
  left:  EVENTS.LeftSlide

REV_DIRS_TO_EVENTS =
  left: EVENTS.RightSlide
  right: EVENTS.LeftSlide
  up: EVENTS.DownSlide
  down: EVENTS.UpSlide

directionToSlideEvent = (dir) -> DIRS_TO_EVENTS[dir]?()
keyEventToSlideEvent = (ev) ->  KEYS_TO_EVENTS[ev.which]?()

################################################################################
# #TODO: refactor / remove window refs
window.revealToSlideDeck = revealToSlideDeck

window.jumpToSlide = (slide) ->
  Reveal.slide(slide.h, slide.v)
  Reveal.deactivateOverview()

window.jumpToSlideId = (slideId) ->
  slide = revealToSlideDeck().get(slideId)
  Reveal.slide(slide.h, slide.v)
  Reveal.deactivateOverview()

stripRevealIdPrefix = (id) ->
  if id
    m = id.match(/reveal-(.+)/)
    if m? then m[1] else id

indexSlide = (acc, slideSection) ->
  if not acc
    {h:0, v:0}                  #first slide
  else
    switch slideSection.parentNode.tagName
      when 'DIV' then {h: 1 + acc.h, v:0}
      when 'SECTION'
        if not acc.nested
          {h: 1 + acc.h, v: 0, nested: true}
        else
          {h: acc.h, v: 1 + acc.v, nested: true}
      else {error: slideSection}

domSectionsToSlideDeck = ($containerNode) ->
  sections = _.filter($containerNode.find('section'), (s) -> s.id)
  indices = utils.scanl(sections, indexSlide)
  slides = for [idx, sect] in _.zip(indices, sections)
    new Slide(stripRevealIdPrefix($(sect).attr('id')), idx.h, idx.v)
  new SlideDeck(slides)

revealToSlideDeck = () ->
  domSectionsToSlideDeck($("div.reveal"))

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

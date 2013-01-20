require "rx/rx.time"
_ = require "underscore"

utils = require "./utils"
######################################################################

class Slide
  constructor: (@id, @h, @v) ->

class SlideDeck
  constructor: (@slides) ->
    @idsToSlides = {}
    for slide in @slides
      @idsToSlides[slide.id] = slide

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

scanl = (coll, reducer, init) ->
  acc = init
  for el in coll
    acc = reducer(acc, el)
    do (acc)->
      acc

domSectionsToSlideDeck = ($containerNode) ->
  sections = _.filter($containerNode.find('section'), (s) -> s.id)
  indices = scanl(sections, indexSlide)
  slides = for [idx, sect] in _.zip(indices, sections)
    new Slide(stripRevealIdPrefix($(sect).attr('id')), idx.h, idx.v)
  new SlideDeck(slides)

revealToSlideDeck = () ->
  domSectionsToSlideDeck($("div.reveal"))

######################################################################
#TODO: refactor / remove window refs
window.revealToSlideDeck = revealToSlideDeck

window.jumpToSlide = (slide) ->
  Reveal.slide(slide.h, slide.v)
  Reveal.deactivateOverview()

window.jumpToSlideId = (slideId) ->
  slide = revealToSlideDeck().idsToSlides[slideId]
  Reveal.slide(slide.h, slide.v)
  Reveal.deactivateOverview()

######################################################################
EVENTS =
  ToggleOverview:  {keys: [13]} # enter
  EnterFullscreen: {keys: [70]} # f
  TogglePause:     {keys: [66, 190]} # period, b
  NextSlide:       {keys: [32,34,78]} # space, n, pgdown
  PrevSlide:       {keys: [33, 80]}   # pgup, p
  LeftSlide:       {keys: [37, 72]}   # left, h
  UpSlide:         {keys: [38, 75]} #up, k
  RightSlide:      {keys: [39, 76]} #right, l
  DownSlide:       {keys: [40, 74]} #down, j
  SelectSlide:     {}

KEYS_TO_EVENTS = {}
for k, v of EVENTS
  do (k, v) ->
    ev = EVENTS[k] = -> {type: k}
    if v.keys?
      for kcode in v.keys
        KEYS_TO_EVENTS[kcode] = ev

movements = ["NextSlide", "PrevSlide", "UpSlide", "DownSlide", "RightSlide", "LeftSlide"]

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

######################################################################

EVENTS_TO_REVEAL_FNS =
  EnterFullscreen: Reveal.enterFullscreen
  TogglePause: Reveal.togglePause
  ToggleOverview: Reveal.toggleOverview
  PrevSlide: Reveal.prev
  NextSlide: Reveal.next
  UpSlide:   Reveal.up
  DownSlide: Reveal.down
  RightSlide: Reveal.right
  LeftSlide: Reveal.left
  SelectSlide: (ev) ->
    Reveal.slide(ev.h, ev.v)
    Reveal.deactivateOverview()

handleRevealCommand = (slideEvent) ->
  EVENTS_TO_REVEAL_FNS[slideEvent.type]?(slideEvent)

######################################################################
is_touch = `'ontouchstart' in document.documentElement`
#is_touch = document.documentElement.ontouchstart? or window.touch?

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
  evType = if is_touch then 'touchstart' else 'click'
  $($el).liveAsObservable(evType)


hammerEventstream = ($el, event_type) ->
  $($el).bindAsObservable(event_type)

################################################################################

# exports.revealAsObservable = revealAsObservable = (event_type) ->
#   subj = new Rx.Subject()
#   subj.callback = (params) -> subj.onNext(params)
#   Reveal.addEventListener(event_type, subj.callback)
#   subj

revealOverviewClickEventstream = ->
  mkClickEventstream("div.reveal.overview section").
    select((ev) ->
        try
          $el = $(ev.currentTarget)
          sev = EVENTS.SelectSlide()
          sev.h = $el.attr('data-index-h')
          sev.v = $el.attr('data-index-v')
          sev
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

appendRevealDetails = (ev) ->
  ev.revealIndices = Reveal.getIndices()
  ev

appendSlideDOMId = (ev) ->
  ev.slideId = stripRevealIdPrefix(Reveal.getCurrentSlide().id)
  ev

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
  merged.
    where((n) -> n).         #drop nulls #TODO: log what leads to null
    select(appendSlideDOMId).
    select(appendRevealDetails)

######################################################################

exports.handleRemoteSlideEvent = (slideEvent) ->
  console.log("remote", slideEvent)
  if slideEvent.type in movements
    {h, v} = slideEvent.revealIndices
    Reveal.slide(h, v)
  else
    handleRevealCommand(slideEvent)

exports.handleLocalSlideEvent = (slideEvent) ->
  utils.log("local", slideEvent)
  handleRevealCommand(slideEvent)

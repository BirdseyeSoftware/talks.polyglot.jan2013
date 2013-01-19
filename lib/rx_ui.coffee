require "rx/rx.time"
_ = require "underscore"

## Rx Observables ####################################################

exports.hammerAsObservable = hammerAsObservable = ($el, event_type) ->
  $($el).hammer().bindAsObservable(event_type)

exports.revealAsObservable = revealAsObservable = (event_type) ->
  subj = new Rx.Subject()
  subj.callback = (params) -> subj.onNext(params)
  Reveal.addEventListener(event_type, subj.callback)
  subj

######################################################################

######################################################################

NextSlide = ->
  type: "NextSlide"

PrevSlide = ->
  type: "PrevSlide"

UpSlide = ->
  type: "UpSlide"

DownSlide = ->
  type: "DownSlide"

RightSlide = ->
  type: "RightSlide"

LeftSlide = ->
  type: "LeftSlide"

keyEventToSlideEvent = (ev) ->
  ev_map =
    37: PrevSlide
    39: NextSlide
    32: NextSlide
  ctor = ev_map[ev.which]
  if ctor?
    ctor()

directionStrToSlideEvent = (direction) ->
  ev_map =
    "up": UpSlide
    "down": DownSlide
    "right": RightSlide
    "left":  LeftSlide
  ctor = ev_map[direction]
  if ctor?
    ctor()

revealNavBarObservable = ->
  $("aside.controls div").
    liveAsObservable("click").
    select((ev) ->
        $el = $(ev.target)
        cls = $el.attr("class").split(" ")[0]
        dir = cls.replace("navigate-", "")
        directionStrToSlideEvent(dir))

swipeEventToSlideEvent = (ev) ->
  dir = ev.direction
  rev_dirs =
    left: "right"
    right: "left"
    up: "down"
    down: "up"
  directionStrToSlideEvent(rev_dirs[dir])

appendRevealDetails = (ev) ->
  ev.revealIndices = Reveal.getIndices()
  ev

appendSlideDOMId = (ev) ->
  currentSlide = Reveal.getCurrentSlide().id
  if currentSlide?
    m = currentSlide.match(/reveal-(.+)/)
    if m?
      ev.slideId = m[1]
  ev

exports.slideEventsObservable = slideEventsObservable = ($el) ->
  $el = $($el)
  Rx.Observable.merge(
    revealNavBarObservable(),
    hammerAsObservable($el, "swipe").select(swipeEventToSlideEvent),
    $el.bindAsObservable("keyup").select(keyEventToSlideEvent)).
    where((n) -> n).
    select(appendSlideDOMId).
    select(appendRevealDetails)

######################################################################

exports.handleRemoteSlideEvent = (slideEvent) ->
  {h, v} = slideEvent.revealIndices
  Reveal.slide(h, v)

handleRevealCommand = (slideEvent) ->
  ev_map =
    PrevSlide: Reveal.prev
    NextSlide: Reveal.next
    UpSlide:   Reveal.up
    DownSlide: Reveal.down
    RightSlide: Reveal.right
    LeftSlide: Reveal.left
  fn = ev_map[slideEvent.type]
  if fn?
    fn()

exports.handleSlideEvent = (slideEvent) ->
  handleRevealCommand(slideEvent)

exports.PrevSlide = PrevSlide
exports.NextSlide = NextSlide

_ = require "underscore"

class Slide
  constructor: (@id, @h, @v, @offset=null) ->

class SlideDeck
  constructor: (@slides) ->
    @length = @slides.length
    @_idsToSlides = {}
    @_coordsToSlide = {}
    for slide, i in slides
      slide.offset = i
      @_idsToSlides[slide.id] = slide
      @_coordsToSlide[[slide.h, slide.v]] = slide

  get: (idxOrId) ->
    switch typeof(idxOrId)
      when 'string' then @_idsToSlides[idxOrId]
      when 'object' then @_coordsToSlide[[idxOrId.h, idxOrId.v]]
      when 'number' then @slides[idxOrId]

move = (slideDeck, direction, fromSlide) ->
  direction = direction.toLowerCase()
  if not fromSlide
    fromSlide = slideDeck.slides[0]

  tryHorVerMove = (idxs) ->
    newslide = slideDeck.get(_.extend({h: fromSlide.h, v: fromSlide.v}, idxs))
    newslide or fromSlide

  switch direction
    when "prev"
      slideDeck.get(Math.max(0, fromSlide.offset - 1))
    when "next"
      slideDeck.get(Math.min(slideDeck.length - 1, fromSlide.offset + 1))
    when "up"
      tryHorVerMove(v: fromSlide.v - 1)
    when "down"
      tryHorVerMove(v: fromSlide.v + 1)
    when "left"
      tryHorVerMove(h: fromSlide.h - 1)
    when "right"
      tryHorVerMove(h: fromSlide.h + 1)

EVENTS =
  SelectSlide:     (h, v) -> {type: "SelectSlide", h: h, v:v}
  ToggleOverview:  null
  EnterFullscreen: null
  TogglePause:     null
  Next:            null
  Prev:            null
  Left:            null
  Up:              null
  Right:           null
  Down:            null

## cleanup the null constructors
for k, ctor of EVENTS
  do (k, ctor) ->
    ctor = ctor or -> {type: k}
    ev = EVENTS[k] = ctor

movements = ["Next", "Prev", "Up", "Down", "Right", "Left"]
################################################################################
toggle = (current, options=[true, false]) ->
  if current is options[0]
    options[1]
  else
    options[0]

Modes =
  normal: "normal"
  overview: "overview"

class PresentationState
  constructor: (@slideDeck,
                @slide=null,
                @mode=Modes.normal,
                @paused=false,
                @fullscreen=false) ->
    if not slide
      @slide = @slideDeck[0]

movementHandler = (state, ev) ->
  slide: move(state.slideDeck, ev.type, state.slide)
  paused: false

EventHandlers =
  ToggleOverview: (state, ev) ->
    mode: toggle(state.mode, [Modes.overview, Modes.normal])

  EnterFullscreen: (state, ev) -> fullscreen: true
  TogglePause: (state, ev) ->  paused: toggle(state.paused)

  SelectSlide: (state, ev) ->
    slide = state.slideDeck.get(ev)
    {slide: slide, mode: Modes.normal, paused: false}

  Next:  movementHandler
  Prev:  movementHandler
  Left:  movementHandler
  Up:    movementHandler
  Right: movementHandler
  Down:  movementHandler

slideEventReducer = (prevState, ev) ->
  if not prevState
    throw new Error("Invalid state: #{prevState}")
  handler = EventHandlers[ev.type] #TODO: error handling
  if not handler
    throw new Error("Invalid event: #{ev}")
  whatChanged = handler(prevState, ev)
  _.extend(_.clone(prevState), whatChanged)

################################################################################
exports.Slide = Slide
exports.SlideDeck = SlideDeck
exports.movements = movements
exports.EVENTS = EVENTS
exports.Modes = Modes

exports._testExports =
  toggle: toggle
  PresentationState: PresentationState
  EventHandlers: EventHandlers
  slideEventReducer: slideEventReducer
  move: move

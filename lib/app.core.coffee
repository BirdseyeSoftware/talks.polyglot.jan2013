_ = require "underscore"

class Slide
  constructor: (@id, @h, @v, @offset=null) ->
  toString: () -> "Slide{h: #{@h}, v: #{@v}, offset: #{@offset}}"

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

  tryHorVerMove = (idxs, fallbackIdxs) ->
    newslide = slideDeck.get(_.extend({h: fromSlide.h, v: fromSlide.v}, idxs))
    newslide or (fallbackIdxs and tryHorVerMove(fallbackIdxs)) or  fromSlide

  fs = fromSlide
  switch direction
    when "prev"
      slideDeck.get(Math.max(0, fs.offset - 1))
    when "next"
      slideDeck.get(Math.min(slideDeck.length - 1, fs.offset + 1))
    when "up"
      tryHorVerMove(v: fs.v - 1)
    when "down"
      tryHorVerMove(v: fs.v + 1)
    when "left"
      tryHorVerMove({h: fs.h - 1}, {h: fs.h - 1, v: 0})
    when "right"
      tryHorVerMove({h: fs.h + 1}, {h: fs.h + 1, v: 0})

################################################################################
EVENTS =
  SelectSlide:     ({h, v, id}) -> {type: "SelectSlide", h: h, v: v, id: id}
  ToggleOverview:  null
  EnterFullscreen: null
  ExitFullscreen:  null
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
    if not @slide
      @slide = @slideDeck.get(0)

movementHandler = (state, ev) ->
  slide: move(state.slideDeck, ev.type, state.slide)
  paused: false

EventHandlers =
  ToggleOverview: (state, ev) ->
    mode: toggle(state.mode, [Modes.overview, Modes.normal])

  EnterFullscreen: (state, ev) -> fullscreen: true
  ExitFullscreen: (state, ev) -> fullscreen: false # TODO: trigger from fullscreen dom api
  TogglePause: (state, ev) -> paused: toggle(state.paused)

  SelectSlide: (state, ev) ->
    slide = state.slideDeck.get(if ev.id then ev.id else ev)
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
toSlideObj = (slide) ->
  if slide.constructor is Slide
    slide
  else
    new Slide(slide.id, slide.h, slide.v, slide.offset)

class StateChange
  constructor: ({prevState, newState, event, timestamp}) ->
    @prevState = prevState
    @newState = newState
    @event = event
    @timestamp = timestamp or new Date()
    # properly rehydrate slides after network transport
    @prevState.slide = toSlideObj(prevState.slide)
    @newState.slide = toSlideObj(newState.slide)
    @prevState = _.omit(prevState, 'slideDeck')
    @newState = _.omit(newState, 'slideDeck')

################################################################################
exports.Slide = Slide
exports.SlideDeck = SlideDeck
exports.movements = movements
exports.EVENTS = EVENTS
exports.Modes = Modes
exports.slideEventReducer = slideEventReducer
exports.PresentationState = PresentationState
exports.StateChange = StateChange

exports._testExports =
  toggle: toggle
  EventHandlers: EventHandlers
  move: move

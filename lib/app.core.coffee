require "rx/rx.time"
_ = require "underscore"

utils = require "./utils"
################################################################################
class Slide
  constructor: (@id, @h, @v) ->

class SlideDeck
  constructor: (@slides) ->
    @_idsToSlides = {}
    for slide in @slides
      @_idsToSlides[slide.id] = slide
  get: (idxOrId) ->
    if typeof(idxOrId) is 'string'
      @_idsToSlides[idxOrId]
    else
      @slides[idxOrId]

################################################################################
EVENTS =
  ToggleOverview:  null
  EnterFullscreen: null
  TogglePause:     null
  NextSlide:       null
  PrevSlide:       null
  LeftSlide:       null
  UpSlide:         null
  RightSlide:      null
  DownSlide:       null
  SelectSlide:     (h, v) -> {type: "SelectSlide", h: h, v:v}

for k, ctor of EVENTS
  do (k, ctor) ->
    ctor = ctor or -> {type: k}
    ev = EVENTS[k] = ctor

################################################################################

movements = ["NextSlide", "PrevSlide", "UpSlide", "DownSlide",
  "RightSlide", "LeftSlide"]

exports.movements = movements
exports.EVENTS = EVENTS

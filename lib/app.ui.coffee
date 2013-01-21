Rx = require "rx"
_ = require "underscore"
{EVENTS} = require "./app.core"
{mktee} = require("./utils")

################################################################################
MODES =
  AUDIENCE: "AUDIENCE",
  PRESENTER: "PRESENTER"

stylesheetMap =
  AUDIENCE: ["/common.css", "/audience.css",
             "/reveal.js/css/reveal.min.css",
             "/reveal.js/css/theme/default.css",
             "/reveal.js/lib/css/zenburn.css"],
  PRESENTER: ["/common.css", "/presenter.css"]
  ORG_MODE: ["/common.css", "/presenter.css"]

exports.mode_observable = mode_observable = new Rx.Subject()
setPresentationMode = (mode) -> mode_observable.onNext(mode)

setStylesheet = (mode) ->
  $("style").remove()
  $("link[rel=stylesheet]").remove()
  for href in stylesheetMap[mode]
    $("head").append(
      $("<link>").attr("href", href).
                  attr("rel", "stylesheet"))

toggleDomElemsForMode = (mode) ->
  switch mode
    when MODES.AUDIENCE
      $("#reveal").show()
      $("#org-mode-content").hide()
    when MODES.PRESENTER
      $("#org-mode-content").show()
      $("#reveal").hide()
    when MODES.ORG_MODE
      $("#org-mode-content").show()
      $("#reveal").hide()

handleModeChange = mktee(setStylesheet, toggleDomElemsForMode)
mode_observable.subscribe(handleModeChange)

################################################################################
# transform org-mode slides to Reveal.js section tags
orgSlideToReveal = ($orgSlide) ->
  $orgSlide = $($orgSlide)
  $revealSlide = $("<section>").html($orgSlide.html())
  $IDLink = $orgSlide.find("h2 > a, h3 > a, h4 > a")
  if $IDLink.length > 0
    id = $($IDLink[0]).attr("id")
    $orgSlide.attr(id: "org-#{id}")
    $revealSlide.attr(id: "reveal-#{id}")

  $revealSlide.find("div.notes").remove()
  slideLevel = parseInt($orgSlide.attr("class").match(/outline-(\d+)/)[1], 10)
  $childSlides = $revealSlide.find("div.outline-#{slideLevel + 1}")
  revealChildSlides = _.map($childSlides, orgSlideToReveal)
  $childSlides.remove()
  $currentLevelNodes = $revealSlide.children()
  if $currentLevelNodes.length > 0 and revealChildSlides.length > 0
    $currentLevelNodes.remove()
    $firstChildSlide = $("<section>").append($currentLevelNodes)
    $firstChildSlide.attr(id: $revealSlide.attr('id'))
    $revealSlide.attr(id: null)
    revealChildSlides = [[$firstChildSlide, []]].concat(revealChildSlides)

  [$revealSlide, revealChildSlides]

stitchRevealSlides = ($container, [$slide, children]) ->
  $slide.appendTo($container)
  _.map(children, (child) -> stitchRevealSlides($slide, child))
  null

bootstrapRevealContentFromOrg = ()->
  $orgContent = $("div#content").hide().attr(id: "org-mode-content")
  $orgSlides = $orgContent.find("div.outline-2")

  $revealSlidesContainer = $("<div>").addClass("slides")
  $revealContent = $("<div>").
                     addClass("reveal").
                     append($revealSlidesContainer).
                     appendTo($(document.body))
  for slideTree in _.map($orgSlides, orgSlideToReveal)
    stitchRevealSlides($revealSlidesContainer, slideTree)
  ##
  for code in $revealSlidesContainer.find('pre')
    $(code).html($("<code>").html($(code).html()))

################################################################################
# UI bootstrap sequence
fixAssetsPath = () ->
  fixPath = (attr_name) ->
    () ->
      $el = $(@)
      if $el.attr(attr_name)?.substring(0,1) != "/"
        $el.attr(attr_name, "/#{$el.attr(attr_name)}")
      null

  $("img").each(fixPath("src"))
  $("script").each(fixPath("src"))
  $("link").each(fixPath("href"))
  null

exports.init = () ->
  # initial UI bootstrapping
  bootstrapRevealContentFromOrg()
  setPresentationMode(MODES.AUDIENCE)
  fixAssetsPath()
  $("body").bind("touchstart", (ev) -> ev.preventDefault())
  $("div#table-of-contents h2").remove()
  $("#preamble, #postamble").remove()
  bootstrapRevealContentFromOrg()
  Reveal.addEventListener("ready",
    -> $("aside.controls > div").unbind()
    setTimeout((->$("body").show()), 300))
  Reveal.initialize(
    keyboard: false,
    rollingLinks: false
    history: true
    dependencies: [
      {src: 'reveal.js/plugin/highlight/highlight.js', async: true,
      callback: () -> hljs.initHighlightingOnLoad()}])

################################################################################
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

################################################################################
# touch ui eventstreams
has_touch_support = `'ontouchstart' in document.documentElement` or window.touch?

touchTypes = [
    "doubletap", "tap",
    "swipe", "hold",
    "drag", "dragstart", "dragend",
    "transform", "transformstart", "transformend"
    "release"]

# hammerEventstream = ($el, event_type) ->
#   $($el).bindAsObservable(event_type)

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
isFullscreenActive = () ->
  (document.fullscreenElement or
    document.mozFullScreenElement or
    document.webkitFullscreenElement)

fullscreenEventToSlideEvent = (isFull) ->
  EVENTS.ExitFullscreen() if not isFull # we skip enter events

mkFullscreenChangeEventstream = () ->
  $(document).bindAsObservable(
    'webkitfullscreenchange mozfullscreenchange fullscreenchange').
    select(isFullscreenActive)

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
            $el.attr('data-index-h'),
            ($el.attr('data-index-v') or 0))
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
    when "doubletap" then  EVENTS.ToggleOverview()
    when "swipe" then REV_DIRS_TO_EVENTS[ev.direction]?()

exports.uiSlideEventstream = () ->
  keyups = $('body').bindAsObservable("keyup")
  merged = Rx.Observable.merge(
    revealNavBarClickEventstream(),
    revealOverviewClickEventstream(),
    mkFullscreenChangeEventstream().select(fullscreenEventToSlideEvent),
    mkTouchEventstream($('body')).select(touchEventToSlideEvent),
    keyups.select(keyEventToSlideEvent))
  merged.where((n) -> n)         #drop nulls #TODO: log what leads to null

######################################################################
# Reveal.js view update code

cancelFullscreen = () ->
  document.exitFullscreen?()
  document.mozCancelFullScreen?()
  document.webkitCancelFullscreen?()

enterFullscreen = () ->
  Reveal.enterFullscreen()

updateRevealForPresentationState = (state) ->
  {h, v} = Reveal.getIndices()
  slide = state.slide
  if slide.h != h or slide.v != v
    Reveal.slide(slide.h, slide.v)

  if state.paused and not Reveal.isPaused()
    Reveal.togglePause()
  else if Reveal.isPaused() and not state.paused
    Reveal.togglePause()

  if state.mode == 'overview'
    Reveal.toggleOverview() if not Reveal.isOverviewActive()
  else
    Reveal.deactivateOverview() if Reveal.isOverviewActive()

  if state.fullscreen and not isFullscreenActive()
    enterFullscreen()
  else if not state.fullscreen and isFullscreenActive()
    cancelFullscreen()

################################################################################
exports.updateRevealForPresentationState = updateRevealForPresentationState

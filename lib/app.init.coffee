rx = require("rx")
{mktee} = require("./utils")

MODES =
  AUDIENCE: "AUDIENCE",
  PRESENTER: "PRESENTER"

stylesheetMap =
  AUDIENCE: ["/common.css", "/audience.css",
             "reveal.js/css/reveal.min.css",
             "reveal.js/css/theme/default.css",
             "reveal.js/lib/css/zenburn.css"],
  PRESENTER: ["/common.css", "/presenter.css"]
  ORG_MODE: ["/common.css", "/presenter.css"]

exports.mode_observable = mode_observable = new rx.Subject()
setPresentationMode = (mode) -> mode_observable.onNext(mode)

################################################################################

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

transformToReveal = ()->
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

unbindRevealEvents = () ->
  console.log("gone")
  $("aside.controls > div").unbind()

initialCleanupAndTransform = () ->
  $("div#table-of-contents h2").remove()
  $("#preamble, #postamble").remove()
  transformToReveal()
  Reveal.addEventListener("ready", unbindRevealEvents)

exports.init = ()->
  initialCleanupAndTransform()
  setPresentationMode(MODES.AUDIENCE)
  $("body").bind("touchstart", (ev) -> ev.preventDefault())
  Reveal.initialize(
    keyboard: false,
    rollingLinks: false
    dependencies: [
      {src: 'reveal.js/plugin/highlight/highlight.js', async: true,
      callback: () -> hljs.initHighlightingOnLoad()}]
  )
  setTimeout((-> $("body").show()), 400)

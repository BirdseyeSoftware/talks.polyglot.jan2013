$ = require "jquery"
Rx = require "rx"
_ = require "underscore"
{mktee} = require("./utils")
modes = require "./app.ui.modes"

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
  modes.setPresentationMode(modes.MODES.AUDIENCE)
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

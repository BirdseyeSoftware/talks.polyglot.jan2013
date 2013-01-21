_ = require "underscore"
core = require "./app.core"

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
    new core.Slide(stripRevealIdPrefix($(sect).attr('id')), idx.h, idx.v)
  new core.SlideDeck(slides)

revealToSlideDeck = () ->
  domSectionsToSlideDeck($("div.reveal"))

window.revealToSlideDeck = revealToSlideDeck

window.jumpToSlide = (slide) ->
  Reveal.slide(slide.h, slide.v)
  Reveal.deactivateOverview()

window.jumpToSlideId = (slideId) ->
  slide = revealToSlideDeck().get(slideId)
  Reveal.slide(slide.h, slide.v)
  Reveal.deactivateOverview()

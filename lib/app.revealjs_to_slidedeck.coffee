_ = require "underscore"
utils = require "./utils"
core = require "./app.core"

stripRevealIdPrefix = (id) ->
  if id
    m = id.match(/reveal-(.+)/)
    if m? then m[1] else id

indexSlide = (acc, slideSection) ->
  if not acc
    {h:0, v:0}                  #first slide
  else
    parent = slideSection.parentNode
    nested = parent.tagName == 'SECTION' and $(parent).hasClass('stack')
    if not nested
      {h: 1 + acc.h, v:0}
    else
      if not acc.stackParent or acc.stackParent != parent
        {h: 1 + acc.h, v: 0, stackParent: parent}
      else
        {h: acc.h, v: 1 + acc.v, stackParent: parent}

domSectionsToSlideDeck = ($containerNode) ->
  sections = _.filter($containerNode.find('section'), (s) -> s.id)
  indices = utils.scanl(sections, indexSlide)
  slides = for [idx, sect] in _.zip(indices, sections)
    new core.Slide(stripRevealIdPrefix($(sect).attr('id')), idx.h, idx.v)
  new core.SlideDeck(slides)

exports.revealjsDomToSlideDeck = () ->
  domSectionsToSlideDeck($("div.reveal"))

fullscreen = require "./app.ui.fullscreen"

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

  if state.fullscreen and not fullscreen.isActive()
    fullscreen.enter()
  else if not state.fullscreen and fullscreen.isActive()
    fullscreen.cancel()

################################################################################
exports.updateRevealForPresentationState = updateRevealForPresentationState

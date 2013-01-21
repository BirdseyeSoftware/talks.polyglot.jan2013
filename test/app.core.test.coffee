# run tests in node, not browser
buster = require("buster")
assert = buster.assert
_ = require "underscore"

core = require "../lib/app.core"
_.extend(core, core._testExports)
{EVENTS, Slide, SlideDeck,
  Modes,
  move,
  movements} = core

sampleSlides1 = [
      new Slide("0", 0, 0),
      new Slide("1", 1, 0),
      new Slide("2", 2, 0)
      new Slide("2.1", 2, 1)
      new Slide("2.2", 2, 2)
      new Slide("3", 3, 0)
      ]

buster.testCase "app.core",
  "toggle": ->
    assert(core.toggle(false))
    assert(
      core.toggle(Modes.overview, [Modes.overview, Modes.normal]) ==
      Modes.normal)

  "SlideDeck ctor and .get": ->
    slides = sampleSlides1
    deck = new SlideDeck(slides)
    for slide, i in slides
      assert slide.offset == i
      assert(deck.get(i) == slide)
      assert(deck.get(slide.id) == slide)
      assert(deck.get(slide) == slide)
      assert(deck.get(h: slide.h, v: slide.v) == slide)
    assert(slides.length == deck.length)
    ##
    null

  "event ctors": ->
    for evtype, ctor of EVENTS
      ev = ctor()
      assert ev
      assert ev.type == evtype
    ##
    selectEvent = EVENTS.SelectSlide(1, 3)
    assert selectEvent.h == 1
    assert selectEvent.v == 3
    null

  "movement event types are valid": ->
    for movement in movements
      assert EVENTS[movement]
    ##
    null

  "move()'s final slide argument defaults to first slide": ->
    deck = new SlideDeck(sampleSlides1)
    assert(move(deck, "Prev") == deck.slides[0])
    assert(move(deck, "Up") == deck.slides[0])
    assert(move(deck, "Next") == deck.slides[1])

  "move()'s direction arg is case-insensitive": ->
    deck = new SlideDeck(sampleSlides1)
    assert(move(deck, "prev") == deck.slides[0])
    assert(move(deck, "Prev") == deck.slides[0])

  "move() down/up have no effect on non-stacked slides": ->
    deck = new SlideDeck(sampleSlides1)
    for nonStackedOffest in [0,1,5]
      slide = deck.get(nonStackedOffest)
      assert(move(deck, "Up", slide) == slide)
      assert(move(deck, "Down", slide) == slide)
    ##
    null

  "move() left/right nav by horizontal index": ->
    deck = new SlideDeck(sampleSlides1)
    slide = first = deck.slides[0]
    last = deck.get(deck.length - 1)
    while slide != last
      nextslide = move(deck, 'right', slide)
      assert((slide.h + 1) == nextslide.h)
      assert(nextslide.v == 0)
      slide = nextslide
    slide = last
    while slide != first
      nextslide = move(deck, 'left', slide)
      assert((slide.h - 1) == nextslide.h)
      assert(nextslide.v == 0)
      slide = nextslide
    ##
    null

  "move() won't go beyond deck bounds": ->
    deck = new SlideDeck(sampleSlides1)
    assert(move(deck, "Prev") == deck.slides[0])
    assert(move(deck, "Left") == deck.slides[0])
    assert(move(deck, "Up") == deck.slides[0])
    assert(move(deck, "Prev", deck.slides[0]) == deck.slides[0])
    for slide, i in deck.slides
      nextSlide = move(deck, "Next", slide)
      if i == (deck.length - 1)
        # last slide
        assert nextSlide == slide
        assert(move(deck, "Down", slide) == slide)
        assert(move(deck, "Right", slide) == slide)
      else
        assert nextSlide.offset == i+1
    ##
    null

  "slideEventReducer() with sample events": ->
    #TODO: add test for multiple stacked slide sections in a row
    deck = new SlideDeck(sampleSlides1)
    sampleEvents = [
      [EVENTS.Up(), 0],
      [EVENTS.Next(), 1],
      [EVENTS.Next(), 2],
      [EVENTS.Prev(), 1],
      [EVENTS.SelectSlide(3, 0), 5],
      [EVENTS.Prev(), 4],
      [EVENTS.Prev(), 3],
      [EVENTS.Down(), 4],
      [EVENTS.Down(), 4, {paused: false, mode: Modes.normal}],
      [EVENTS.TogglePause(), 4, {paused: true}],
      [EVENTS.TogglePause(), 4, {paused: false}],
      [EVENTS.ToggleOverview(), 4, {mode: Modes.overview}],
      [EVENTS.ToggleOverview(), 4, {mode: Modes.normal}],
      ]
    state = new core.PresentationState(deck)
    for [ev, expectedOffset, expectedProps] in sampleEvents
      newState = core.slideEventReducer(state, ev)
      assert(newState.slide.offset == expectedOffset)
      if expectedProps
        for k, v of expectedProps
          assert(v == newState[k], k)
      state = newState
    ##
    null

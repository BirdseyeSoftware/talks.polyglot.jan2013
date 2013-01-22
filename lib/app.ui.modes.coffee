$ = require "jquery"
Rx = require "rx"
{mktee} = require("./utils")

clientModeChangeEventstream = new Rx.Subject()
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

setPresentationMode = (mode) -> clientModeChangeEventstream.onNext(mode)

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
clientModeChangeEventstream.subscribe(handleModeChange)

################################################################################
exports.setPresentationMode = setPresentationMode
exports.clientModeChangeEventstream = clientModeChangeEventstream
exports.MODES = MODES

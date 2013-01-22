exports.isFullscreenActive = exports.isActive = () ->
  (document.fullscreenElement or
    document.mozFullScreenElement or
    document.webkitFullscreenElement)

exports.cancel = exports.cancelFullscreen = () ->
  document.exitFullscreen?()
  document.mozCancelFullScreen?()
  document.webkitCancelFullscreen?()

exports.enterFullscreen = exports.enter = () ->
  Reveal.enterFullscreen()

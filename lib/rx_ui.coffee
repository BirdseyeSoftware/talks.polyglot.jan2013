# window.$ = require "jquery"
# window.Rx = require "rx"
# require "rxjs-jquery"
eventToKeycode = (ev) ->
  ev.which

isDirectionKey = (keycode) ->
  keycode == 37 || #left
  keycode == 39    # right

directionKeyToSlideMovement = (keycode) ->
  if keycode == 37
    "PrevSlide"
  else if keycode == 39
    "NextSlide"
  else
    "I don't know"

notify = (msg) ->
  alert(msg)
  #$("#content").append(msg)


window.client = client = new Faye.Client("/faye")

# THIS ONE WORKS!
# $(->
#   $("body#circus").bind("touchstart", (ev) ->
#     client.publish("/touch", msg: "hello world")))

$(->
  $("body#circus").hammer().bind("swipe", (ev) ->
    ev.preventDefault()
    #notify(ev.direction)
    client.publish("/touch", ev.direction)
    ))

#
# $(->
#   touchEvents = $("body#circus").
#                   bindAsObservable("swipe").
#                   subscribe(
#                       ((ev) ->
#                         ev.preventDefault()
#                         notify(ev.direction)
#                         #client.publish("/touch", ev.direction)
#                         ),
#                       ((err) -> notify(err)),
#                       (-> notify("complete"))))


                      #pub = client.publish("/touch", ev)
                      #pub.callback(-> notify("Sent successfuly"))
                      #pub.errback((err) -> notify(err))


  # $("body#circus").bind("touchend", (ev) ->
  #   notify(ev))
  # touchEvents = $("body#circus").
  #                 bindAsObservable("touchstart").
  #                 throttle(1000).
  #                 subscribe((ev) ->
  #                     client.publish("/touch", ev)
  #                     notify("You have been touched!"))

  # slideMovements = $("body#circus").
  #                    keyupAsObservable().
  #                    where(_.compose(isDirectionKey, eventToKeycode)).
  #                    select(_.compose(directionKeyToSlideMovement, eventToKeycode))
  # slideMovements.subscribe(
  #   (move)-> console.log(move),
  #   (err) -> console.log(err))

{server} = require "./server.core"
store  = require "./server.storage"
pubsub = require "./server.pubsub"
require "./server.passport"
config = require "./server.config"

################################################################################

server.get('/', (req, resp) -> resp.redirect("/slideshow/"))


server.get('/login/',
  (req, resp) ->
    if req.user?
      resp.redirect("/slideshow/")
    else
      resp.sendfile("assets/login.html", {}, (err) -> console.log(err)))

server.get('/logout/',
  (req, resp) ->
    if req.user?
      res.clearCookie('userSession')
      req.session.auth = null
      req.session.destroy(->)
    resp.redirect("/login/"))

server.get('/slideshow/',
  (req, resp) ->
    if req.user?
      resp.sendfile("build/slides.html")
    else
      resp.redirect("/login/"))

server.get("/users/",
  (req, resp) ->
    resp.set("Content-Type", "application/json")
    store.getAuthenticatedUsers((err, result) ->
      resp.write(JSON.stringify(result))
      resp.end()))

server.get("/slide_events/:provider/:id",
  (req, resp) ->
    resp.set("Content-Type", "application/json")
    store.getSlideEvents(
      req.params.provider,
      req.params.id,
      (err, result) ->
        if error?
          resp.write("{error: 'An error ocurred'}")
        else
          resp.write(JSON.stringify(result))
        resp.end()))

################################################################################

app = server.listen(config.PORT)
pubsub.attach(app)

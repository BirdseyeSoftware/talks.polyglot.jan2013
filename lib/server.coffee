{server} = require "./server.core"
{getAuthenticatedUsers} = require "./server.storage"
pubsub = require "./server.pubsub"
require "./server.passport"
config = require "./server.config"

################################################################################

server.get('/',
  (req, resp) ->
    resp.redirect("/slideshow/")
    resp.end())

server.get('/login/',
  (req, resp) ->
    if req.user?
      resp.redirect("/slideshow/")
      resp.end()
    else
      resp.sendfile("assets/login.html", {}, (err) -> console.log(err))
    null)

server.get('/slideshow/',
  (req, resp) ->
    if req.user?
      resp.sendfile("build/slides.html")
    else
      resp.redirect("/login/")
      resp.end()
    null)

server.get("/loggedInUsers",
  (req, resp) ->
    resp.set("Content-Type", "application/json")
    getAuthenticatedUsers((err, result) ->
      resp.write(JSON.stringify(result))
      resp.end()))

################################################################################

app = server.listen(config.PORT)
pubsub.attach(app)

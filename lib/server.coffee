_ = require "underscore"
Rx = require "rx"
Faye = require "faye"
express = require "express"
Redis = require "redis"
RedisStore = require("connect-redis")(express)

####################

Pass = require "passport"
TwitterStrategy = require("passport-twitter").Strategy
GithubStrategy = require("passport-github").Strategy
FacebookStrategy = require("passport-facebook").Strategy
MeetupStrategy = require("passport-meetup").Strategy
GoogleStrategy = require("passport-google-oauth").Strategy

####################

CHANNEL = require "./channel_names"

################################################################################

redisClient = Redis.createClient()

################################################################################
## Faye Config

faye = new Faye.NodeAdapter(mount: "/faye", timeout: 45)
publish = (args...) -> faye.getClient().publish(args...)

faye.asObservable = (event_type) ->
  subj = new Rx.Subject()
  subj.callback = (params...) -> subj.onNext(params)
  faye.bind(event_type, subj.callback)
  subj

faye.asObservable('publish').subscribe(
  ([clientId, channel, data]) ->
    console.log("publish", clientId, channel, data)
    if data == 123
      faye.getClient().publish("/foo", 456))

faye.asObservable('subscribe').subscribe(
  ([clientId, channel]) ->
    console.log("subscribe", clientId, channel))

faye.asObservable('handshake').subscribe(
  (clientId) ->
    console.log("handshake", clientId))

################################################################################
## Passport Config

Pass.serializeUser((user, done) ->
  done(null, JSON.stringify(user)))
Pass.deserializeUser((user, done) ->
  user = JSON.parse(user)
  if user
    done(null, user)
  else
    done(new Error("Corrupted session"), null))

Pass.use(
  new TwitterStrategy(
    consumerKey: "UwqwbKAgfcPX4cbCX5dXw",
    consumerSecret: "ulIQ0HAGc1MwCsEraPfaTmJ97BKOMcB1vNRPgoVLOMc",
    callbackURL: "http://127.0.0.1:8000/auth/twitter/callback",
    (token, tokenSecret, profile, done) ->
        done(null, profile)))

Pass.use(
  new FacebookStrategy(
    clientID: "331933636921369",
    clientSecret: "3af8e3b8ff3b20d3043ac7f60765b385",
    callbackURL:  "http://127.0.0.1:8000/auth/facebook/callback",
    (accessToken, refreshToken, profile, done) ->
      done(null, profile)))

Pass.use(
  new GithubStrategy(
    clientID: "264b30622a456bcf9a3e",
    clientSecret: "9acca4041260868f11e45639ac92c987a3d44433",
    callbackURL: "http://127.0.0.1:8000/auth/github/callback",
    (accessToken, refreshToken, profile, done) ->
        done(null, profile)))

Pass.use(
  new MeetupStrategy(
    consumerKey: "4cbrkutic5tpsv066fofjg9oir",
    consumerSecret: "71iohigpn844p24n3qsdmmfsoa",
    callbackURL: "http://127.0.0.1:8000/auth/meetup/callback",
    (accessToken, tokenSecret, profile, done) ->
        done(null, profile)))

Pass.use(
  new MeetupStrategy(
    consumerKey: "4cbrkutic5tpsv066fofjg9oir",
    consumerSecret: "71iohigpn844p24n3qsdmmfsoa",
    callbackURL: "http://127.0.0.1:8000/auth/meetup/callback",
    (accessToken, tokenSecret, profile, done) ->
        done(null, profile)))

Pass.use(
  new GoogleStrategy(
    consumerKey: "659551111339.apps.googleusercontent.com",
    consumerSecret: "zn0JeIBkiMChw-oZGdNpGW1W",
    callbackURL: "http://127.0.0.1:8000/auth/google/callback",
    (accessToken, tokenSecret, profile, done) ->
        done(null, profile)))

################################################################################
## Express Config

server = express()

server.configure(->
  server.use(express.static(__dirname + '/../assets'))
  server.use(express.static(__dirname + '/../build'))

  server.use(express.cookieParser())
  server.use(express.bodyParser())
  server.use(express.session(
    store: new RedisStore(client: redisClient)
    secret: "ABCDEFGHJIK",
    ))

  server.use(Pass.initialize())
  server.use(Pass.session())

  console.log("express server ready"))

####################
## Routes

_slideshowRedirect = (service, req, resp) ->
  publish(CHANNEL.clientAuthenticated,
    provider: service,
    displayName: req.user.displayName,
    username: req.user.username,
    id: req.user.id)
  resp.cookie('fayAuthToken', req.sessionID, maxAge: 90000, httpOnly: false)
  resp.redirect("/slideshow/")
  resp.end()
  null

slideshowRedirect = (service) ->
  _.bind(_slideshowRedirect, _slideshowRedirect, service)

## TWITTER

server.get(
  '/auth/twitter',
  Pass.authenticate('twitter'))

server.get(
  '/auth/twitter/callback',
  Pass.authenticate('twitter', failureRedirect: '/login/'),
  slideshowRedirect("twitter"))

## FACEBOOK

server.get(
  '/auth/facebook',
  Pass.authenticate('facebook'))

server.get(
  '/auth/facebook/callback',
  Pass.authenticate('facebook', failureRedirect: '/login/'),
  slideshowRedirect("facebook"))

## MEETUP

server.get(
  '/auth/meetup',
  Pass.authenticate('meetup'))

server.get(
  '/auth/meetup/callback',
  Pass.authenticate('meetup', failureRedirect: '/login/'),
  slideshowRedirect("meetup"))

## GOOGLE

server.get(
  '/auth/google',
  Pass.authenticate('google', scope: 'https://www.google.com/m8/feeds'))

server.get(
  '/auth/google/callback',
  Pass.authenticate('google', failureRedirect: '/login/'),
  slideshowRedirect("google"))

## GITHUB

server.get(
  '/auth/github',
  Pass.authenticate('github'))

server.get(
  '/auth/github/callback',
  Pass.authenticate('github', failureRedirect: '/login/'),
  slideshowRedirect("github"))

################################################################################

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

app = server.listen(8080)
faye.attach(app)

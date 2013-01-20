express = require "express"
Faye = require "faye"
Rx = require "rx"
Pass = require "passport"
TwitterStrategy = require("passport-twitter").Strategy
GithubStrategy = require("passport-github").Strategy
FacebookStrategy = require("passport-facebook").Strategy
MeetupStrategy = require("passport-meetup").Strategy
GoogleStrategy = require("passport-google-oauth").Strategy

## Faye Config

faye = new Faye.NodeAdapter(mount: "/faye", timeout: 45)

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

## Passport Config

Pass.serializeUser((user, done) -> done(null, user.id))
Pass.deserializeUser((id, done) -> done(id))

Pass.use(
  new TwitterStrategy(
    consumerKey: "UwqwbKAgfcPX4cbCX5dXw",
    consumerSecret: "ulIQ0HAGc1MwCsEraPfaTmJ97BKOMcB1vNRPgoVLOMc",
    callbackURL: "http://127.0.0.1:8000/auth/twitter/callback",
    (token, tokenSecret, profile, done) ->
        console.log("Authenticated via twitter: ", profile)
        done(profile.displayName)))

Pass.use(
  new FacebookStrategy(
    clientID: "331933636921369",
    clientSecret: "3af8e3b8ff3b20d3043ac7f60765b385",
    callbackURL:  "http://127.0.0.1:8000/auth/facebook/callback",
    (accessToken, refreshToken, profile, done) ->
      console.log("Authenticated via facebook:", profile)
      done(profile)))

Pass.use(
  new GithubStrategy(
    clientID: "264b30622a456bcf9a3e",
    clientSecret: "9acca4041260868f11e45639ac92c987a3d44433",
    callbackURL: "http://127.0.0.1:8000/auth/github/callback",
    (accessToken, refreshToken, profile, done) ->
        console.log("Authenticated via github:", profile)
        done(profile.displayName)))

Pass.use(
  new MeetupStrategy(
    consumerKey: "4cbrkutic5tpsv066fofjg9oir",
    consumerSecret: "71iohigpn844p24n3qsdmmfsoa",
    callbackURL: "http://127.0.0.1:8000/auth/meetup/callback",
    (accessToken, tokenSecret, profile, done) ->
        console.log("Authenticated via meetup:", profile)
        done(profile.displayName)))

Pass.use(
  new MeetupStrategy(
    consumerKey: "4cbrkutic5tpsv066fofjg9oir",
    consumerSecret: "71iohigpn844p24n3qsdmmfsoa",
    callbackURL: "http://127.0.0.1:8000/auth/meetup/callback",
    (accessToken, tokenSecret, profile, done) ->
        console.log("Authenticated via meetup:", profile)
        done(profile.displayName)))

Pass.use(
  new GoogleStrategy(
    consumerKey: "659551111339.apps.googleusercontent.com",
    consumerSecret: "zn0JeIBkiMChw-oZGdNpGW1W",
    callbackURL: "http://127.0.0.1:8000/auth/google/callback",
    (accessToken, tokenSecret, profile, done) ->
        console.log("Authenticated via google:", profile)
        done(profile.displayName)))

## Express Config

server = express()

server.configure(->
  server.use(express.static(__dirname + '/../assets'))
  server.use(express.static(__dirname + '/../build'))

  server.use(express.cookieParser())
  server.use(express.bodyParser())
  server.use(express.cookieSession(secret: "ABCDEFGHJIK"))

  server.use(Pass.initialize())
  server.use(Pass.session())
  console.log("express server ready"))

####################

server.get(
  '/auth/twitter',
  Pass.authenticate('twitter'))

server.get(
  '/auth/twitter/callback',
  Pass.authenticate('twitter', failureRedirect: '/login'),
  (req, resp) ->
    res.write("Authenticated Successfuly with Twitter")
    null)

server.get(
  '/auth/facebook',
  Pass.authenticate('facebook'))

server.get(
  '/auth/facebook/callback',
  Pass.authenticate('facebook', failureRedirect: '/login'),
  (req, resp) ->
    res.write("Authenticated Successfuly with Facebook")
    null)

server.get(
  '/auth/meetup',
  Pass.authenticate('meetup'))

server.get(
  '/auth/meetup/callback',
  Pass.authenticate('meetup', failureRedirect: '/login'),
  (req, resp) ->
    res.write("Authenticated Successfuly with Meetup")
    null)

server.get(
  '/auth/google',
  Pass.authenticate('google', scope: 'https://www.google.com/m8/feeds'))

server.get(
  '/auth/google/callback',
  Pass.authenticate('google', failureRedirect: '/login'),
  (req, resp) ->
    res.write("Authenticated Successfuly with Google")
    null)

server.get(
  '/auth/github',
  Pass.authenticate('github'))

server.get(
  '/auth/github/callback',
  Pass.authenticate('github', failureRedirect: '/login'),
  (req, resp) ->
    res.write("Authenticated Successfuly with Github")
    null)

####################

app = server.listen(8000)
faye.attach(app)

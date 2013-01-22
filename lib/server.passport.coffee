_ = require "underscore"
passport  = require "passport"
TwitterStrategy = require("passport-twitter").Strategy
GithubStrategy = require("passport-github").Strategy
MeetupStrategy = require("passport-meetup").Strategy
GoogleStrategy = require("passport-google-oauth").Strategy

config = require "./server.config"
{server} = require "./server.core"
{publish} = require "./server.pubsub"
channels = require "./channel_names"

callback_url_prefix = "http://#{config.HTTP_HOST}:#{config.PORT}/"
################################################################################

passport.serializeUser((user, done) ->
  done(null, JSON.stringify(user)))

passport.deserializeUser((user, done) ->
  user = JSON.parse(user)
  if user
    done(null, user)
  else
    done(new Error("Corrupted session"), null))

################################################################################

passport.use(
  new TwitterStrategy(
    consumerKey: "UwqwbKAgfcPX4cbCX5dXw",
    consumerSecret: "ulIQ0HAGc1MwCsEraPfaTmJ97BKOMcB1vNRPgoVLOMc",
    callbackURL: "#{callback_url_prefix}auth/twitter/callback",
    (token, tokenSecret, profile, done) ->
      done(null, profile)))

passport.use(
  new GithubStrategy(
    clientID: "264b30622a456bcf9a3e",
    clientSecret: "9acca4041260868f11e45639ac92c987a3d44433",
    callbackURL: "#{callback_url_prefix}auth/github/callback",
    (accessToken, refreshToken, profile, done) ->
      done(null, profile)))

passport.use(
  new MeetupStrategy(
    consumerKey: "4cbrkutic5tpsv066fofjg9oir",
    consumerSecret: "71iohigpn844p24n3qsdmmfsoa",
    callbackURL: "#{callback_url_prefix}auth/meetup/callback",
    (accessToken, tokenSecret, profile, done) ->
      done(null, profile)))

passport.use(
  new MeetupStrategy(
    consumerKey: "4cbrkutic5tpsv066fofjg9oir",
    consumerSecret: "71iohigpn844p24n3qsdmmfsoa",
    callbackURL: "#{callback_url_prefix}auth/meetup/callback",
    (accessToken, tokenSecret, profile, done) ->
      done(null, profile)))

passport.use(
  new GoogleStrategy(
    consumerKey: "659551111339.apps.googleusercontent.com",
    consumerSecret: "zn0JeIBkiMChw-oZGdNpGW1W",
    callbackURL: "#{callback_url_prefix}auth/google/callback",
    (accessToken, tokenSecret, profile, done) ->
      done(null, profile)))

################################################################################

_slideshowRedirect = (service, req, resp) ->
  user =
    provider: service,
    displayName: req.user.displayName,
    username: req.user.username,
    id: req.user.id
  publish(channels.clientAuthenticated, user)

  userSession =
    token: req.sessionID
    user: user
  resp.cookie('userSession', JSON.stringify(userSession), {maxAge: 900000, secret: false})
  resp.redirect("/slideshow/")

slideshowRedirect = (service) ->
  _.bind(_slideshowRedirect, _slideshowRedirect, service)

## TWITTER

server.get(
  '/auth/twitter',
  passport.authenticate('twitter'))

server.get(
  '/auth/twitter/callback',
  passport.authenticate('twitter', failureRedirect: '/login/'),
  slideshowRedirect("twitter"))

## MEETUP

server.get(
  '/auth/meetup',
  passport.authenticate('meetup'))

server.get(
  '/auth/meetup/callback',
  passport.authenticate('meetup', failureRedirect: '/login/'),
  slideshowRedirect("meetup"))

## GOOGLE

server.get(
  '/auth/google',
  passport.authenticate('google', scope: 'https://www.google.com/m8/feeds'))

server.get(
  '/auth/google/callback',
  passport.authenticate('google', failureRedirect: '/login/'),
  slideshowRedirect("google"))

## GITHUB

server.get(
  '/auth/github',
  passport.authenticate('github'))

server.get(
  '/auth/github/callback',
  passport.authenticate('github', failureRedirect: '/login/'),
  slideshowRedirect("github"))

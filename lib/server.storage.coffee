{getUserKey} = require "./utils"
redis = require "redis"
channels = require "./channel_names"
{subscribe} = require "./server.pubsub"

APP_NS = "polyglot"
_redisClient = redis.createClient()

################################################################################

exports.createSessionStore = (express) ->
  RedisStore = require("connect-redis")(express)
  new RedisStore(client: _redisClient)

exports.getAuthenticatedUsers = (callback) ->
  _redisClient.smembers("#{APP_NS}:authenticated_users", callback)

exports.getSlideEvents = (provider, user_id, callback) ->
  # 1000 is an arbitrary number here
  _redisClient.lrange("#{APP_NS}:#{provider}:#{user_id}:slide_events", 0, 1000, callback)

################################################################################

storeAuthenticatedUserOnRedis = (user) ->
  userKey = getUserKey(user)
  _redisClient.sadd("#{APP_NS}:authenticated_users", userKey)
  _redisClient.set("#{APP_NS}:#{userKey}:properties", JSON.stringify(user))

storeUserSlideEventsOnRedis = (user) ->
  userKey = getUserKey(user)
  (slideEvent) ->
    _redisClient.lpush("#{APP_NS}:#{userKey}:slide_events", JSON.stringify(slideEvent))

registerToUserSlideEvent = (user) ->
  userKey  = getUserKey(user, "/")
  subscribe("#{channels.slideEvents}/#{userKey}", storeUserSlideEventsOnRedis(user))

subscribe(channels.clientAuthenticated, storeAuthenticatedUserOnRedis)
subscribe(channels.clientAuthenticated, registerToUserSlideEvent)

################################################################################

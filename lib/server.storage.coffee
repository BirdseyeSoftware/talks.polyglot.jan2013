{getUserKey} = require "./utils"
redis = require "redis"
channels = require "./channel_names"
{subscribe, publish} = require "./server.pubsub"

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
  _redisClient.lrange("#{APP_NS}:#{provider}:slide_events:#{user_id}", 0, 1000, callback)

################################################################################

storeAuthenticatedUserOnRedis = (user) ->
  userKey = getUserKey(user)
  _redisClient.sadd("#{APP_NS}:authenticated_users", userKey)
  _redisClient.set("#{APP_NS}:properties:#{userKey}", JSON.stringify(user))

mkUserSlideEventConsumerForRedis = (user) ->
  userKey = getUserKey(user)
  (stateChangedEvent) ->
    _redisClient.lpush("#{APP_NS}:slide_events:#{userKey}", JSON.stringify(stateChangedEvent))
    if stateChangedEvent.event.type == "AskQuestion"
      _redisClient.sadd("#{APP_NS}:questions:#{stateChangedEvent.event.slideId}", userKey)

subscribeToUserSlideEvents = (user) ->
  subscribe(channels.getUserEventChannelName(user), mkUserSlideEventConsumerForRedis(user))

subscribe(channels.clientAuthenticated, storeAuthenticatedUserOnRedis)
subscribe(channels.clientAuthenticated, subscribeToUserSlideEvents)

publishEventsFromPresenterToSlaves = (stateChange) ->
  console.log("presenter state change: ", stateChange)
  publish(channels.slaveEvents, stateChange)

PRESENTER_USER = {id: "236886", provider: "github"}
do ->
  subscribe(channels.getUserEventChannelName(PRESENTER_USER), publishEventsFromPresenterToSlaves)

################################################################################

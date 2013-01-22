redis = require "redis"
channels = require "./channel_names"
{subscribe} = require "./server.pubsub"

_redisClient = redis.createClient()

exports.createSessionStore = (express) ->
  RedisStore = require("connect-redis")(express)
  new RedisStore(client: _redisClient)

exports.getAuthenticatedUsers = (callback) ->
  _redisClient.smembers("authenticatedUsers", callback)

subscribe(channels.clientAuthenticated, (user) ->
  userKey = JSON.stringify([user.provider, user.id])
  _redisClient.sadd("authenticatedUsers", userKey)
  _redisClient.set("#{userKey}:properties", JSON.stringify(user)))

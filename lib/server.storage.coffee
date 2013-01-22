_ = require "underscore"
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

exports.getSlideEvents = (user, callback) ->
  # 1000 is an arbitrary number here
  userKey = getUserKey(user)
  _redisClient.lrange("#{APP_NS}:slide_events:#{userKey}", 0, 1000, callback)

# FUGLY!!!
exports.getAllSlideQuestions = (callback) ->
  partial_results = []
  _redisClient.keys("#{APP_NS}:questions:*", (err, slides) ->
      if err
        callback(err, null)
      else
        multi = _redisClient.multi()
        partial_results = for slide in slides
          # execute the subcommand
          multi.smembers(slide)

          # create the result entry
          partial_result = {}
          slideId = slide.match(/.+:.+:(.+)/)[1]
          partial_result.id = slideId
          partial_result

      multi.exec((err, replies) ->
        if err
          callback(err, null)
        else
          results = _.reduce(replies, ((acc, reply, index) ->
            partial_result = partial_results[index]
            result = {}
            result[partial_result.id] = reply
            _.extend(acc, result)), {})
          callback(null, results)))

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

PRESENTER_USER = {id: 236886, provider: "github"}
do ->
  subscribe(channels.getUserEventChannelName(PRESENTER_USER), publishEventsFromPresenterToSlaves)

getCurrentPresenterSlide = (callback) ->
  userKey = getUserKey(PRESENTER_USER)
  _redisClient.lindex("#{APP_NS}:slide_events:#{userKey}", 1, (err, record) ->
    if err
      callback(err, null)
    else
      callback(null, JSON.parse(record).newState.slide))
exports.getCurrentPresenterSlide = getCurrentPresenterSlide
################################################################################

streams = require "./app.streams"
channelNames = require "./channel_names"
utils = require "./utils"
auth = require "./app.auth"

exports.fayeClient = fayeClient = new Faye.Client("/faye")
exports.isMe = isMe = (clientId) -> fayeClient.getClientId() == clientId

CURRENT_USER_CHANNEL = channelNames.getUserEventChannelName(auth.getCurrentUser())
exports.CURRENT_USER_CHANNEL = CURRENT_USER_CHANNEL
exports.publishSlideStateChange = (stateChange) ->
  stateChange.user = user = auth.getCurrentUser()
  stateChange.userAgent = navigator.userAgent
  stateChange.fayeCid = fayeClient.getClientId()
  fayeClient.publish(CURRENT_USER_CHANNEL, stateChange)

exports.log = (msg) ->
  fayeClient.publish('/debug',
    [fayeClient.getClientId(), msg, navigator.userAgent])

exports.listenToRemoteDebug = (subscribers...) ->
  fayeClient.subscribe channelNames.debugEvents, ([cid, ev])->
    if not isMe(cid)
      streams.remoteDebugEventstream.onNext(ev)

  if subscribers
    utils.teeSubscribe(streams.remoteDebugEventstream, subscribers...)

# init user remote channel subscription
do ->
  fayeClient.subscribe CURRENT_USER_CHANNEL, (stateChange)->
    if not isMe(stateChange.fayeCid)
      streams.remoteUserSlideStateChangeStream.onNext(stateChange)

# init slave remote channel subscription
do ->
  fayeClient.subscribe channelNames.slaveEvents, (stateChange)->
    if not isMe(stateChange.fayeCid)
      streams.remoteSlaveSlideStateChangeStream.onNext(stateChange)

PRESENTER_ID = 236886
# a little hack so we can push urls to the audience
# PLEASE DON'T BE A DICK AND ABUSE THIS DURING THE PRESENTATION
fayeClient.subscribe('/url', (url) ->
  console.log(url)
  if auth.getCurrentUser().id != PRESENTER_ID
    window.open(url, 'tmp'))

exports.pushUrl = (url) ->
  fayeClient.publish('/url_submit', {user: auth.getCurrentUser(), url: url})

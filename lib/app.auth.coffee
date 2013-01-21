getAuthenticationCookie = ->
  JSON.parse(decodeURIComponent($.macaroon("userSession")))

exports.getAuthToken = ->
  getAuthenticationCookie()['token']

exports.getCurrentUser = ->
  getAuthenticationCookie()['user']
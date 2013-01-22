getAuthenticationCookie = ->
  JSON.parse(decodeURIComponent($.macaroon("userSession")))

exports.getAuthToken = ->
  getAuthenticationCookie()['token']

exports.getCurrentUser = ->
  try
    {user, token} = getAuthenticationCookie()
    user.token = token
    user
  catch err
    console?.exception?(err)

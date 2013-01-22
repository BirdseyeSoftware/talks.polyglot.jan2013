getAuthenticationCookie = ->
  JSON.parse(decodeURIComponent($.macaroon("userSession")))

# exports.getAuthToken = ->
#   getAuthenticationCookie()['token']

TEST_USER = {user: {provider: 'test', id:'test'}, token: 'test'}
exports.getCurrentUser = ->
  try
    {user, token} = getAuthenticationCookie()
    user.token = token
    user
  catch err
    console?.log?("no user found, using test user")
    console?.exception?(err) or console?.error?(err)
    TEST_USER

exports.login = ->
  username = prompt("Username:")
  $.macaroon("currentUser", username)
  username

exports.logout = ->
  $.macaroon("currentUser", null)

exports.getCurrentUser = ->
  $.macaroon("currentUser") ||
  exports.login()

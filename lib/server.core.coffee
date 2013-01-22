express  = require "express"
passport = require "passport"
storage  = require "./server.storage"

exports.server = server = express()

server.configure(->
  server.use(express.static(__dirname + '/../assets'))
  server.use(express.static(__dirname + '/../build'))

  server.use(express.cookieParser())
  server.use(express.bodyParser())
  server.use(express.session(
    store: storage.createSessionStore(express)
    secret: "ABCDEFGHJIK"))

  server.use(passport.initialize())
  server.use(passport.session())

  console.log("express server ready"))

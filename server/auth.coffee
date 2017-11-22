auth = require 'http-auth'
config = require '../config'

basic = auth.basic { realm: 'BookIT' }, (username, password, cb) ->
  cb password.toLowerCase() is config.password

module.exports = (app) ->
  app.use auth.connect basic

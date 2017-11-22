auth = require 'http-auth'

basic = auth.basic { realm: 'BookIT' }, (username, password, cb) ->
  cb password.toLowerCase() is 'sadie'

module.exports = (app) ->
  app.use auth.connect basic

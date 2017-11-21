module.exports = (app) ->
  path = require 'path'
  express = require 'express'
  oneDay = 1000 * 60 * 60 * 24
  app.use '/dist', [express.static path.join(__dirname, '../', 'dist'), maxAge: oneDay]

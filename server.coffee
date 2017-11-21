whakaruru = require 'whakaruru/verbose'
whakaruru ->
  express = require 'express'
  app = express()
  mutunga = require 'http-mutunga'
  httpServer = mutunga app
  compression = require 'compression'
  app.use compression()
  bodyParser = require 'body-parser'
  app.use bodyParser.urlencoded
    limit: '50mb'
    extended: yes
  app.use bodyParser.json
    limit: '50mb'
  app.set 'json spaces', 2

  pods = [
    require './server/static'
    require './server/query'
    require './book/server'
    require './server/root'
  ]

  pod app, httpServer for pod in pods

  pjson = require './package.json'
  port = 8080
  httpServer.listen port, ->
    host = httpServer.address().address
    boundport = httpServer.address().port
    shutdown = ->
      console.log "#{pjson.name}@#{pjson.version} ōhākī waiting for requests to finish"
      httpServer.close ->
        console.log "#{pjson.name}@#{pjson.version} e noho rā!"
        process.exit 0
    process.on 'SIGTERM', shutdown
    process.on 'SIGINT', shutdown

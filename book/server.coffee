fs = require 'fs'
baby = require 'babyparse'
moment = require 'moment-timezone'
chrono = require 'chronological'
moment = chrono moment
simpledate = 'YYYY-MM-DD'

buildtimeline = require './buildtimeline'

islocked = no
callbacks = []

lock = (cb) ->
  if islocked
    callbacks.push cb
    return
  islocked = yes
  callbacks = []
  cb()

release = (cb) ->
  return cb() if !islocked
  islocked = yes
  _callbacks = callbacks
  callbacks = []
  cb()
  callback() for callback in _callbacks

readbookings = (cb) ->
  fs.readFile './data/bookings.csv', 'utf-8', (err, data) ->
    return cb err if err?
    rows = baby.parse data,
      header: yes
      skipEmptyLines: yes
    res = {}
    res[r.id] = r for r in rows.data
    cb null, res

module.exports = (app) ->
  # app.post '/update', (req, res) ->
  #   return res.send 'processing' if isprocessing
  #   isprocessing = yes
  #   loaddata ->
  #     processdata ->
  #       isprocessing = no
  #       res.send 'ok'

module.exports.query = (req, store) ->
  store.use 'bookings', (params, cb) ->
    readbookings (err, events) ->
      return cb err if err?
      timeline = buildtimeline events
      cb null,
        events: events
        timeline: timeline

fs = require 'fs'
baby = require 'babyparse'
shortid = require 'shortid'
moment = require 'moment-timezone'
chrono = require 'chronological'
moment = chrono moment
simpledate = 'YYYY-MM-DD'

buildtimeline = require './buildtimeline'

islocked = no
callbacks = []

readbookings = (cb) ->
  fs.readFile './data/bookings.csv', 'utf-8', (err, data) ->
    return cb err if err?
    rows = baby.parse data,
      header: yes
      skipEmptyLines: yes
    res = {}
    res[r.id] = r for r in rows.data
    cb null, res

writebookings = (events, cb) ->
  events = Object.keys(events).map (id) -> events[id]
  fs.writeFile './data/bookings.csv', baby.unparse(events), cb

module.exports = (app) ->
  app.post '/v0/addbooking', (req, res) ->
    readbookings (err, events) ->
      id = shortid.generate()
      events[id] =
        id: id
        name: req.body.name
        start: req.body.start
        end: req.body.end
      writebookings events, (err) ->
        if err?
          if err.stack?
            console.error err.stack
          else
            console.error err
          return res.status(500).send(err)
        res.send id: id

  app.post '/v0/deletebooking', (req, res) ->
    readbookings (err, events) ->
      delete events[req.body.id]
      writebookings events, (err) ->
        if err?
          if err.stack?
            console.error err.stack
          else
            console.error err
          return res.status(500).send(err)
        res.send id: id

  app.post '/v0/changebooking', (req, res) ->
    readbookings (err, events) ->
      if !events[req.body.id]?
        return res.status(400).send('Booking not found')
      booking = events[req.body.id]
      booking.name = req.body.name
      booking.start = req.body.start
      booking.end = req.body.end
      writebookings events, (err) ->
        if err?
          if err.stack?
            console.error err.stack
          else
            console.error err
          return res.status(500).send(err)
        res.send id: booking.id

module.exports.query = (req, store) ->
  store.use 'bookings', (params, cb) ->
    readbookings (err, events) ->
      return cb err if err?
      timeline = buildtimeline events
      cb null,
        events: events
        timeline: timeline

fs = require 'fs'
baby = require 'babyparse'
shortid = require 'shortid'
moment = require 'moment-timezone'
chrono = require 'chronological'
moment = chrono moment
simpledate = 'YYYY-MM-DD'

buildtimeline = require './buildtimeline'
ical = require 'ical-generator'
config = require '../config'

readbookings = (cb) ->
  fs.readFile './data/bookings.csv', 'utf-8', (err, data) ->
    return cb err if err?
    rows = baby.parse data,
      header: yes
      skipEmptyLines: yes
    res = {}
    for r in rows.data
      if r.tags? and r.tags.trim() isnt ''
        tags = {}
        tags[t] = yes for t in r.tags.split ','
        r.tags = tags
      else
        r.tags = {}
      res[r.id] = r
    cb null, res

writebookings = (events, cb) ->
  events = Object.keys(events).map (id) -> events[id]
  for e in events
    if e.tags?
      e.tags = Object.keys(e.tags).join ','
    else
      e.tags = null
  cal = ical
    domain: config.domain
    name: config.title
    timezone: config.timezone
    prodId:
      company: config.company
      product: config.product
  cal.events events.map (e) ->
    start: moment(e.start).add(14, 'h').toDate()
    end: moment(e.end).add(10, 'h').toDate()
    summary: e.name
  cal.save './data/bookings.ics', (err) ->
    return cb err if err?
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
        tags: req.body.tags
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
        res.send id: req.body.id

  app.post '/v0/changebooking', (req, res) ->
    readbookings (err, events) ->
      if !events[req.body.id]?
        return res.status(400).send('Booking not found')
      booking = events[req.body.id]
      booking.name = req.body.name
      booking.start = req.body.start
      booking.end = req.body.end
      booking.tags = req.body.tags
      writebookings events, (err) ->
        if err?
          if err.stack?
            console.error err.stack
          else
            console.error err
          return res.status(500).send(err)
        res.send id: req.body.id

module.exports.query = (req, store) ->
  store.use 'bookings', (params, cb) ->
    readbookings (err, events) ->
      return cb err if err?
      timeline = buildtimeline events
      cb null,
        events: events
        timeline: timeline

  store.use 'config', (params, cb) ->
    cb null, config

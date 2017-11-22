{ component, hub, dom } = require 'odojs'
inject = require 'injectinto'
moment = require 'moment-timezone'
chrono = require 'chronological'
moment = chrono moment
astro = require './astro'
route = require 'odo-route'
odoql = require 'odoql/odojs'
page = require 'page'
request = require 'superagent'
component.use odoql

ql = require 'odoql'
ql = ql
  .use 'store'
  .use params: localstore: yes

get = (key) ->
  try
    return JSON.parse localStorage.getItem key
  catch
    return null
set = (key, value) -> localStorage.setItem key, JSON.stringify value

nicedate = 'dddd D MMMM YYYY'
shortdate = 'ddd D MMMM'
simpledate = 'YYYY-MM-DD'

require './add'
require './view'

module.exports = (hub, scene, localstore) ->
  hub.every 'select date', (p, cb) ->
    cb()
    set 'selectedDate', p
    scene.refreshQueries ['selectedDate']
    hub.emit 'update'
  localstore.use 'selectedDate', (params, cb) ->
    cb null, get 'selectedDate'

  hub.every 'add booking', (p, cb) ->
    payload =
      name: p.name
      start: moment(p.start).format simpledate
      end: moment(p.end).format simpledate
    request
      .post '/v0/addbooking'
      .send payload
      .end (err, res) ->
        if err?
          alert err
          return
        unless res.ok
          alert res.text
          return
        scene.refreshQueries ['bookings']
        page '/'

  hub.every 'delete booking', (p, cb) ->
    request
      .post '/v0/deletebooking'
      .send { id: p.id }
      .end (err, res) ->
        if err?
          alert err
          return
        unless res.ok
          alert res.text
          return
        scene.refreshQueries ['bookings']
        page '/'

  hub.every 'change booking', (p, cb) ->
    payload =
      id: p.id
      name: p.name
      start: moment(p.start).format simpledate
      end: moment(p.end).format simpledate
    request
      .post '/v0/changebooking'
      .send payload
      .end (err, res) ->
        if err?
          alert err
          return
        unless res.ok
          alert res.text
          return
        scene.refreshQueries ['bookings']
        page '/'

route '/', (p) -> page: 'list'

res = component
  query: (state, params) ->
    bookings: ql.store 'bookings'
    selectedDate: ql.localstore 'selectedDate'
    config: ql.store 'config'
  render: (state, params, hub) ->
    today = moment().startOf 'd'
    childparams =
      selectedDate: state?.selectedDate ? today.format simpledate
    date = moment childparams.selectedDate
    ids = state.bookings.timeline[childparams.selectedDate]?.ids ? []
    dom '.grid.main', [
      dom '.scroll.right', [
        dom 'h1', state.config.title
        astro state, childparams, hub.child
          select: (p, cb) ->
            cb()
            hub.emit 'select date', p.format simpledate
      ]
      dom '.scroll', [
        dom 'h2', date.format nicedate
        dom '.bookings', ids.map (id) ->
          e = state.bookings.events[id]
          bookingstart = moment(e.start)
          bookingend = moment(e.end)
          dom 'a.booking', { attributes: href: "/booking/#{e.id}" }, [
            dom '.booking-title', [
              e.name
              if date.isSame bookingstart
                if bookingstart.isSame bookingend
                  ' visiting'
                else
                  ' arriving'
              else if date.isSame bookingend
                ' leaving'
              else
                ' staying'
            ]
            dom '.booking-dates', "#{bookingstart.format shortdate} — #{bookingend.format shortdate}"
          ]
        dom '.actions', dom 'a.action', { attributes: href: "/addbooking/#{childparams.selectedDate}/#{date.clone().add(2, 'd').format simpledate}/"}, '＋  Add Booking'
      ]
    ]

inject.bind 'page:list', res
inject.bind 'page:default', res

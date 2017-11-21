{ component, hub, dom } = require 'odojs'
inject = require 'injectinto'
moment = require 'moment-timezone'
chrono = require 'chronological'
moment = chrono moment
astro = require './astro'
route = require 'odo-route'
odoql = require 'odoql/odojs'
component.use odoql
buildtimeline = require './buildtimeline'
defaultnames = require './defaultnames'

ql = require 'odoql'
ql = ql
  .use 'store'

nicedate = 'dddd D MMMM YYYY'
shortdate = 'ddd D MMMM'
simpledate = 'YYYY-MM-DD'

route '/booking/:id', (p) ->
  page: 'view'
  id: p.params.id

inject.bind 'page:view', component
  query: (state, params) ->
    bookings: ql.store 'bookings'
  render: (state, params, hub) ->
    e = state.bookings.events[params.id]
    editing = params?.editing ? 'nothing'
    edited = params?.edited
    if edited?.id isnt params.id
      edited =
        id: e.id
        name: e.name
        start: moment e.start
        end: moment e.end
    childparams =
      selectedRange: { start: edited.start, end: edited.end }
    childstate =
      bookings:
        events: {}
        timeline: null
    for id, evt of state.bookings.events
      continue if id is params.id
      childstate.bookings.events[id] = evt
    childstate.bookings.timeline = buildtimeline childstate.bookings.events
    if editing is 'start'
      childparams.selectedDate = edited.start
    else if editing is 'end'
      childparams.selectedDate = edited.end
    haschanges = edited.name isnt e.name or !edited.start.isSame(moment(e.start)) or !edited.end.isSame(moment(e.end))
    toggle = (key) -> (e) ->
      e.preventDefault()
      value = key
      if editing is value
        value = 'nothing'
      hub.emit 'update', editing: value
    saveChanges = (e) ->
      e.preventDefault()
      hub.emit 'change booking', edited
    beginDeleteBooking = (e) ->
      e.preventDefault()
      hub.emit 'update', deleting: yes
    cancelDeleteBooking = (e) ->
      e.preventDefault()
      hub.emit 'update', deleting: null
    confirmDeleteBooking = (e) ->
      e.preventDefault()
      hub.emit 'delete booking', edited
    cancelChanges = (e) ->
      e.preventDefault()
      hub.emit 'update',
        edited: null
        editing: 'nothing'
    cancelRename = (e) ->
      e.preventDefault()
      hub.emit 'update', editing: 'nothing'
    keydown = (e) ->
      e.preventDefault() if e.which is 13
    keyup = (e) ->
      name = e.target.value
      name = name.replace(/[\r\n\v]+/g, '')
      e.target.value = name
      hub.emit 'update', name: name
    rename = (e) ->
      e.preventDefault()
      edited.name = params.name if params?.name?
      edited.name = edited.name.replace(/\s{2,}/g, ' ').trim()
      hub.emit 'update',
        edited: edited
        editing: 'nothing'
        name: null
    return dom '.grid.main', [
      dom '.scroll.right', astro childstate, childparams, hub.child
        select: (p, cb) ->
          cb()
          if editing is 'start'
            edited.start = p
            if edited.end.isBefore edited.start
              edited.end = edited.start
            hub.emit 'update',
              edited: edited
              editing: 'end'
          else if editing is 'end'
            edited.end = p
            if edited.start.isAfter edited.end
              edited.start = edited.end
            hub.emit 'update',
              edited: edited
              editing: 'nothing'
      dom '.scroll', [
        if params.deleting
          [
            dom 'h2', edited.name
            dom '.grid', [
              dom '.booking.selection', [
                dom '.booking-dates', [
                  dom 'small', 'ARRIVE'
                  ' ⋅ '
                  edited.start.format nicedate
                ]
              ]
              dom '.booking.selection', [
                dom '.booking-dates', [
                  dom 'small', 'LEAVE'
                  ' ⋅ '
                  edited.end.format nicedate
                ]
              ]
            ]
            dom '.actions', [
              dom 'a.action.danger', { onclick: confirmDeleteBooking, attributes: href: '#' }, '⌫  Delete'
              dom 'a.action', { onclick: cancelDeleteBooking, attributes: href: '#' }, '⤺  Cancel'
            ]
          ]
        else if editing is 'name'
          [
            dom 'textarea', { onkeydown: keydown, onkeyup: keyup, attributes: autofocus: 'autofocus', name: 'name', autocomplete: 'off', autocorrect: 'off', autocapitalize: 'on', spellcheck: 'false' }, edited.name
            dom 'ul.defaultnames', defaultnames.map (name) ->
              choosename = (e) ->
                e.preventDefault()
                edited.name = name
                hub.emit 'update',
                  edited: edited
                  editing: 'nothing'
                  name: null
              dom 'li', dom 'a', { onclick: choosename, attributes: href: '#' }, name
            dom '.actions', [
              dom 'a.action', { onclick: cancelRename, attributes: href: '#' }, '⤺  Cancel'
              if params?.name? and params.name.replace(/\s{2,}/g, ' ').trim() isnt edited.name
                dom 'a.action.primary', { onclick: rename, attributes: href: '#' }, '✓  Change'
            ]
          ]
        else
          [
            dom 'h2', dom 'a', { onclick: toggle('name'), attributes: href: '#' }, [
              edited.name
              dom 'small', 'CHANGE NAME'
            ]
            dom '.grid', [
              dom "a.booking.selection#{if editing is 'start' then '.selected' else ''}", { onclick: toggle('start'), attributes: href: '#' }, [
                dom '.booking-dates', [
                  dom 'small', 'ARRIVE'
                  ' ⋅ '
                  edited.start.format nicedate
                ]
              ]
              dom "a.booking.selection#{if editing is 'end' then '.selected' else ''}", { onclick: toggle('end'), attributes: href: '#' }, [
                dom '.booking-dates', [
                  dom 'small', 'LEAVE'
                  ' ⋅ '
                  edited.end.format nicedate
                ]
              ]
            ]
            if editing is 'start'
              dom 'h2', '← Select arrival date'
            else if editing is 'end'
              dom 'h2', '← Select leaving date'
            else if editing is 'nothing'
              dom '.actions', [
                if !haschanges
                  [
                    dom 'a.action', { onclick: beginDeleteBooking, attributes: href: '#' }, '⌫  Delete'
                    dom 'a.action', { attributes: href: '/' }, '✕  Close'
                  ]
                else
                  [
                    dom 'a.action', { onclick: cancelChanges, attributes: href: '#' }, '⤺  Cancel'
                    dom 'a.action.primary', { onclick: saveChanges, attributes: href: '#' }, '✓  Update'
                  ]
              ]
          ]
      ]
    ]

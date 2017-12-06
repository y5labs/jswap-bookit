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

ql = require 'odoql'
ql = ql
  .use 'store'

nicedate = 'dddd D MMMM YYYY'
shortdate = 'ddd D MMMM'
simpledate = 'YYYY-MM-DD'

route '/addbooking/:start/:end', (p) ->
  page: 'add'
  start: p.params.start
  end: p.params.end

inject.bind 'page:add', component
  query: (state, params) ->
    bookings: ql.store 'bookings'
    config: ql.store 'config'
  render: (state, params, hub) ->
    editing = params?.editing ? 'name'
    edited = params?.edited
    if !edited?
      edited =
        name: ''
        start: moment params.start
        end: moment params.end
        tags: {}
    childparams =
      selectedRange: { start: edited.start, end: edited.end }
    if editing is 'start'
      childparams.selectedDate = edited.start
    else if editing is 'end'
      childparams.selectedDate = edited.end
    toggle = (key) -> (e) ->
      e.preventDefault()
      value = key
      if editing is value
        value = 'nothing'
      hub.emit 'update', editing: value
    addBooking = (e) ->
      e.preventDefault()
      hub.emit 'add booking', edited
    cancelRename = (e) ->
      e.preventDefault()
      hub.emit 'update', editing: 'nothing'
    keydown = (e) ->
      e.preventDefault() if e.which is 13
    keyup = (e) ->
      name = e.target.value
      name = name.replace(/[\r\n\v]+/g, '')
      e.target.value = name
      hub.emit 'update',
        name: name
        edited: edited
    rename = (e) ->
      e.preventDefault()
      edited.name = params.name if params?.name?
      edited.name = edited.name.replace(/\s{2,}/g, ' ').trim()
      hub.emit 'update',
        edited: edited
        editing: 'start'
        name: null
    dom '.grid.main', [
      dom '.scroll.right', [
        dom 'h1', state.config.title
        astro state, childparams, hub.child
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
      ]
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
            dom 'textarea', { onkeydown: keydown, onkeyup: keyup, attributes: autofocus: 'autofocus', name: 'name', autocomplete: 'off', autocorrect: 'off', autocapitalize: 'on', spellcheck: 'false', placeholder: 'Enter name or select below…' }, edited.name
            dom 'ul.defaultnames', state.config.defaultnames.map (name) ->
              choosename = (e) ->
                e.preventDefault()
                edited.name = name
                hub.emit 'update',
                  edited: edited
                  editing: 'start'
                  name: null
              dom 'li', dom 'a', { onclick: choosename, attributes: href: '#' }, name
            dom '.actions', [
              dom 'a.action', { onclick: cancelRename, attributes: href: '#' }, '⤺  Cancel'
              if params?.name? and params.name.replace(/\s{2,}/g, ' ').trim() isnt edited.name
                dom 'a.action.primary', { onclick: rename, attributes: href: '#' }, '✓  Done'
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
              [
                dom 'h2', '← Select arrival date'
                dom '.actions', dom 'a.action', { onclick: toggle('end'), attributes: href: '#' }, 'Next  →'
              ]
            else if editing is 'end'
              [
                dom 'h2', '← Select leaving date'
                dom '.actions', dom 'a.action', { onclick: toggle('nothing'), attributes: href: '#' }, 'Next  →'
              ]
            else if editing is 'nothing'
              [
                dom 'h3', 'Select:'
                dom '.tagselection', ['upstairs', 'downstairs'].map (t) ->
                  toggletag = (e) ->
                    e.preventDefault()
                    if edited.tags[t]
                      delete edited.tags[t]
                    else
                      edited.tags[t] = yes
                    hub.emit 'update', edited: edited
                  if edited.tags[t]
                    dom 'a.tag.selected', { onclick: toggletag, attributes: href: '#' }, "✓  #{t}"
                  else
                    dom 'a.tag', { onclick: toggletag, attributes: href: '#' }, t
                dom '.actions', [
                  dom 'a.action', { attributes: href: '/' }, '⤺  Cancel'
                  dom 'a.action.primary', { onclick: addBooking, attributes: href: '#' }, '＋  Add booking'
                ]
              ]
          ]
      ]
    ]

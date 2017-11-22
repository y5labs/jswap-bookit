moment = require 'moment-timezone'
chrono = require 'chronological'
moment = chrono moment
simpledate = 'YYYY-MM-DD'

module.exports = (events) ->
  timeline = {}
  today = moment().startOf('d')
  for id, e of events
    for d in today.every(1, 'd').between moment(e.start).add(1, 's'), moment(e.end)
      date = d.format simpledate
      timeline[date] = { ids: {}} if !timeline[date]?
      timeline[date].isduring = yes
      timeline[date].ids[id] = yes
    timeline[e.start] = { ids: {}} if !timeline[e.start]?
    timeline[e.start].isstart = yes
    timeline[e.start].ids[id] = yes
    timeline[e.end] = { ids: {}} if !timeline[e.end]?
    timeline[e.end].isend = yes
    timeline[e.end].ids[id] = yes
  for d, day of timeline
    day.isstart = !day.isduring and day.isstart
    day.isend = !day.isduring and day.isend
    day.isduring = day.isduring
    delete day.count
    day.ids = Object.keys day.ids
  timeline

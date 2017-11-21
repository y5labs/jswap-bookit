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
      timeline[date] = { count: 0, ids: {}} if !timeline[date]?
      timeline[date].count += 3
      timeline[date].ids[id] = yes
    timeline[e.start] = { count: 0, ids: {}} if !timeline[e.start]?
    timeline[e.start].count += 1
    timeline[e.start].ids[id] = yes
    timeline[e.end] = { count: 0, ids: {}} if !timeline[e.end]?
    timeline[e.end].count += 2
    timeline[e.end].ids[id] = yes
  for d, day of timeline
    day.isstart = day.count is 1
    day.isend = day.count is 2
    day.isduring = day.count >= 3
    delete day.count
    day.ids = Object.keys day.ids
  timeline

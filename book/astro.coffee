{ component, dom } = require 'odojs'
moment = require 'moment-timezone'
chrono = require 'chronological'
moment = chrono moment
simpledate = 'YYYY-MM-DD'

module.exports = component render: (state, params, hub) ->
  today = moment().startOf 'd'
  startOfMonth = today.clone().startOf 'M'

  months = startOfMonth.every(1, 'M')
  beforeMonth = startOfMonth.clone().subtract(1, 's')
  days = months.between beforeMonth, startOfMonth.clone().add(6, 'M')

  select = (date) -> (e) ->
    e.preventDefault()
    hub.emit 'select', date

  dom '.astro', days.map (month) ->
    start = month.clone().startOf('isoWeek')
    beforeStart = start.clone().subtract(1, 's')
    end = month.clone().endOf('month').endOf('isoWeek')

    days = start.every(1, 'd')
    days = days.between beforeStart, end

    selectedDate = null
    selectedDate = moment params.selectedDate if params.selectedDate?

    weeks = []
    for i in [0...days.length / 7]
      weeks.push days[i * 7...(i + 1) * 7]
    [
      dom '.astro-header', dom 'h2', month.format 'MMMM YYYY'
      dom '.astro-month', weeks.map (week) ->
        dom '.astro-week', week.map (d) ->
          date = d.format simpledate
          day = state.bookings.timeline[date]
          day ?= { isstart: no, isduring: no, isend: no, ids: [] }
          isselectedstart = params.selectedRange?.start?.isSame d
          isselectedend = params.selectedRange?.end?.isSame d
          isselected = params.selectedRange?.start?.isBefore(d) and params.selectedRange?.end?.isAfter(d)
          if params.selectedRange?.start?.isSame(d) and params.selectedRange?.start?.isSame params.selectedRange?.end
            isselectedstart = no
            isselectedend = no
            isselected = yes
          if !d.isSame(month, 'month')
            return dom '.day.empty', dom 'span', d.format 'D'
          if selectedDate? and selectedDate.isSame(d, 'day')
            return dom "a.day.selected#{if isselectedstart or isselectedend or isselected then '.selected-during' else ''}#{if day.isstart or day.isend or day.isduring then '.during' else ''}", { onclick: select(d), attributes: href: '#' }, [
              dom 'span', d.format 'D'
              dom 'div', d.format 'D'
            ]
          dom "a.day#{if d.isoWeekday() > 5 then '.weekend' else ''}#{if d.isBefore today then '.past' else ''}#{if day.isstart then '.start' else ''}#{if day.isend then '.end' else ''}#{if day.isduring then '.during' else ''}#{if isselectedstart then '.selected-start' else if isselectedend then '.selected-end' else if isselected then '.selected-during' else ''}", { onclick: select(d), attributes: href: '#' }, dom 'span', d.format 'D'
    ]

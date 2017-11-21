route = require 'odo-route'

route '*', (p) ->
  status: 404
  page:
    id: 'error'
    message: "Sorry, the \"#{p.url}\" page was not found."

module.exports = route

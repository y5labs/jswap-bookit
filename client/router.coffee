{ component, dom } = require 'odojs'
inject = require 'injectinto'

getpage = (params) ->
  page = params.page ? 'default'
  page = page.id if page instanceof Object
  inject.one "page:#{page}"

Router = component
  query: (params) ->
    getpage(params).query params
  render: (state, params, hub) ->
    dom '#root.wrapper', [
      getpage(params) state, params, hub
    ]

module.exports = Router

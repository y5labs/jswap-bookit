{ component, dom, svg } = require 'odojs'
inject = require 'injectinto'

inject.bind 'page:error', component
  render: (state, params) ->
    dom '.page--wrapper', [
      dom 'p', params.page.message
      dom 'p', params.page.details
    ]

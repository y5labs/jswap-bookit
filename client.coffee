{ component, hub, dom } = require 'odojs'
inject = require 'injectinto'
odoql = require 'odoql/odojs'
component.use odoql

hub = hub()

request = require 'superagent'
dynamic = require 'odoql-exe/dynamic'
Store = require 'odoql-store'
localstore = Store name: 'localstore'
exe = require 'odoql-exe'
exe = exe hub: hub
  .use require 'odoql-localstorage'
  .use require 'odoql-http'
  .use require 'odoql-csv'
  .use localstore
  .use dynamic (keys, queries, cb) ->
    request
      .post '/query'
      .send q: queries
      .set 'Accept', 'application/json'
      .end (err, res) ->
        return cb err if err?
        return cb new Error res.text unless res.ok
        result = {}
        for key in keys
          result[key] = res.body[key]
        cb null, result

pods = [
  require './book/'
]

# Setup odo relay against the root router component
# Discover queries, state and dom elements already built on the server
relay = require 'odo-relay'
root = document.querySelector '#root'
router = require './client/router'
scene = relay root, router, exe,
  queries: window.__queries
  state: window.__state
  hub: hub

# Load routes into page.js for pushstate routing
route = require 'odo-route'
page = require 'page'
hostname = window.location.hostname
hostnameparts = hostname.split '.'
subdomain = if hostnameparts.length is 3
  hostnameparts[0]
else
  null
page '*', (e, next) ->
  scene.clearParams()
  window.ga 'send', 'pageview', e.path if window.ga?
  next()
  window.scrollTo 0, 0
for route in route.routes()
  do (route) ->
    page route.pattern, (e, next) ->
      context =
        hostname: hostname
        subdomain: subdomain
        url: e.pathname
        params: e.params
        querystring: e.querystring
      callednext = no
      result = route.cb context, ->
        callednext = yes
        next()
      scene.update result if !callednext

# Log all events
hub.all (e, description, p, cb) ->
  for n in ['odo', 'Odo', 'localdb', 'remotedb', 'socket']
    return cb() if description.indexOf(n) isnt -1
  return cb() if description is 'update'
  console.log description, p
  cb()

p hub, scene, localstore for p in pods

hub.every 'update', (p, cb) ->
  p ?= {}
  p.version = scene.params()?.version ? 0
  p.version++
  scene.update p
  cb()

# Detect the current url and run scene.update for the first time
page.start()

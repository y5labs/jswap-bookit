module.exports = (app) ->
  Store = require 'odoql-store'
  Exe = require 'odoql-exe'
  buildqueries = require 'odoql-exe/buildqueries'
  app.post '/query', (req, res, next) ->
    store = Store()
    require('../book/server').query req, store

    exe = Exe()
      .use store
    run = buildqueries exe, req.body.q
    run (errors, results) ->
      return res.send results if !errors?
      for _, error of errors
        if error.stack?
          console.error error.stack
        else
          console.error error
      res.status 500
      res.send errors

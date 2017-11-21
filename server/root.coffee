hash = Math.random().toString()

module.exports = (app) ->
  app.get '/*', (req, res, next) ->
    res.send """
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta http-equiv="X-UA-Compatible" content="IE=edge, chrome=1" />
          <meta name="viewport" content="width=570,user-scalable=no">
          <title>BookIT</title>
          <link rel="stylesheet" href="/dist/bundle.css?#{hash}" />
        </head>
        <body>
          <div id="root"></div>
          <script src="/dist/bundle.js?#{hash}"></script>
        </body>
      </html>
    """

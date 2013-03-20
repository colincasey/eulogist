appname = "Eulogist"
author = "Colin Casey"

# setup dependencies
connect = require('connect')
express = require('express')
io = require('socket.io')
config = require('nconf')
nap = require('nap')
coffee = require('coffee-script')
less = require('less')

Log = require('./log')

# setup configuration
config.argv().env()
config.file(file: 'config.json')
config.defaults({
  http: {
    port: 4321
  },
  logs: []
})

logs = (new Log(logConfig) for logConfig in config.get('logs'))

# setup express
server = express.createServer()
server.configure ->
  server.set('views', __dirname + '/../views')
  server.set('view options', layout: false)
  server.use(connect.bodyParser())
  server.use(express.cookieParser())
  server.use(express.session(secret: 'ajei583mfy39kf8nfdkfif3'))
  server.use(connect.static(__dirname + '/../static'))
  server.use(server.router)

# setup errors
server.error (err, req, res, next) ->
  if err instanceof NotFound
    res.render('404.jade', locals: {
      title: "#{appname}: 404 - Not Found"
      description: ''
      author: author
    }, status: 404)
  else
    res.render('500.jade', locals: {
      title: "#{appname}: Error"
      description: ''
      author: author
      error: err
    }, status: 500)

# start server
server.listen(config.get('http:port'))

# setup socket.io
io = io.listen(server)
io.sockets.on 'connection', (socket) ->
  console.log('client connected')

  logsVMs = ({ id: log.name.replace(' ', '+'), name: log.name } for log in logs)
  socket.emit('logs', logsVMs)

  newStatus = ->
    random = Math.floor((Math.random()*20)+1)
    switch random
      when 1 then 500
      when 2 then 400
      when 3 then 300
      when 4 then 100
      else 200

  duration = Math.floor(Math.random() * 300 + Math.random() * 1000)
  sendLoop = ->
    socket.emit('logMessage', {
      method: 'GET'
      status: newStatus()
      url: '/some/url'
      handledBy: 'DashboardController#index'
      requestedOn: new Date()
      duration: Math.floor((Math.random()*1500)+1)
    })
    duration = Math.floor(Math.random() * 300 + Math.random() * 1000)
    setTimeout(sendLoop, duration)
  setTimeout(sendLoop, duration)

  socket.on 'open', (logId) ->
    console.log("request to open log with id '#{logId}'")
    name = logId.replace('+', ' ')
    log = (log for log in logs when log.name == name)[0]

    unless log?
      console.log 'error: log not found'
      socket.emit 'logNotFound'
      return

    console.log("opening log #{log.name}")
    log.on 'open', ->
      console.log "#{log.name} has been opened"
      socket.emit 'opened'
      log.on 'log', (logData) ->
        console.log logData
        socket.emit 'data', logData
    log.on 'authenticate', ->
      socket.emit 'authenticate'
    log.open()

  socket.on 'disconnect', ->
    console.log('client disconnected')

# routes
server.get '/', (req, res) ->
  res.render('index.jade', locals: {
    title: appname
    description: ''
    author: author
    logs: ({ id: log.name.replace(' ', '+'), name: log.name } for log in logs)
    nap: nap
  })

# helper for 500 errors
server.get '/500', (req, res) ->
  throw new Error('This is a 500 error')

# always keep 404 route as last
server.get '/*', (req, res) ->
  throw new NotFound;

NotFound = (msg) ->
  @name = 'NotFound'
  Error.call(this, msg)
  Error.captureStackTrace(this, arguments.callee)

# setup assets
nap({
  publicDir: "/static"
  assets: {
    js: {
      all: [
        '/static/vendor/jquery-1.8.2.js'
        '/static/vendor/spin.min.js'
        '/static/vendor/jquery.spin.js'
        '/static/vendor/bootstrap/js/bootstrap.js'
        '/static/vendor/d3.js'
        '/static/vendor/angular/angular.js'
        '/static/vendor/angular-ui/angular-ui.js'
        '/static/js/timeline.coffee'
        '/static/js/application.coffee'
        '/static/js/controllers.coffee'
        '/static/js/directives.coffee'
        '/static/js/filters.coffee'
        '/static/js/services.coffee'
      ],
      modernizr: [
        '/static/vendor/modernizr/modernizr.js'
      ]
    },
    css: {
      all: [
        '/static/vendor/bootstrap/css/bootstrap.css'
        '/static/vendor/angular-ui/angular-ui.css'
        '/static/css/application.less'
      ]
    },
    jst: {
      all: [
        '/static/templates/logs.jade'
      ]
    }
  }
})

console.log('Listening on http://localhost:' + config.get('http:port'))

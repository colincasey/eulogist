EventEmitter = require('events').EventEmitter;
spawn = require('child_process').spawn;
#pty = require('pty.js')

class LogStream extends EventEmitter
  constructor: (file, opts = {}) ->
    @file = file
    @opts = opts

  start: ->
    throw new Error('must be implemented in subclass')

  stop: ->
    throw new Error('must be implemented in subclass')

  _handleDataReceived: (data) =>
    @emit 'data', data.toString('utf8')

class LocalLogStream extends LogStream
  start: ->
    @tail = spawn('tail', ['-f', @file])
    @tail.stdout.on('data', @_handleDataReceived)
    @emit('open')

  stop: ->
    @tail?.kill()
    @emit('close')

class RemoteLogStream extends LogStream
  constructor: (file, opts = {}) ->
    super(file, opts)
    @host = opts.host
    @session = 'disconnected'

  start: ->
    @term = pty.spawn('bash', [], {
      name: 'xterm',
      cwd: process.env.HOME,
      env: process.env
    })
    @term.on('data', @_handleTerminalDataReceived)
    @emit('start')

  stop: ->
    @term.destroy()
    @session = 'disconnected'
    @emit('close')

  _handleTerminalDataReceived: (data) =>
    data = data.toString('utf8')
    delegate = "_on#{@session.charAt(0).toUpperCase()}#{@session.substring(1)}"
    if @[delegate]
      @[delegate](data)
    else
      throw 'Not sure how to handle state ' + @session

  _onDisconnected: (data) =>
    if /\$$/.test(data.toString().trim())
      console.log("connecting to #{@opts.host}...")
      @session = 'initializing'
      @term.write("ssh #{@opts.host}\r")

  _onInitializing: (data) =>
    if /^Password:/.test(data)
      @emit 'passwordRequested', (password) =>
        @session = 'authenticating'
        console.log('authenticating...')
        @term.write("#{password}\r")

  _onAuthenticating: (data) =>
    if /\$$/.test(data.trim())
      @session = 'connected'
      console.log('connected')
      @term.write("tail -f \"#{@file}\"\r")

  _onConnected: (data) =>
    @_handleDataReceived(data)

module.exports = (file, opts = {}) ->
  new (if opts.host? then RemoteLogStream else LocalLogStream)(file, opts)
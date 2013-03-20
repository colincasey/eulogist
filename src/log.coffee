Interpreter = require('./interpreter')
LogStream = require('./logStream')
EventEmitter = require('events').EventEmitter;

requiredArgs = ['name', 'file', 'format']

module.exports = class Log extends EventEmitter
  constructor: (opts = {}) ->
    for requiredArg in requiredArgs
      throw new Error("'#{requiredArg}' is required") unless opts[requiredArg]?

    @opts = opts
    @name = opts.name
    @stream = new LogStream(@opts.file, @opts)
    @interpreter = new Interpreter(@stream, @opts.format)

    log = this
    @interpreter.on('log', @_onLog)

  _onLog: (logData) =>
    @emit 'log', logData

  open: () ->
    @emit 'open'
    @stream.start()

  close: () ->
    @emit 'close'
    @stream.stop()




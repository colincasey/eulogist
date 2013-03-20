EventEmitter = require('events').EventEmitter
StringScanner = require('pstrscan')
PatternScanner = require('./patternScanner')

module.exports = class Interpreter extends EventEmitter
  constructor: (streamer, format) ->
    @buffer = ''
    @scanner = new StringScanner(@buffer)
    @logData = {}

    @patterns = @_buildPatterns format
    @currentPattern = @patterns[0]
    @readingStackTrace = false

    @streamer = streamer
    @streamer.on 'data', @_processData

  _processData: (data) =>
    @buffer += data
    @scanner.concat(data)
    if !@ready
      @_scanToStart()
    else if @readingStackTrace
      @_readStackTrace()
    else
      @_continueMatching()

  _scanToStart: ->
    if @scanner.check(@patterns[0].getMatcher())
      @ready = true
      @_continueMatching()
    else
      result = @scanner.scanUntil(@patterns[0].getMatcher())
      if result?
        capture = @scanner.getCapture(1)
        startPosition = @scanner.getPos() - capture.length - 1
        @scanner.setPosition(startPosition)
        @ready = true
        @_continueMatching()

  _continueMatching: ->
    pattern = @currentPattern
    result = pattern.scan(@scanner)
    if result?
      @logData[pattern.name] = result
      @_nextPattern()

  _nextPattern: ->
    nextIndex = @patterns.indexOf(@currentPattern) + 1
    if nextIndex == @patterns.length
      @currentPattern = @patterns[0]
      if @logData.priority && @logData.priority.toLowerCase() == 'error'
        @readingStackTrace = true
        @startOfStackTrace = @scanner.getPos()
        @_readStackTrace()
      else
        @_logDataComplete()
        @_continueMatching()
    else
      @currentPattern = @patterns[nextIndex]
      @_continueMatching()

  _readStackTrace: ->
    result = @scanner.scanUntil(@currentPattern.getMatcher())
    if result?
      capture = @scanner.getCapture(1)
      endOfStackTrace = @scanner.getPos() - capture.length - 1
      @scanner.setPos(endOfStackTrace)
      stackTrace = @buffer.substring(@startOfStackTrace, endOfStackTrace)
      @logData.stackTrace = stackTrace
      @_logDataComplete()
      @_continueMatching()

  _logDataComplete: ->
    @buffer = @buffer.substring(@scanner.getPos())
    @scanner = new StringScanner(@buffer)
    @readingStackTrace = false
    @emit 'log', @logData
    @logData = {}

  _buildPatterns: (format) ->
    patterns = []
    patternScanner = new PatternScanner(format)
    while patternScanner.hasPatterns()
      patterns.push patternScanner.nextPattern()
    throw new Error('format could not be properly parsed: ' + format) if patterns.length == 0
    patterns





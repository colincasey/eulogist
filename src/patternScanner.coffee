StringScanner = require('pstrscan')
Pattern = require('./pattern')

ESCAPED_PERCENT = /%%/
PATTERN_START = /%/
CONVERSION_CHARACTER = /([cCdFlLmMnprtxX])/
IGNORE = /[\s]/
PADDING_MODIFIER = /(-?\d+)/
TRUNCATE_MODIFIER_START = /\./
TRUNCATE_MODIFIER = /(\d+)/
FORMATTING = /\{([^}]*)\}/
ENDING_SPACE = /\s{1}/

module.exports = class PatternScanner
  constructor: (pattern) ->
    @pattern = pattern
    @scanner = new StringScanner(pattern)

  hasPatterns: ->
    !@scanner.hasTerminated()

  nextPattern: ->
    throw new Error('end of pattern has been reached') if @scanner.hasTerminated()

    @_patternReset()
    @scanner.skip(IGNORE)
    @scanner.skip(ESCAPED_PERCENT)

    if @scanner.scan(PATTERN_START)
      start = @scanner.getPos() - 1
      patternContent = @scanner.scanUntil(CONVERSION_CHARACTER)
      @_throwParseError('no matching conversion character', start) unless patternContent?
      @_parsePattern(patternContent)
      @_parseSeparator()
    else
      throw new Error("no conversion patterns are present in '#{@pattern}'")

    @_createPattern()

  _createPattern: ->
    new Pattern
      conversionCharacter: @conversionCharacter
      padding: @padding
      truncate: @truncate
      format: @format
      separator: @separator

  _patternReset: ->
    @conversionCharacter = null
    @padding = null
    @truncate = null
    @format = null
    @separator = null

  _throwParseError: (msg, pos) ->
    errorIndicator = if pos == 0 then "-->#{@pattern}" else "#{@pattern.substring(0, pos)}-->#{@pattern.substring(pos)}"
    throw new Error("#{msg} at position #{pos}: '#{errorIndicator}'")

  _throwPatternParseError: (msg, pos, contentScanner) ->
    currentPos = @scanner.getPos()
    patternStr = contentScanner.getSource()
    @_throwParseError(msg, currentPos - patternStr.length + pos)

  _parseSeparator: ->
    currentPos = @scanner.getPos()
    nextPattern = @scanner.scanUntil(/%[^%]/)
    if nextPattern?
      @separator = @pattern.substring(currentPos, @scanner.getPos() - 2)
      @separator = null if @separator == ''
      @scanner.unscan()
    else
      @separator = null

  _parsePattern: (patternContent) ->
    contentScanner = new StringScanner(patternContent)
    @_parsePadding(contentScanner)
    @_parseTruncate(contentScanner)
    @_parseConversionCharacter(contentScanner)
    @_parseFormatting()

  _parsePadding: (contentScanner) ->
    start = contentScanner.getPos()
    value = contentScanner.scan(PADDING_MODIFIER)
    if value?
      intValue = parseInt(value)
      @_throwPatternParseError("invalid padding modifier '#{value}'", start, contentScanner) if isNaN(intValue) || intValue == 0
      @padding = intValue
    unless contentScanner.check(TRUNCATE_MODIFIER_START)? || contentScanner.check(CONVERSION_CHARACTER)
      end = contentScanner.checkUntil(CONVERSION_CHARACTER) - 1
      badValue = contentScanner.getSource().substring(contentScanner.getPos(), contentScanner.getPos() + end)
      @_throwPatternParseError("invalid padding modifier '#{badValue}'", start, contentScanner)

  _parseTruncate: (contentScanner) ->
    if contentScanner.scan(TRUNCATE_MODIFIER_START)
      start = contentScanner.getPos()
      value = contentScanner.scan(TRUNCATE_MODIFIER)
      if value?
        intValue = parseInt(value)
        @_throwPatternParseError("invalid truncate modifier '#{value}'", start, contentScanner) if intValue <= 0
        @truncate = intValue
      else
        end = contentScanner.checkUntil(CONVERSION_CHARACTER) - 1
        badValue = contentScanner.getSource().substring(start, start + end)
        @_throwPatternParseError("invalid truncate modifier '#{badValue}'", start, contentScanner)

  _parseConversionCharacter: (contentScanner) ->
    @conversionCharacter = contentScanner.scan(CONVERSION_CHARACTER)

  _parseFormatting: ->
    start = @scanner.getPos()
    if @scanner.scan(FORMATTING)?
      @format = @scanner.getCapture(1)
      @_throwParseError("no format specified", start) unless @format

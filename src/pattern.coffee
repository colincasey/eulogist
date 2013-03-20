module.exports = class Pattern
  constructor: (opts = {}) ->
    defaults = patternDefaults[opts.conversionCharacter] || {}
    @[key] = value for key, value of defaults
    @[key] = value for key, value of opts when value?

  scan: (scanner) ->
    matcher = @getMatcher()
    if scanner.scan(matcher) then scanner.getCapture(1).trim() else null

  getMatcher: ->
    unless @_matcher?
      customMatcher = "create#{@name.charAt(0).toUpperCase()}#{@name.substring(1)}Matcher"
      @_matcher = @[customMatcher]() if @[customMatcher]?
      @_matcher = @_matcher || @createDefaultMatcher()
    @_matcher

  createDefaultMatcher: ->
    if @truncate?
      contents = '.{' + "#{@truncate}" + '}'
    else if @padding?
      contents = '.{' + "#{Math.abs(@padding)}" + '}'
    else
      contents = "[^\\s]+"
    ///(#{contents})#{@separator || ''}///


patternDefaults = {
  'c': {
    name: 'category',
    createCategoryMatcher: ->
      return unless @format?
      precision = parseInt(@format, 10)
      return if isNaN(precision)
      categories = ("[^.]+" for i in [0..precision-1])
      ///(#{categories.join("\\.")})#{@separator || ''}///
  },
  'd': {
    name: 'date',
    format: 'ISO8601',
    createDateMatcher: ->
      dateMatcher = namedDateFormatToFormat[@format] || @format
      for match, replacement of dateFormatReplacements
        dateMatcher = dateMatcher.replace(match, replacement)
      ///(#{dateMatcher})#{@separator || ''}///

  },
  'p': {
    name: 'priority'
  },
  'M': {
    name: 'method'
  },
  'L': {
    name: 'lineNumber'
  },
  'x': {
    name: 'nestedDiagnosticContext'
  },
  'm': {
    name: 'message',
    createMessageMatcher: ->
      /([^\r\n]*)/
  },
  'n': {
    name: 'lineSeparator',
    createLineSeparatorMatcher: () ->
      /(\n|\r\n)/
  }
}

namedDateFormatToFormat = {
  'ISO8601': 'yyyy-MM-dd HH:mm:ss,SSS'
}

dateFormatReplacements = {
  'yyyy': "\\d{4}",
  'mm': "\\d{2}",
  'MM': "\\d{2}",
  'dd': "\\d{2}",
  'HH': "\\d{2}",
  'ss': "\\d{2}",
  'SSS': "\\d{3}"
}
assert = require('assert')

describe 'PatternScanner', ->
  PatternScanner = require '../src/patternScanner'

  describe 'conversion character parsing', ->
    it 'should recognize all log4j conversion characters', ->
      for conversionCharacter in ['c', 'C', 'd', 'F', 'l', 'L', 'm', 'M', 'n', 'p', 'r', 't', 'x', 'X']
        pattern = scanner = new PatternScanner("%#{conversionCharacter}").nextPattern()
        pattern.conversionCharacter.should.equal conversionCharacter

    it 'should raise an error if a no conversion character is supplied', ->
      (-> new PatternScanner("%?").nextPattern()).should.throwError("no matching conversion character at position 0: '-->%?'")

  describe 'padding modifier parsing', ->
    it 'should be able to detect left padding modifier', ->
      pattern = new PatternScanner('%10c').nextPattern()
      pattern.padding.should.equal 10

    it 'should be able to detect right padding modifier', ->
      pattern = new PatternScanner('%-10c').nextPattern()
      pattern.padding.should.equal -10

    it 'should raise an error if a bad value is given for the modifier', ->
      (-> new PatternScanner("%?c").nextPattern()).should.throwError("invalid padding modifier '?' at position 1: '%-->?c'")

    it 'should raise an error if zero is given as the padding modifier', ->
      (-> new PatternScanner("%0c").nextPattern()).should.throwError("invalid padding modifier '0' at position 1: '%-->0c'")

  describe 'truncate modifier parsing', ->
    it 'should be able to detect truncate modifier', ->
      pattern = new PatternScanner("%.37c").nextPattern()
      pattern.truncate.should.equal 37

    it 'should raise an error if a bad value is given for the modifier', ->
      (-> new PatternScanner("%.?c").nextPattern()).should.throwError("invalid truncate modifier '?' at position 2: '%.-->?c'")

    it 'should raise an error if zero is given as the truncate modifier', ->
      (-> new PatternScanner("%.0c").nextPattern()).should.throwError("invalid truncate modifier '0' at position 2: '%.-->0c'")

    it 'should raise an error if a negative value is given as the truncate modifier', ->
      (-> new PatternScanner("%.-22c").nextPattern()).should.throwError("invalid truncate modifier '-22' at position 2: '%.-->-22c'")

  describe 'format parsing', ->
    it 'should be able to detect the format', ->
      pattern = new PatternScanner("%c{2}").nextPattern()
      pattern.format.should.equal "2"

    it 'should raise an error if no value is given for the format', ->
      (-> new PatternScanner("%c{}").nextPattern()).should.throwError("no format specified at position 2: '%c-->{}'")

  describe 'parsing multiple patterns', ->
    it 'should be able to detect the pattern seperator', ->
      scanner = new PatternScanner("%c %d")
      pattern = scanner.nextPattern()
      pattern.separator.should.equal " "
      pattern = scanner.nextPattern()
      assert.equal(pattern.separator, null)

    it 'should be able to detect all different types of patterns', ->
      scanner = new PatternScanner("%d %-5p %-17c{2}.%M:%L %3x - %m%n")

      pattern = scanner.nextPattern()
      pattern.conversionCharacter.should.equal 'd'
      pattern.name.should.equal 'date'
      pattern.separator.should.equal ' '

      pattern = scanner.nextPattern()
      pattern.conversionCharacter.should.equal 'p'
      pattern.name.should.equal 'priority'
      pattern.padding.should.equal -5
      pattern.separator.should.equal ' '

      pattern = scanner.nextPattern()
      pattern.conversionCharacter.should.equal 'c'
      pattern.name.should.equal 'category'
      pattern.padding.should.equal -17
      pattern.format.should.equal '2'
      pattern.separator.should.equal '.'

      pattern = scanner.nextPattern()
      pattern.conversionCharacter.should.equal 'M'
      pattern.name.should.equal 'method'
      pattern.separator.should.equal ':'

      pattern = scanner.nextPattern()
      pattern.conversionCharacter.should.equal 'L'
      pattern.name.should.equal 'lineNumber'
      pattern.separator.should.equal ' '

      pattern = scanner.nextPattern()
      pattern.conversionCharacter.should.equal 'x'
      pattern.name.should.equal 'nestedDiagnosticContext'
      pattern.padding.should.equal 3
      pattern.separator.should.equal ' - '

      pattern = scanner.nextPattern()
      pattern.conversionCharacter.should.equal 'm'
      pattern.name.should.equal 'message'
      assert.equal(pattern.separator, null)

      pattern = scanner.nextPattern()
      pattern.conversionCharacter.should.equal 'n'
      pattern.name.should.equal 'lineSeparator'
      assert.equal(pattern.separator, null)



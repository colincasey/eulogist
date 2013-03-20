assert = require('assert')
EventEmitter = require('events').EventEmitter

describe 'Interpreter', ->
  Interpreter = require '../src/interpreter'
  messageFormat = "%d %-5p %-17c{2}.%M:%L %3x - %m%n"

  beforeEach ->
    @streamer = new EventEmitter()

  describe "interpreting messages", ->
    it "should be able to recognize a standard message", (done) ->
      interpreter = new Interpreter(@streamer, messageFormat)
      interpreter.on 'log', (logData) ->
        logData.date.should.equal "2012-05-24 11:33:29,958"
        logData.priority.should.equal 'INFO'
        logData.category.should.equal 'form.authentication'
        logData.method.should.equal 'setParams'
        logData.lineNumber.should.equal '?'
        logData.nestedDiagnosticContext.should.equal ''
        logData.message.should.equal "BEFORE: something"
        done()
      @streamer.emit('data', "2012-05-24 11:33:29,958 INFO  form.authentication.setParams:?     - BEFORE: something\n")

  describe 'date matching', ->
    it "should be able to match date", (done) ->
      interpreter = new Interpreter(@streamer, "%d")
      interpreter.on 'log', (log) ->
        log.date.should.equal "2012-05-24 11:33:29,958"
        done()
      @streamer.emit('data', "2012-05-24 11:33:29,958")

    it 'should be able to match date with a specific format', (done) ->
      interpreter = new Interpreter(@streamer, '%d{HH:mm:ss,SSS}')
      interpreter.on 'log', (log) ->
        log.date.should.equal "11:33:29,958"
        done()
      @streamer.emit('data', "11:33:29,958")

  describe 'priority matching', ->
    it "should be able to match priority", (done) ->
      interpreter = new Interpreter(@streamer, "%p")
      interpreter.on 'log', (message) ->
        message.priority.should.equal 'INFO'
        done()
      @streamer.emit('data', 'INFO')

  describe 'category matching', ->
    it 'should be able to match category', (done) ->
      interpreter = new Interpreter(@streamer, '%c')
      interpreter.on 'log', (message) ->
        message.category.should.equal 'some.package.with.Class'
        done()
      @streamer.emit 'data', 'some.package.with.Class'

    it 'should be able to match a category when formatting is specified', (done) ->
      interpreter = new Interpreter(@streamer, '%c{2}')
      interpreter.on 'log', (message) ->
        message.category.should.equal 'with.Class'
        done()
      @streamer.emit 'data', 'with.Class'

  describe 'method name matching', ->
    it "should be able to match method", (done) ->
      interpreter = new Interpreter(@streamer, "%M")
      interpreter.on 'log', (message) ->
        message.method.should.equal 'setParams'
        done()
      @streamer.emit 'data', 'setParams'

  describe 'line number matching', ->
    it "should be able to match line numbers", (done) ->
      interpreter = new Interpreter(@streamer, "%L")
      interpreter.on 'log', (message) ->
        message.lineNumber.should.equal '123'
        done()
      @streamer.emit 'data', '123'

  describe "nested diagnostic content matching", ->
    it "should be able to match the pattern %x", (done) ->
      interpreter = new Interpreter(@streamer, "%x")
      interpreter.on 'log', (message) ->
        message.nestedDiagnosticContext.should.equal "1"
        done()
      @streamer.emit 'data', "1"

  describe "message matching", ->
    it "should be able to match the pattern %m", (done) ->
      interpreter = new Interpreter(@streamer, "%m")
      interpreter.on 'log', (message) ->
        message.message.should.equal "hello"
        done()
      @streamer.emit 'data', "hello"

  describe "matching %n pattern", ->
    it "should be able to match a regular newline", (done) ->
      interpreter = new Interpreter(@streamer, "%n")
      interpreter.on 'log', (message) ->
        message.lineSeparator.should.equal ""
        done()
      @streamer.emit 'data', "\n"

    it "should be able to match a carriage return and newline", (done) ->
      interpreter = new Interpreter(@streamer, "%n")
      interpreter.on 'log', (message) ->
        message.lineSeparator.should.equal ""
        done()
      @streamer.emit 'data', "\r\n"

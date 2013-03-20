LogStream = require('../src/logStream')
fs = require('fs')
path = require('path')

describe 'logStream', ->
  testFilepath = null
  testFile = null
  stream = null

  beforeEach ->
    testFilepath = path.join(__dirname, 'logStream.test')
    testFile = fs.createWriteStream(testFilepath)
    stream = new LogStream(testFilepath)
    stream.start()

  afterEach ->
    stream.stop()
    testFile.destroy()
    fs.unlinkSync testFilepath

  it 'should fire data event whenever new content is written to file', (done) ->
    stream.once 'data', (data) ->
      data.should.equal "1"
      testFile.write "2"
      stream.once 'data', (data) ->
        data.should.equal "2"
        done()
    testFile.write "1"
requestPromise = require 'request-promise'
bluebird = require 'bluebird'
chai = require 'chai'

app = require '../src/app'

resizeImages = (endpoint, urls, height, width) ->
  request =
    images: []
  for u in urls
    request.images.push
      input: u
      operation: 'max'
      height: height
      width: width
  r =
    uri: endpoint
    json: true
    body: request
    simple: false
    resolveWithFullResponse: true
    followRedirect: false
  requestPromise.post r

successTest = (endpoint, name, urls) ->

  describe name, -> 
    response = null

    before ->
      resizeImages endpoint, urls, 400, 400
      .then (r) ->
        response = r

    it 'should respond with 202 Accepted', ->
      chai.expect(response.statusCode, JSON.stringify(response.body)).to.equal 202

describe 'Resizing images via HTTP API', ->

  port = 5555
  endpoint = "http://localhost:#{port}/resize"
  server = null

  before ->
    app.startServer port
    .then (instance) ->
      server = instance.server

  after ->
    server.close()

  urls = require './fixtures/images-music-jonnor-com.json'
  successTest endpoint, 'music.jonnor.com', urls

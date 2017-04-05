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
    it 'should set Location header to /job/:id', ->
      location = response.headers['location']
      chai.expect(location).to.contain '/job/'

    describe 'GET /job/:id', ->
      jobResponse = null
      before ->
        url = endpoint.replace('/resize', response.headers['location'])
        r =
          uri: url
          json: true
          simple: false
          resolveWithFullResponse: true
        requestPromise.get r
        .then (res) ->
          jobResponse = res
      it 'should return 201 Created', ->
        chai.expect(jobResponse.statusCode, JSON.stringify(jobResponse.body)).to.equal 201
      it 'should show job as not completed'

    describe 'after a little time', ->
      it 'the job is completed'

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

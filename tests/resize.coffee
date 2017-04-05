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
      it 'shows job as not completed', ->
        job = jobResponse.body
        chai.expect(job).to.include.keys ['created_at', 'updated_at', 'completed_at', 'failed_at']
        chai.expect(job.completed_at).to.be.a 'null'
        chai.expect(job.failed_at).to.be.a 'null'
        chai.expect(job.created_at).to.be.a 'string'
      it 'has info about the images', ->
        job = jobResponse.body
        chai.expect(job).to.include.keys ['id', 'data']
        chai.expect(job.data).to.have.keys ['images']
        images = job.data.images
        chai.expect(images).to.exist
        chai.expect(images).to.be.an 'object'
        chai.expect(Object.keys(images)).to.have.length urls.length

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

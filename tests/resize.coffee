requestPromise = require 'request-promise'
bluebird = require 'bluebird'
chai = require 'chai'
msgflo = require 'msgflo'

config = require '../config'

# Based on http://stackoverflow.com/a/38225011/1967571
rejectDelayer = (delay) ->
  f = (reason) ->
    return new Promise (resolve, reject) ->
      setTimeout(reject.bind(null, reason), delay)
  return f

retryUntil = (attempt, test, delay=500, max=5) ->
  p = Promise.reject(new Error 'retry starter')
  for i in [0..max]
    p = p.catch(attempt).then(test).catch(rejectDelayer(delay))
  return p

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
      completedResponse = null

      before ->
        @timeout 12*1000

        jobStatus = () ->
          url = endpoint.replace('/resize', response.headers['location'])
          r =
            uri: url
            json: true
            simple: false
            resolveWithFullResponse: true
          requestPromise.get r
          .then (res) ->
            return res

        isCompleted = (response) ->
          #console.log 'b', JSON.stringify(response.body, null, 2)
          if response.statusCode == 200
            return Promise.resolve response
          else
            return Promise.reject new Error "Job status was #{response.statusCode}"

        retryUntil(jobStatus, isCompleted, 1000, 15)
        .then (res) ->
          completedResponse = res

      it.skip 'the job is completed', ->
        console.log 'done', completedResponse.body

setupParticipants = (options) ->
  return bluebird.promisify(msgflo.setup.participants)(options)
killProcesses = (parts, signal) ->
  return bluebird.promisify(msgflo.setup.killProcesses)(parts, signal)

describe 'Resizing images via HTTP API', ->
  port = 6666
  baseurl = process.env.IMAGERESIZE_TEST_TARGET or "http://localhost:#{port}"
  doSetup = not process.env.IMAGERESIZE_TEST_TARGET?
  endpoint = "#{baseurl}/resize"
  processes = null

  # TODO: support specifying envvars like PORT
  setup =
    graphfile: './graphs/imageresize.fbp'
    forward: 'stderr,stdout'
    broker: config.msgflo.broker

  before ->
    @timeout 10*1000
    return Promise.resolve true if not doSetup
    return setupParticipants setup
    .then (p) ->
      processes = p
  after ->
    @timeout 4*1000
    return Promise.resolve null if not processes
    return killProcesses processes

  urls = require './fixtures/images-few.json'
  successTest endpoint, 'music.jonnor.com', urls

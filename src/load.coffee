arrivals = require 'arrivals'
requestPromise = require 'request-promise'
bluebird = require 'bluebird'

exports.resizeImages = (endpoint, urls, height, width) ->
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

main = () ->
  jobs = []

  # parameters
  urls = urls = require '../tests/fixtures/images-few.json'
  port = 6666
  baseurl = process.env.IMAGERESIZE_TEST_TARGET or "http://localhost:#{port}" 
  end = undefined # forever, until p.stop()
  meanTime = 500

  p = arrivals.poisson.process meanTime, end

  p.on 'arrival', () ->
    requested = new Date()
    exports.resizeImages "#{baseurl}/resize", urls, 300, 300
    .then (response) ->
      jobUrl = response.headers['location']
      responded = new Date()
      console.log 'j', jobUrl
      jobs.push
        requested_at: requested
        responded_at: responded
        url: jobUrl

  p.once 'finished', () ->
    console.log('We are done.')
   
  p.start()


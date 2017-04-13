
uuid = require 'uuid'
bluebird = require 'bluebird'
requestPromise = require 'request-promise'
process.hrtime = require 'browser-process-hrtime' # shim for arrivals
arrivals = require 'arrivals'

common = require './common'
load = require './load'
stats = require './stats'

initialState =
  config:
    baseurl: window.location.origin
    updateRate: 10 # seconds
  inputs:
    jobrate: 0 # per minute
    imagesPerJob: 10
    urls: require '../tests/fixtures/images-music-jonnor-com.json'
    outputHeight: 300
    outputWidth: 300
  inputProcess: null
  jobs: {} # empty

changeInputProcess = (next, old, onArrival) ->
  if next.inputs.jobrate == old.inputs.jobrate and old.inputProcess
    # no need to (re)create
    next.inputProcess = old.inputProcess
    return

  if old.inputProcess
    old.inputProcess.stop()

  if next.inputs.jobrate
    meanTimeMs = 1000/(next.inputs.jobrate/60)
    end = undefined
    process = arrivals.poisson.process meanTimeMs, end
    process.on 'arrival', onArrival
    process.start()
    next.inputProcess = process
  else
    next.inputProcess = null

elem = (id) ->
  return document.getElementById id

subscribeInputs = (callback) ->
  elem('jobrate').onchange = (e) ->
    form = e.currentTarget
    callback { jobrate: parseFloat(form.elements.rate.value) }

renderJob = (job) ->
  top = document.createElement 'li'
  id = job.localId.substring 0,5
  state = "pending"
  end = new Date()
  end = new Date job.body?.completed_at if job.body?.completed_at
  timeMs = end.getTime() - job.requested_at.getTime()
  top.innerHTML = "#{id}: #{state} #{timeMs} ms"
  return top

renderJobs = (state) ->
  sorted = common.objectValues(state.jobs).sort (a, b) ->
    A = a.requested_at.getTime()
    B = b.requested_at.getTime()
    return B - A # latest first
  container = elem('jobs')
  container.innerHTML = ''
  console.log 'j', sorted
  for job in sorted
    e = renderJob(job)
    container.appendChild e

resizeImages = (state) ->
  i = state.inputs
  return load.resizeImages "#{state.config.baseurl}/resize", i.urls, i.outputWidth, i.outputHeight

exports.run = () ->
  currentState = common.clone initialState
  onChange = () ->
    renderJobs currentState

  onArrival = () ->
    # request job creation
    localJobId = uuid.v4() # HACK, since API does not allow us to specify
    currentState.jobs[localJobId] =
      localId: localJobId
      requested_at: new Date()
      responded_at: null
      url: null
      body: null 
    onChange()

    resizeImages currentState
    .then (response) ->
      # job was created
      job = currentState.jobs[localJobId]
      job.responded_at = new Date()
      if response.statusCode == 202
        job.url = currentState.config.baseurl+response.headers['location']
      else
        job.error =
          code: response.statusCode
          body: response.body
      onChange()

  subscribeInputs (newInputs) ->
    old = common.clone currentState
    old.inputProcess = currentState.inputProcess # not clone-able
    for k,v of newInputs
      currentState.inputs[k] = v
    onChange()
    changeInputProcess currentState, old, onArrival

  updateJobStatus = () ->
    jobs = common.objectValues(currentState.jobs).filter (j) ->
      created = j.url
      completed = j.body?.errored_at or j.body?.finished_at
      return created and not completed

    bluebird.map jobs, (job) ->
      requestPromise { uri: job.url, json: true }
      .then stats.calculateStats
      .then (data) ->
        data.localId = job.localId
        return data
    .then (jobsData) ->
      # do change update and notification once for whole set
      for data in jobsData
        currentState.jobs[data.localId].body = data
      onChange()

  setTimeout updateJobStatus, currentState.config.updateRate*1000
  changeInputProcess currentState, currentState, onArrival

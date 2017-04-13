
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
    updateRate: 5 # seconds
    deadline: 30 # seconds
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

imageStats = (job) ->
  images = job.body?.data?.images
  ret =
    all: []
    completed: []
    pending: []
    failed: []
  if images
    ret.all = common.objectValues images
    ret.failed = ret.all.filter (i) -> return i.failed_at?
    ret.completed = ret.all.filter (i) -> return i.completed_at?
    ret.pending = ret.all.filter (i) -> return not i.failed_at? and not i.completed_at? 
  return ret

renderJob = (job, deadlineMs) ->
  top = document.createElement 'li'
  id = job.localId.substring 0,5
  images = imageStats job

  end = new Date()
  end = new Date job.body?.completed_at if job.body?.completed_at
  timeMs = end.getTime() - job.requested_at.getTime()

  msg = 'unknown'
  state = 'pending'
  if job.requested_at
    msg = "job request sent"
    state = 'pending'
  if images.pending.length
    msg = "#{images.pending.length}/#{images.all.length} pending"
    state = 'pending'
  if images.failed.length
    msg = "#{images.failed.length}/#{images.all.length} failed"
    state = 'errored'
  if job.error
    msg = "job request failed #{job.error.code}: #{job.error.message}" if job.error
    state = 'errored'
  if job.body?.completed_at
    msg = "#{images.completed.length}/#{images.all.length} completed"
    state = 'completed'
  if timeMs > deadlineMs and state != 'errored'
    msg = "#{images.pending.length}/#{images.all.length} pending"
    state = 'errored'

  # TODO: consider executing taking longer than a deadline for errored
  # TODO: visualize state
  # TODO: visualize execution time
  top.className = "job #{state}"
  top.innerHTML = "#{id}: #{msg} #{timeMs} ms"
  return top

renderJobs = (state) ->
  sorted = common.objectValues(state.jobs).sort (a, b) ->
    A = a.requested_at.getTime()
    B = b.requested_at.getTime()
    return B - A # latest first
  container = elem('jobs')
  container.innerHTML = ''
  for job in sorted
    e = renderJob(job, state.config.deadline*1000)
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
          message: response.body.message
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

  setInterval updateJobStatus, currentState.config.updateRate*1000
  changeInputProcess currentState, currentState, onArrival

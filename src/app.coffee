express = require 'express'
bluebird = require 'bluebird'
bodyParser = require 'body-parser'
uuid = require 'uuid'
msgfloNodejs = require 'msgflo-nodejs'
debug = require('debug')('imageresize:web')

config = require '../config'
errors = require './errors'
jobs = require './jobs'

WebParticipant = require '../participants/Web'
StoreParticipant = require '../participants/StoreResult'

routes = {}
routes.getJob = (req, res, next) ->
  jobId = req.params.id
  debug "GET /job/:#{jobId}"
  jobs.get jobId
  .then (job) ->
    code = if jobs.isCompleted(job.data) then 200 else 201
    return res.status(code).json job
  .catch (err) ->
    return next err

routes.resizeImages = (req, res, next) ->
  debug "POST /resize", req.body?.images?.length

  # TODO: verify request payload with a JSON schema
  throw new error.HttpError "Missing .images array", 422 if not req.body.images

  jobId = uuid.v4()
  created = new Date

  # Generate one AMQP message for each image,
  # so they can be processed independently by the worker
  images = req.body.images.map (i) ->
    i.id = uuid.v4()
    return i
    
  messages = images.map (i) ->
    m =
      job: jobId
      payload: i
      created_at: created
      started_at: null
      completed_at: null
      failed_at: null
      error: null
    return m
  for message in messages
    req.participants.web.send 'resizeimage', message

  # Store images with ID on as part of job,
  # so we can correlate with id from worker
  imageMap = {}
  images.map (i) ->
    imageMap[i.id] = i    

  job =
    id: jobId
    data:
      images: imageMap
    created_at: new Date()

  jobs.create job
  .then () ->
    return res.location("/job/#{jobId}").status(202).end()
  .catch (err) ->
    return next err

setupApp = (app) ->
  app.participants =
    web: WebParticipant config.msgflo.broker, 'web'
    store: StoreParticipant config.msgflo.broker, 'store'

  app.use bodyParser.json
    limit: '1mb'

  app.use (req, res, next) ->
    req.participants = app.participants
    return next()

  # API routes
  app.get '/job/:id', routes.getJob
  app.post '/resize/', routes.resizeImages

  # 404 handler
  app.use (req, res, next) ->
    next new errors.HttpError "#{req.path} not found", 404
    return

  # Error handler
  app.use (err, req, res, next) ->
    debug 'error handler', err

    unless err.type is 'HttpError'
      # Convert regular errors to HTTP errors
      err = new errors.HttpError err.message, 500
    res.status err.code
    res.json
      message: err.message
      errors: err.errors if err.errors?
    return

  return app

startParticipant = (p) ->
  return bluebird.promisify(p.start, context: p)()

startWeb = (app, port) ->
  # Expose extra Bluebird methods
  bluebird.resolve().then () ->
    # wrapped for Exception safety
    return new Promise (resolve, reject) ->
      app.server = app.listen port, (err) ->
        return reject err if err
        return resolve app

exports.startServer = (port) ->
  app = express()
  bluebird.resolve().then () ->
    return setupApp app
  .then () ->
    return bluebird.all([
      startWeb app, port
      startParticipant app.participants.web
      startParticipant app.participants.store
    ]).then (array) ->
      return Promise.resolve app


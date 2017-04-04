express = require 'express'
bluebird = require 'bluebird'
bodyParser = require 'body-parser'
uuid = require 'uuid'
msgfloNodejs = require 'msgflo-nodejs'
debug = require('debug')('msgflo-imageresize:web')

config = require '../config'
errors = require './errors'

WebParticipant = (client, role) ->
  id = process.env.DYNO or uuid.v4()
  id = "#{role}-#{id}"

  definition =
    id: id
    component: 'imageresize/HttpApi'
    icon: 'code'
    label: 'Creates processing jobs from HTTP requests'
    inports: [
      { id: 'resizeimage', hidden: true } # for proxying data from .send() to outports through func()
    ]
    outports: [
      { id: 'resizeimage' }
    ]

  func = (inport, indata, send) ->
    # forward
    return send inport, null, indata

  return new msgfloNodejs.participant.Participant client, definition, func, role

routes = {}
routes.getJob = (req, res, next, jobId) ->
  return next()

routes.resizeImages = (req, res, next) ->
  # TODO: verify request payload with a JSON schema
  throw new error.HttpError "Missing .images array", 422 if not req.body.images

  jobId = uuid.v4()

  # Generate one AMQP message for each image,
  # so they can be processed independently by the worker
  images = req.body.images.map (i) ->
    i.id = uuid.v4()
  messages = images.map (m) ->
    m.job = jobId
  for message in messages
    req.participants.web.send 'resizeimage', message

  # Store images with ID on as part of job,
  # so we can correlate with id from worker
  job =
    id: jobId
    images: images
  # FIXME: persist job info to database

  return res.location("/job/#{jobId}").status(202).end()

setupApp = (app) ->
  app.participants =
    web: WebParticipant config.msgflo.broker, 'api'

  app.use bodyParser.json
    limit: '1mb'

  app.use (req, res, next) ->
    req.participants = app.participants
    return next()

  # API routes
  app.post '/resize/', routes.resizeImages
  app.get '/job/:id', routes.getJob

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
        console.log 'listening', port
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
    ]).then (array) ->
      return Promise.resolve app


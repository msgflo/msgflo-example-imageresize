express = require 'express'
bluebird = require 'bluebird'
bodyParser = require 'body-parser'
debug = require('debug')('msgflo-imageresize:web')

config = require '../config'
errors = require './errors'

routes = {}
routes.getJob = (req, res, next, jobId) ->
  return next()

routes.resizeImages = (req, res, next) ->
  return next()

setupApp = (app) ->
  app.use bodyParser.json
    limit: '1mb'

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

startWeb = (port) ->
  # Expose extra Bluebird methods
  bluebird.resolve().then () ->
    # wrapped for Exception safety
    app = express()
    app = setupApp app
    return new Promise (resolve, reject) ->
      app.server = app.listen port, (err) ->
        return reject err if err
        return resolve app

exports.startServer = (port) ->
  return startWeb port


msgfloNodejs = require 'msgflo-nodejs'
bluebird = require 'bluebird'
debug = require('debug')('imageresize:ResizeImage')

config = require '../config'
resize = require '../src/resize'

ResizeImage = (client, role) ->

  definition =
    component: 'imageresize/ResizeImage'
    icon: 'file-word-o'
    label: 'Resize an image given a URL and upload results'
    inports: [
      id: 'in'
      type: 'object'
    ]
    outports: [
      id: 'out'
      type: 'object'
    ,
      id: 'error'
      type: 'object'
    ]

  processFunc = (inport, indata, callback) ->
    out = exports.clone indata
    out.started_at = new Date()

    resize.resizeImageAndUpload(indata)
    .timeout config.resize.timeout, 'Resizing timed out'
    .asCallback (err, resizedUrl) ->
      if err
        console.error 'resize error', indata.id, err
        out.error = common.serializeError err
        out.failed_at = new Date()
        return callback 'error', err, out if err

      debug 'succeeded', indata.id, resizedUrl
      out.completed_at = new Date()
      out.result =
        output: resizedUrl
      return callback 'out', null, out

  p = new msgfloNodejs.participant.Participant client, definition, processFunc, role
  p.messaging.options.prefetch = config.resize.concurrent
  return p

module.exports = ResizeImage

msgfloNodejs = require 'msgflo-nodejs'
bluebird = require 'bluebird'
debug = require('debug')('imageresize:ResizeImage')

config = require '../config'
jobs = require '../src/jobs'
common = require '../src/common'

storeImageResult = (data) ->
  imageData = {} # FIXME: proper
  return jobs.imageProcessed imageData

StoreResult = (client, role) ->

  definition =
    component: 'imageresize/StoreResult'
    icon: 'file-word-o'
    label: 'Store the result of worker resizing image'
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
    out = common.clone indata

    storeImageResult(indata)
    .timeout config.store.timeout, 'store timed out'
    .asCallback (err, r) ->
      out.stored_at = new Date()
      if err
        console.error 'store error', indata.id, err
        return callback 'error', err, out if err

      debug 'stored', indata.id, indata
      return callback 'out', null, out

  p = new msgfloNodejs.participant.Participant client, definition, processFunc, role
  p.messaging.options.prefetch = config.store.concurrent
  return p

module.exports = StoreResult

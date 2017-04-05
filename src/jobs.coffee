
bluebird = require 'bluebird'

db = require '../db'

exports.create = (job) ->
  return bluebird.resolve()
  .then () ->
    throw new Error "Missing .data" if not job.data
    throw new Error "Missing .data.images" if not job.data.images
    throw new Error ".data.images must be a non-empty object" if not Object.keys(job.data.images).length
    return db('jobs').insert job

exports.get = (jobId) ->
  return bluebird.resolve()
  .then () ->
    throw new Error "Missing job ID" if not jobId
    db('jobs').select('*').where 'id', jobId
    .then (rows) ->
      return Promise.reject new Error "Returned more than one result" if rows.length > 1
      return rows[0]

exports.isCompleted = (job) ->

exports.imageProcessed = (jobId, result) ->
  # FIXME: implement
  return bluebird.resolve()


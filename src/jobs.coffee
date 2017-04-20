
bluebird = require 'bluebird'
knex = require 'knex'

db = require '../db'
common = require './common'

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
  imageCompleted = (image) ->
    return image.failed_at or image.completed_at

  all = common.objectValues job.images
  completed = all.filter imageCompleted
  notCompleted = all.filter (i) -> not imageCompleted i
  remaining = all.length-completed.length
  return remaining == 0

exports.imageProcessed = (jobId, data) ->
  bluebird.resolve().then () ->
    # Sanity-check data
    throw new Error "Job id not a string" if typeof jobId != 'string'
    throw new Error "Image id not a string" if typeof data.id != 'string'
    if data.error
      throw new Error ".error.message is not a string: #{data.error.message}" if typeof data.error.message != 'string'
    else
      output = data.result?.output
      throw new Error "Missing .result.output" if not output
      throw new Error " .result.output is not a string" if typeof output != 'string'
      throw new Error " .result.output '#{output}' is not an URL" if output.indexOf('https://') != 0
  .then () ->
    imageId = data.id

    # XXX: because we are not using, we need to do a big-fat-lock here.
    db.transaction (trx) ->
      db('jobs').transacting(trx)
      .select 'data'
      .forUpdate()
      .where 'id', jobId
      .then (rows) ->
        throw new Error "Returned #{rows.length} rows for job #{jobId}" if rows.length > 1
        throw new Error "Could not find job #{jobId}" if rows.length < 1
        old = rows[0].data
        image = old.images[imageId]
        for k, v of data
          image[k] = v
        return db('jobs').transacting(trx)
          .where 'id', jobId
          .update 'data', old
      .then (trx.commit)
      .catch (trx.rollback)
  .then (r) ->
    return data


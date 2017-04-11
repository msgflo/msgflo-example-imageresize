arrivals = require 'arrivals'
requestPromise = require 'request-promise'
bluebird = require 'bluebird'

common = require './common'

endedAt = (image) ->
  return if image.failed_at 
    new Date image.failed_at
  else
    new Date image.completed_at

processingTime = (image) ->
  start = new Date image.started_at
  end = endedAt image 
  return end.getTime() - start.getTime()
waitingTime = (image) ->
  start = new Date image.created_at
  end = new Date image.started_at
  return end.getTime() - start.getTime()

sortEndtime = (a, b) ->
  [A, B] = [endedAt(a), endedAt(b)]
  return A.getTime() - B.getTime()

calculateStats = (job) ->

  # FIXME: set job failed/completed_at on API-side
  # TODO: also set job started_at
  imagesCompleted = common.objectValues(job.data.images).sort sortEndtime
  lastCompleted = imagesCompleted[imagesCompleted.length-1]
  jobEnd = endedAt lastCompleted
  jobTime = jobEnd.getTime() - (new Date job.created_at).getTime()
  job.total = jobTime

  for id, image of job.data.images
    image.created_at = job.created_at # FIXME: set image created_at API-side
    image.waiting = waitingTime image
    image.processing = processingTime image

  return job

main = () ->
  [node, script, jobUrl] = process.argv
  if not jobUrl 
    console.error "Usage: stats JOBURL"

  requestPromise { url: jobUrl, json: true }
  .then calculateStats
  .then (stats) ->
    console.log JSON.stringify stats, null, 2

main() if not module.parent

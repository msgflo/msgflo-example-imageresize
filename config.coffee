envvar = (key, defaultValue) ->
  val = process.env[key]
  return if val? then val else defaultValue

module.exports =
  msgflo:
    broker: process.env.CLOUDAMQP_URL or process.env.MSGFLO_BROKER or 'amqp://localhost'
  resize:
    timeout: parseInt envvar('IMAGERESIZE_TIMEOUT', 10) # seconds before aborting
    concurrent: parseInt envvar('IMAGERESIZE_CONCURRENT', 5) # number of concurrent jobs

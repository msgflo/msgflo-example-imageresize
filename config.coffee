envvar = (key, defaultValue) ->
  val = process.env[key]
  return if val? then val else defaultValue

module.exports =
  msgflo:
    broker: process.env.CLOUDAMQP_URL or process.env.MSGFLO_BROKER or 'amqp://localhost'
  resize:
    timeout: 1000*parseInt(envvar('IMAGERESIZE_RESIZE_TIMEOUT', 10)) # time before aborting
    concurrent: parseInt(envvar('IMAGERESIZE_RESIZE_CONCURRENT', 5)) # number of concurrent jobs
  store:
    timeout: 1000*parseInt(envvar('IMAGERESIZE_STORE_TIMEOUT', 10)) # time before aborting
    concurrent: parseInt(envvar('IMAGERESIZE_STORE_CONCURRENT', 5)) # number of concurrent jobs
  database:
    url: envvar('DATABASE_URL', 'postgres://postgres:@localhost/imageresize_test')

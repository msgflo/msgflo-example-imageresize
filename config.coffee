envvar = (key, defaultValue) ->
  val = process.env[key]
  return if val? then val else defaultValue

module.exports =
  msgflo:
    broker: process.env.CLOUDAMQP_URL or process.env.MSGFLO_BROKER or 'amqp://localhost'
  s3:
    key: process.env.BUCKETEER_AWS_ACCESS_KEY_ID or process.env.IMAGERESIZE_S3_KEY
    secret: process.env.BUCKETEER_AWS_SECRET_ACCESS_KEY or process.env.IMAGERESIZE_S3_SECRET
    bucket: process.env.BUCKETEER_BUCKET_NAME or process.env.IMAGERESIZE_S3_BUCKET
    prefix: process.env.IMAGERESIZE_S3_PREFIX or 'public/images/'
    region: process.env.IMAGERESIZE_S3_REGION or 'us-east-1'
  resize:
    timeout: 1000*parseInt(envvar('IMAGERESIZE_RESIZE_TIMEOUT', 10)) # time before aborting
    concurrent: parseInt(envvar('IMAGERESIZE_RESIZE_CONCURRENT', 5)) # number of concurrent jobs
  store:
    timeout: 1000*parseInt(envvar('IMAGERESIZE_STORE_TIMEOUT', 10)) # time before aborting
    concurrent: parseInt(envvar('IMAGERESIZE_STORE_CONCURRENT', 5)) # number of concurrent jobs
  database:
    url: envvar('DATABASE_URL', 'postgres://postgres:@localhost/imageresize_test')

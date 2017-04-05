# Actual resizing functionality

sharp = require 'sharp'
knox = require 'knox'
request = require 'request'
fs = require 'fs'
uuid = require 'uuid'
bluebird = require 'bluebird'
path = require 'path'

common = require './common'
config = require '../config'

# Returns a Stream transformer which resizes image input data
# and outputs a new image within the specified @height / @width
# http://sharp.dimens.io/en/stable/api-resize/#resize
exports.createResizer = (width, height, options = {}) ->
  throw new Error "Height not specified" if not height?
  throw new Error "Width not specified" if not width?

  defaultOptions =
    policy: 'max'
    format: 'jpeg'
  for k, v of defaultOptions
    options[k] = v if not options[k]?

  if options.policy not in ['max']
    throw new Error "Unsupported policy '#{options.policy}'"
  if options.format not in ['jpeg', 'png']
    throw new Error "Unsupported format '#{options.format}'"

  transformer = sharp()
    .resize(height, width)
    .toFormat(options.format)
  transformer.max()
  return transformer

uploadS3 = (buffer, path, headers={}) ->
  client = knox.createClient config.s3
  bluebird.promisify(client.putBuffer, context: client)(buffer, path, headers)

exports.resizeImageAndUpload = (image) ->
  bluebird.resolve()
  .then () ->
    throw new Error "Missing .input URL" if not image?.input
    throw new Error "Missing .id for image" if not image?.id

    reader = request image.input
    options =
      format: image.format or 'jpeg'
      policy: image.policy
    resizer = exports.createResizer image.width, image.height, options
    outputPath = path.join config.s3.prefix, "#{image.id}.#{options.format}"
    reader.pipe(resizer)
    resizer.toBuffer()
    .then (buffer) ->
      return uploadS3 buffer, outputPath
    .then () ->
      return "https://#{config.s3.bucket}.s3.amazonaws.com/#{outputPath}"

main = () ->
  [node, script, input, width, height] = process.argv
  if not (input and height and width)
    console.error 'Usage: imageresizer-resize-file http://example.net/URL.jpg height width'
    process.exit 1
  
  image =
    id: uuid.v4()
    height: parseInt height
    width: parseInt width
    input: input

  exports.resizeImageAndUpload image
  .asCallback (err, output) ->
    if err
      console.error err
      process.exit 2
    console.log "Wrote #{output}"

main() if not module.parent

# Actual resizing functionality

sharp = require 'sharp'
request = require 'request'
fs = require 'fs'
uuid = require 'uuid'
bluebird = require 'bluebird'

common = require './common'

# Returns a Stream transformer which resizes image input data
# and outputs a new image within the specified @height / @width
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

exports.resizeImageAndUpload = (image) ->
  bluebird.resolve()
  .then () ->
    throw new Error "Missing .input URL" if not image?.input

    reader = request image.input
    options =
      format: image.format
      policy: image.policy
    resizer = exports.createResizer image.width, image.height, options
    writer = fs.createWriteStream "#{image.id}.jpg" # FIXME: actually upload somewhere
    reader.pipe(resizer)
    resizer.pipe(writer)

    return common.streamEnd writer

main = () ->
  [node, script, input, output, width, height] = process.argv
  if not (input and output and height and width)
    console.error 'Usage: imageresizer-resize-file http://example.net/URL.jpg OUTPUT.jpg height width'
    process.exit 1
  
  image =
    id: uuid.v4()
    height: parseInt height
    width: parseInt width
    input: input

  exports.resizeImageAndUpload image
  .asCallback (err, r) ->
    if err
      console.error err
      process.exit 2
    console.log "Wrote #{output}"

main() if not module.parent

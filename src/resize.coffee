# Actual resizing functionality

sharp = require 'sharp'
request = require 'request'
fs = require 'fs'

# Returns a Stream transformer which resizes image input data
# and outputs a new image within the specified @height / @width
exports.createResizer = (height, width, options = {}) ->
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

main = () ->
  [node, script, input, output, height, width] = process.argv
  if not (input and output and height and width)
    console.error 'Usage: imageresizer-resize-file http://example.net/URL.jpg OUTPUT.jpg height width'
    process.exit 1
  
  reader = request input
  resizer = exports.createResizer Number(height), Number(width)
  writer = fs.createWriteStream output
  reader.pipe(resizer)
  resizer.pipe(writer)

  writer.on 'end', () ->
    console.log "Wrote #{output}"
  writer.on 'error', (err) ->
    console.error err
    process.exit 2

main() if not module.parent

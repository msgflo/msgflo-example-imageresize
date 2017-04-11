
# Default JSON serialization for Error is empty
exports.serializeError = (err) ->
  s =
    message: err.message
    stack: err.stack
  return s

exports.clone = (obj) ->
  return JSON.parse JSON.stringify obj

exports.streamEnd = (stream) ->
  return new Promise (reject, resolve) ->
    stream.on 'end', () ->
      return resolve()
    stream.on 'error', (err) ->
      return reject err

# polyfill for Object.values...
exports.objectValues = (obj) ->
  vals = []
  for key, val of obj
    vals.push val
  return vals

class HttpError extends Error
  type: 'HttpError'
  constructor: (message, code = 500) ->
    @code = code
    @message = message
    super message

exports.HttpError = HttpError

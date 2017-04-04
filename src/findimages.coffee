# A tool to find the images on a webpage
requestPromise = require 'request-promise'
cheerio = require 'cheerio'
bluebird = require 'bluebird'

# NOTE: not recursive
resolveRedirect = (url) ->
  req =
    uri: url
    simple: false
    resolveWithFullResponse: true
    followRedirect: false
    timeout: 10*1000
  requestPromise req
  .then (response) ->
    if response.statusCode == 301
      location = response.headers['location']
      return location or Promise.reject 'Redirect did not set Location'
    else
      return url

findImages = (url, options = {}) ->
  req =
    uri: url
    transform: (body) ->
      return cheerio.load body
  requestPromise req
  .then (ch) ->
    return ch('img').get().map (e) -> e.attribs['src']
  .then (images) ->
    # resolve redirects, if any
    bluebird.map images, (src) ->
      return resolveRedirect src

main = () ->
  [node, script, url] = process.argv

  if not url
    console.error "Usage: msgflo-imageresize-findimages http://example.net/foo.html"
    process.exit 1

  findImages(url).asCallback (err, images) ->
    if err
      console.error err
      process.exit 2
    console.log JSON.stringify images, null, 2

main() if not module.parent

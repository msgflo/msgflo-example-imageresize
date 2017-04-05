uuid = require 'uuid'
msgfloNodejs = require 'msgflo-nodejs'
debug = require('debug')('imageresize:WebParticipant')

WebParticipant = (client, role) ->
  id = process.env.DYNO or uuid.v4()
  id = "#{role}-#{id}"

  definition =
    id: id
    component: 'imageresize/HttpApi'
    icon: 'code'
    label: 'Creates processing jobs from HTTP requests'
    inports: [
      { id: 'resizeimage', hidden: true } # for proxying data from .send() to outports through func()
    ]
    outports: [
      { id: 'resizeimage' }
    ]

  func = (inport, indata, send) ->
    # forward
    debug 'sending', inport, indata.job, indata.payload.id
    return send inport, null, indata

  return new msgfloNodejs.participant.Participant client, definition, func, role

module.exports = WebParticipant

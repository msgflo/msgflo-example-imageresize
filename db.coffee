Knex = require 'knex'
config = require './config'
url = require 'url'

# Parse DB URL
dbConfig = url.parse config.database.url
connection =
  charset: 'utf8'

# Normalize config
switch dbConfig.protocol
  when 'postgres:'
    provider = 'pg'
    [user, pass] = dbConfig.auth.split ':'
    connection.host = dbConfig.hostname
    connection.user = user
    connection.password = pass
    connection.database = dbConfig.path.substr 1
    connection.port = dbConfig.port

module.exports = Knex
  client: provider
  connection: connection
  pool:
    min: 1
    max: 4
  useNullAsDefault: true
  # debug: true

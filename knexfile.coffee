config = require './config'
url = require 'url'

dbConfig = url.parse config.database.url
[user, pass] = dbConfig.auth.split ':'
switch dbConfig.protocol
  when 'postgres:'
    cfg =
      client: 'postgresql'
      connection:
        host: dbConfig.hostname
        port: dbConfig.port
        database: dbConfig.path.substr 1
        user:     user
        password: pass
      pool:
        min: 2
        max: 10
      migrations:
        tableName: 'knex_migrations'

module.exports =
  development: cfg
  staging: cfg
  production: cfg

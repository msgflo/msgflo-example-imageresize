exports.up = (knex, Promise) ->
  knex.schema.createTable 'jobs', (t) ->
    # Job UUID
    t.uuid('id').primary()

    # Timestamp info
    t.timestamps()
    # When whole job completed
    t.timestamp('completed_at').index()
    # When whole job failed
    t.timestamp('failed_at').index()

    # Data associated with this job
    # XXX: a bit quick & dirty
    # Normally one would have a separate table for the images, with a foreign key referring the job
    t.jsonb('data')

exports.down = (knex, Promise) ->
  knex.schema.dropTableIfExists 'jobs'

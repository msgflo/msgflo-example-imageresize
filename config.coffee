module.exports =
  msgflo:
    broker: process.env.CLOUDAMQP_URL or process.env.MSGFLO_BROKER or 'amqp://localhost'

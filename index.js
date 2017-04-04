require('coffee-script/register');
var app = require('./src/app');

var port = process.env.PORT || 6666;
app.startServer(port).asCallback(function(err) {
  if (err) throw err
  console.log('Running on port', port);
});

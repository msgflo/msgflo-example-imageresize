var path = require("path");
module.exports = {
  entry: './browser.js',
  output: {
    path: path.join(__dirname, "assets"),
    publicPath: "assets/",
    filename: "imageresize.js",
    library: 'imageresize',
    libraryTarget: 'umd'
  },
  externals: {
  },
  node: {
    'fs': 'empty',
    'tls': 'empty',
    'net': 'empty'
  },
  module: {
    loaders: [
      { test: /\.coffee$/, loader: "coffee-loader" },
    ]
  },
  resolve: {
    extensions: [".coffee", ".js"]
  },
};

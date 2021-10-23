const HtmlWebpackPlugin = require('html-webpack-plugin');
const path = require('path');

module.exports = {
  mode: 'development',
  entry: './src/index.ts',
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: [/node_modules/, /elm-stuff/],
      },
      {
        test: /\.css$/i,
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.(csv|png|svg|jpg|jpeg|gif)$/i,
        type: 'asset/resource',
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: {
          loader: 'elm-webpack-loader',
          options: {}
        }
      }
    ],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js', '.elm'],
  },
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'docs'),
  },
  devServer: {
    compress: true,
    port: 8000,
  },
  plugins: [new HtmlWebpackPlugin({
    template: 'src/index.html',
    filename: 'index.html',
  })],
};

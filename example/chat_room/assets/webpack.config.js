const path = require('path');
const glob = require('glob');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new TerserPlugin({
        terserOptions: {
          ecma: 5,
          compress: {
            pure_funcs: [
              "F2",
              "F3",
              "F4",
              "F5",
              "F6",
              "F7",
              "F8",
              "F9",
              "A2",
              "A3",
              "A4",
              "A5",
              "A6",
              "A7",
              "A8",
              "A9"
            ],
            pure_getters: true,
            keep_fargs: false,
            unsafe_comps: true,
            unsafe: true,
            passes: 2
          },
          mangle: true
        }
      })
    ]
  },
  entry: {
      './js/app.js': ['./js/app.js'].concat(glob.sync('./vendor/**/*.js'))
  },
  output: {
    filename: 'app.js',
    path: path.resolve(__dirname, '../priv/static/js')
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader']
      },
      {
      test: /\.elm$/,
      exclude: [/elm-stuff/, /node_modules/],
      use: {
        loader: 'elm-webpack-loader',
        options: {
            cwd: __dirname + '/elm/',
            //debug: options.mode === "development",
            optimize: options.mode === "production"
          }
        }
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: '../css/app.css' }),
    new CopyWebpackPlugin([{ from: 'static/', to: '../' }])
  ]
});

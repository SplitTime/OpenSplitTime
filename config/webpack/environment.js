const { environment } = require('@rails/webpacker')
const webpack = require('webpack')
const WebpackAssetsManifest = require('webpack-assets-manifest');

module.exports = environment

environment.config.merge({
    externals: {
        jquery: 'jQuery',
    },
})
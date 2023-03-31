const { environment } = require('@rails/webpacker')
const webpack = require("webpack")
const WebpackAssetsManifest = require("webpack-assets-manifest");

environment.plugins.append('Provide', new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    'window.jQuery': 'jquery',
}))

module.exports = environment

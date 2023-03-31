const { environment } = require("@rails/webpacker")
const webpack = require("webpack")
const WebpackAssetsManifest = require("webpack-assets-manifest");

environment.config.merge({
    externals: {
        jquery: "jQuery",
    },
})

module.exports = environment

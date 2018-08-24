const { environment } = require('@rails/webpacker')
const webpack = require('webpack')

module.exports = environment

environment.config.merge({
    externals: {
        jquery: 'jQuery',
    },
})
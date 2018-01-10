const Utils = require('utils');
const defaults = require('lodash/defaults');
const defaultConfig = {
    baseUrl: '/',
};

class JSONAPI {
    constructor(apiConfig) {
        Utils.const(this, 'config', defaults({}, apiConfig, defaultConfig));
    }

    /**
     * 
     * @param {*} modelConfig 
     */
    define(modelConfig) {

    }
}

module.exports = JSONAPI;

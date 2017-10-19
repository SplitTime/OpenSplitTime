const JSONAPI = require('jsonapi');
const apiConfig = {
    baseUrl: '/api/v1'
};

console.log(new JSONAPI(apiConfig));
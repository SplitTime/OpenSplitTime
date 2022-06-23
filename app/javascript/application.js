// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
// import "./vue_controllers"
// import * as bootstrap from "bootstrap"

require("@hotwired/turbo-rails")

import "./src/jquery"
// import "./src/jquery-ui"

$(function () {
    console.log("hello world")
})

import './src/utils/growl';
import "chartkick/chart.js";

import Vue from "vue";
import TurboLinksAdapter from 'vue-turbolinks';

Vue.use(TurboLinksAdapter);

import {Application} from "@hotwired/stimulus"

const application = Application.start()
const context = require.context("controllers", true, /.js$/)

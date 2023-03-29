/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

require("@hotwired/turbo-rails")

import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

import { preferredDistanceUnit, preferredElevationUnit, distanceToPreferred, elevationToPreferred } from 'utils/units';
global.preferredDistanceUnit = preferredDistanceUnit;
global.preferredElevationUnit = preferredElevationUnit;
global.distanceToPreferred = distanceToPreferred;
global.elevationToPreferred = elevationToPreferred;

import 'utils/growl';
import "chartkick/chart.js";
import Inputmask from "inputmask/dist/jquery.inputmask.min";

import TurboLinksAdapter from 'vue-turbolinks';
Vue.use(TurboLinksAdapter);

import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

const application = Application.start()
const context = require.context("controllers", true, /.js$/)
application.load(definitionsFromContext(context))

// Initialize Bootstrap tooltips
document.addEventListener("turbo:load", () => {
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })
})

// Expand the default allowList for Bootstrap tooltips and popovers
let myDefaultAllowList = bootstrap.Tooltip.Default.allowList;

myDefaultAllowList.table = [];
myDefaultAllowList.tr = [];
myDefaultAllowList.td = [];
myDefaultAllowList.th = [];
myDefaultAllowList.tbody = [];
myDefaultAllowList.thead = [];


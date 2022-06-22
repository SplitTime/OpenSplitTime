// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

require("@hotwired/turbo-rails")

import { preferredDistanceUnit, preferredElevationUnit, distanceToPreferred, elevationToPreferred } from 'utils/units';
global.preferredDistanceUnit = preferredDistanceUnit;
global.preferredElevationUnit = preferredElevationUnit;
global.distanceToPreferred = distanceToPreferred;
global.elevationToPreferred = elevationToPreferred;

import 'utils/growl';
import "chartkick/chart.js";

import TurboLinksAdapter from 'vue-turbolinks';
Vue.use(TurboLinksAdapter);

import { Application } from "@hotwired/stimulus"

const application = Application.start()
const context = require.context("controllers", true, /.js$/)

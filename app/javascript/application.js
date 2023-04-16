// Entry point for the build script in your package.json

// Sentry error reporting
// import * as Sentry from "@sentry/browser";
//
// Sentry.init({
//   dsn: "https://75503de427ae47638046edde0174a0ea@o361209.ingest.sentry.io/3805803",
//   release: process.env.npm_package_version,
//   integrations: [new Sentry.BrowserTracing()],
//
//   // Set tracesSampleRate to 1.0 to capture 100%
//   // of transactions for performance monitoring.
//   // We recommend adjusting this value in production
//   tracesSampleRate: 1.0,
// });

import "@hotwired/turbo-rails"
import "./controllers"

// Turbo-Rails
require("@hotwired/turbo-rails")

// ActiveStorage
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

// Preferred units
import { preferredDistanceUnit, preferredElevationUnit, distanceToPreferred, elevationToPreferred } from "./src/utils/units";

window.preferredDistanceUnit = preferredDistanceUnit;
window.preferredElevationUnit = preferredElevationUnit;
window.distanceToPreferred = distanceToPreferred;
window.elevationToPreferred = elevationToPreferred;

// Miscellaneous imports
import "./src/utils/growl";
import "./src/chartkick/chart.js";
import Inputmask from "inputmask/dist/jquery.inputmask";
import "datatables.net-bs5";

// Live Entry
import "./src/live_entry/index";

// reloadWithTurbo
import { reloadWithTurbo } from "./src/utils/reload_with_turbo"
window.reloadWithTurbo = reloadWithTurbo()

// jQuery
import $ from 'jquery';
window.$ = $
window.jQuery = $

// Stimulus
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

const application = Application.start()
const context = require.context("controllers", true, /.js$/)
application.load(definitionsFromContext(context))

// Rails.ujs
import Rails from '@rails/ujs';
Rails.start();

// Bootstrap and Popper.js
require("@popperjs/core")
import * as bootstrap from "bootstrap"

// Expand the default allowList for Bootstrap tooltips and popovers
let myDefaultAllowList = Tooltip.Default.allowList;

myDefaultAllowList.table = [];
myDefaultAllowList.tr = [];
myDefaultAllowList.td = [];
myDefaultAllowList.th = [];
myDefaultAllowList.tbody = [];
myDefaultAllowList.thead = [];

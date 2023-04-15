/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag "application" %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

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

// Turbo-Rails
require("@hotwired/turbo-rails")

// ActiveStorage
import * as ActiveStorage from "@rails/activestorage"

ActiveStorage.start()

// Preferred units
import { preferredDistanceUnit, preferredElevationUnit, distanceToPreferred, elevationToPreferred } from "utils/units";

global.preferredDistanceUnit = preferredDistanceUnit;
global.preferredElevationUnit = preferredElevationUnit;
global.distanceToPreferred = distanceToPreferred;
global.elevationToPreferred = elevationToPreferred;

// Miscellaneous imports
import "utils/growl";
import "chartkick/chart.js";
import Inputmask from "inputmask/dist/jquery.inputmask";
import "datatables.net-bs5";

// jQuery
import $ from 'jquery';

global.$ = $
global.jQuery = $
require('jquery-ui');

// jquery-ui theme
require.context('file-loader?name=[path][name].[ext]&context=node_modules/jquery-ui-dist!jquery-ui-dist', true,    /jquery-ui\.css/ );
require.context('file-loader?name=[path][name].[ext]&context=node_modules/jquery-ui-dist!jquery-ui-dist', true,    /jquery-ui\.theme\.css/ );

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
import "bootstrap"
import { Tooltip } from "bootstrap"

// Expand the default allowList for Bootstrap tooltips and popovers
let myDefaultAllowList = Tooltip.Default.allowList;

myDefaultAllowList.table = [];
myDefaultAllowList.tr = [];
myDefaultAllowList.td = [];
myDefaultAllowList.th = [];
myDefaultAllowList.tbody = [];
myDefaultAllowList.thead = [];

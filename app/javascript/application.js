// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Sentry
import * as Sentry from "@sentry/browser";

Sentry.init({
  dsn: "https://75503de427ae47638046edde0174a0ea@o361209.ingest.sentry.io/3805803",

  // Alternatively, use `process.env.npm_package_version` for a dynamic release version
  // if your build tool supports it.
  release: "opensplittime",
  integrations: [new Sentry.BrowserTracing(), new Sentry.Replay()],

  // Set tracesSampleRate to 1.0 to capture 100%
  // of transactions for performance monitoring.
  // We recommend adjusting this value in production
  tracesSampleRate: 1.0,

  // Set `tracePropagationTargets` to control for which URLs distributed tracing should be enabled
  tracePropagationTargets: ["localhost", /^https:\/\/ost-stage\.herokuapp\.com/, /^https:\/\/opensplittime\.org/],

  // Capture Replay for 10% of all sessions,
  // plus for 100% of sessions with an error
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
});

// ActiveStorage
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

// Chartkick
import "chartkick/chart.js"

// Inputmask
import Inputmask from "inputmask/dist/inputmask";

Inputmask.extendAliases({
  "military": {
    alias: "datetime",
    inputFormat: "HH:MM:ss",
    placeholder: "hh:mm:ss",
    insertMode: false,
    showMaskOnHover: false,
  },
  "elapsed": {
    alias: "datetime",
    inputFormat: "H2:MM:ss",
    placeholder: "hh:mm:ss",
    insertMode: false,
    showMaskOnHover: false,
  },
  "elapsed_without_seconds": {
    alias: "datetime",
    inputFormat: "H2:MM",
    placeholder: "hh:mm",
    insertMode: false,
    showMaskOnHover: false,
  },
  "datetime_us": {
    alias: "datetime",
    inputFormat: "mm/dd/yyyy HH:MM:ss",
    placeholder: "mm/dd/yyyy hh:mm:ss",
    insertMode: false,
    showMaskOnHover: true,
  },
  "date_us": {
    alias: "datetime",
    inputFormat: "mm/dd/yyyy",
    placeholder: "mm/dd/yyyy",
    insertMode: false,
    showMaskOnHover: true,
  },
  "bib_number": {
    regex: "[0-9|*]{0,6}"
  },
  "lap_number": {
    alias: "integer",
    rightAlign: false,
    nullable: true,
    min: 1,
    max: undefined
  }
})

// reloadWithTurbo
import { reloadWithTurbo } from "./src/utils/reload_with_turbo"
window.reloadWithTurbo = reloadWithTurbo()

// Bootstrap and Popper.js
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
myDefaultAllowList.div = [];

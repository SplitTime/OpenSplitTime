// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// ActiveStorage
import * as ActiveStorage from "@rails/activestorage"

ActiveStorage.start()

// Preferred units
import { preferredDistanceUnit, preferredElevationUnit, distanceToPreferred, elevationToPreferred } from "./src/utils/units";

global.preferredDistanceUnit = preferredDistanceUnit;
global.preferredElevationUnit = preferredElevationUnit;
global.distanceToPreferred = distanceToPreferred;
global.elevationToPreferred = elevationToPreferred;

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

global.reloadWithTurbo = reloadWithTurbo()

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
import * as bootstrap from "bootstrap"

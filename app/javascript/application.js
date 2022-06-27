// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

require("@hotwired/turbo-rails")

// https://gorails.com/episodes/how-to-use-jquery-with-esbuild
import "./src/jquery"
import "./src/jquery-ui"

import "./src/utils/growl";

import "chartkick/chart.js";

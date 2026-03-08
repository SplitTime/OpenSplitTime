import { Controller } from "@hotwired/stimulus"
import { Tooltip } from "bootstrap"

// Patch Bootstrap Tooltip to prevent crash when transition callback
// fires on elements that Turbo has already removed from the DOM.
const origIsWithActiveTrigger = Tooltip.prototype._isWithActiveTrigger
Tooltip.prototype._isWithActiveTrigger = function () {
  if (!this._activeTrigger) return false
  return origIsWithActiveTrigger.call(this)
}

export default class extends Controller {
  connect() {
    this.tooltip = new Tooltip(this.element)
  }

  disconnect() {
    if (this.tooltip) {
      this.tooltip.tip?.remove()
      this.tooltip.dispose()
      this.tooltip = null
    }
  }
}

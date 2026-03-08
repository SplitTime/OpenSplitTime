import { Controller } from "@hotwired/stimulus"
import { Tooltip } from "bootstrap"

// Patch Bootstrap Tooltip to prevent crashes when Turbo replaces DOM
// elements that have active tooltip transitions. The transition's
// complete callback fires after dispose() has nulled internal state.
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
      // Keep references that the pending transition complete callback needs
      const element = this.tooltip._element
      this.tooltip.tip?.remove()
      this.tooltip.dispose()
      // Restore _element so complete callback's removeAttribute doesn't crash
      this.tooltip._element = element
      this.tooltip = null
    }
  }
}

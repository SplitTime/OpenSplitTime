import { Controller } from "@hotwired/stimulus"
import { Tooltip } from "bootstrap"

// Patch Bootstrap Tooltip to prevent crashes when transition callbacks
// fire on elements that Turbo has already removed from the DOM.
const origHide = Tooltip.prototype._hide
Tooltip.prototype._hide = function (...args) {
  if (!this._element || !this._element.isConnected) return
  origHide.call(this, ...args)
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

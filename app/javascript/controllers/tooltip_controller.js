import { Controller } from "@hotwired/stimulus"
import { Tooltip } from "bootstrap"

export default class extends Controller {
  connect() {
    this.tooltip = new Tooltip(this.element)
  }

  disconnect() {
    if (this.tooltip) {
      // Nullify internal state before disposal to prevent errors
      // when Bootstrap's transition callback fires on removed elements
      this.tooltip._activeTrigger = {}
      this.tooltip.tip?.remove()
      this.tooltip.dispose()
      this.tooltip = null
    }
  }
}

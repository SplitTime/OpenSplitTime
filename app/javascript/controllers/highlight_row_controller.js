import { Controller } from "@hotwired/stimulus"
import { effortHighlighted, toggleHighlightedEffort } from "../src/utils/highlight_store"

// Lives on each highlightable row. Applying state on connect means rows
// replaced by Turbo broadcasts re-apply their own highlight automatically.
export default class extends Controller {
  static targets = ["icon"]
  static values = { effortId: Number, group: Number }

  connect() {
    this.apply()
  }

  toggle() {
    toggleHighlightedEffort(this.groupValue, this.effortIdValue)
    this.apply()
    window.dispatchEvent(new CustomEvent("highlights:changed"))
  }

  apply() {
    const highlighted = effortHighlighted(this.groupValue, this.effortIdValue)

    this.element.classList.toggle("effort-highlighted", highlighted)
    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("text-warning", highlighted)
      this.iconTarget.classList.toggle("text-secondary", !highlighted)
    }
  }
}

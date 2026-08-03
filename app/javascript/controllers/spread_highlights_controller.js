import { Controller } from "@hotwired/stimulus"
import { clearHighlightedEfforts, highlightedEffortIds, mergeHighlightedEfforts } from "../src/utils/highlight_store"

// Coordinates the highlight controls above the spread table: the count
// chip, the show-only filter, and clearing. Individual rows manage their
// own state via highlight_row_controller; this controller and the rows
// stay in sync through the window-level highlights:changed event.
export default class extends Controller {
  static targets = ["chip", "countText", "onlyButton"]
  static values = { group: Number }

  connect() {
    this.seedFromFragment()
    this.refresh()
  }

  // Arriving via a shared #highlight= link while already on the page is
  // a hash-only change with no reload, so connect() never re-fires
  onHashChange() {
    this.seedFromFragment()
    window.dispatchEvent(new CustomEvent("highlights:changed"))
  }

  refresh() {
    const count = highlightedEffortIds(this.groupValue).length

    this.chipTarget.classList.toggle("d-none", count === 0)
    this.countTextTarget.textContent = `${count} highlighted`
    if (count === 0) this.showAll()
  }

  toggleOnly() {
    if (this.element.classList.contains("highlights-only")) {
      this.showAll()
    } else {
      this.element.classList.add("highlights-only")
      this.onlyButtonTarget.classList.add("active")
      this.onlyButtonTarget.setAttribute("aria-pressed", "true")
    }
  }

  clear() {
    clearHighlightedEfforts(this.groupValue)
    window.dispatchEvent(new CustomEvent("highlights:changed"))
  }

  showAll() {
    this.element.classList.remove("highlights-only")
    this.onlyButtonTarget.classList.remove("active")
    this.onlyButtonTarget.setAttribute("aria-pressed", "false")
  }

  seedFromFragment() {
    const match = window.location.hash.match(/highlight=([\d,]+)/)
    if (!match) return

    mergeHighlightedEfforts(this.groupValue, match[1].split(","))
  }
}

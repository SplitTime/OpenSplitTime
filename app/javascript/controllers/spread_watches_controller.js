import { Controller } from "@hotwired/stimulus"
import { clearWatchedEfforts, mergeWatchedEfforts, watchedEffortIds } from "../src/utils/watch_store"

// Coordinates the watch controls that live inside existing chrome: the
// "Watched" item in the gender dropdown (show-only filter with a count)
// and the clear-all button in the table header. Individual rows manage
// their own state via watch_row_controller; this controller and the
// rows stay in sync through the window-level watches:changed event.
export default class extends Controller {
  static targets = ["watchedItem", "watchCount", "clearButton"]
  static values = { group: Number }

  connect() {
    this.seedFromFragment()
    this.refresh()
  }

  // Arriving via a shared #watch= link while already on the page is a
  // hash-only change with no reload, so connect() never re-fires
  onHashChange() {
    this.seedFromFragment()
    window.dispatchEvent(new CustomEvent("watches:changed"))
  }

  refresh() {
    const count = watchedEffortIds(this.groupValue).length

    if (this.hasWatchCountTarget) {
      this.watchCountTarget.textContent = count > 0 ? `(${count})` : ""
    }
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.toggle("d-none", count === 0)
    }
    if (count === 0) this.showAll()
  }

  toggleOnly(event) {
    event.preventDefault()

    if (this.element.classList.contains("watches-only")) {
      this.showAll()
    } else {
      this.element.classList.add("watches-only")
      if (this.hasWatchedItemTarget) this.watchedItemTarget.classList.add("active")
    }
  }

  clear() {
    clearWatchedEfforts(this.groupValue)
    window.dispatchEvent(new CustomEvent("watches:changed"))
  }

  showAll() {
    this.element.classList.remove("watches-only")
    if (this.hasWatchedItemTarget) this.watchedItemTarget.classList.remove("active")
  }

  seedFromFragment() {
    const match = window.location.hash.match(/watch=([\d,]+)/)
    if (!match) return

    mergeWatchedEfforts(this.groupValue, match[1].split(","))
  }
}

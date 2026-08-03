import { Controller } from "@hotwired/stimulus"
import { clearWatchedEfforts, mergeWatchedEfforts, watchedEffortIds } from "../src/utils/watch_store"

// Coordinates the watch controls that live inside existing chrome: the
// "Watched" item in the gender dropdown (show-only filter, present only
// while watches exist) and the clear-all button in the table header.
// Individual rows manage their own state via watch_row_controller; this
// controller and the rows stay in sync through the window-level
// watches:changed event.
export default class extends Controller {
  static targets = ["watchedItem", "clearButton"]
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

    if (this.hasWatchedItemTarget) {
      this.watchedItemTarget.classList.toggle("d-none", count === 0)
    }
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.toggle("d-none", count === 0)
    }
    if (count === 0) this.showAll()
  }

  toggleOnly(event) {
    event.preventDefault()
    this.applyOnlyState(!this.element.classList.contains("watches-only"))
  }

  clear() {
    clearWatchedEfforts(this.groupValue)
    window.dispatchEvent(new CustomEvent("watches:changed"))
  }

  showAll() {
    this.applyOnlyState(false)
  }

  // While the watched filter is on, the dropdown toggle reads "Watched"
  // and the disabled current-gender item is re-enabled so it serves as
  // the way back to the unfiltered view (its link reloads the page,
  // which resets this ephemeral filter)
  applyOnlyState(on) {
    if (on === this.element.classList.contains("watches-only")) return

    this.element.classList.toggle("watches-only", on)
    if (!this.hasWatchedItemTarget) return

    this.watchedItemTarget.classList.toggle("active", on)
    const dropdown = this.watchedItemTarget.closest(".btn-group")
    const toggle = dropdown?.querySelector(".dropdown-toggle")
    const toggleText = toggle?.childNodes[0]

    if (on) {
      this.originalToggleText = toggleText?.textContent
      if (toggleText) toggleText.textContent = "Watched "
      this.reenabledGenderItem = dropdown?.querySelector("a.dropdown-item.disabled")
      this.reenabledGenderItem?.classList.remove("disabled")
    } else {
      if (toggleText && this.originalToggleText) toggleText.textContent = this.originalToggleText
      this.reenabledGenderItem?.classList.add("disabled")
      this.reenabledGenderItem = null
    }
  }

  seedFromFragment() {
    const match = window.location.hash.match(/watch=([\d,]+)/)
    if (!match) return

    mergeWatchedEfforts(this.groupValue, match[1].split(","))
  }
}

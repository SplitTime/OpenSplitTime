import { Controller } from "@hotwired/stimulus"
import { clearWatchedEfforts, mergeWatchedEfforts, watchedEffortIds } from "../src/utils/watch_store"

// Coordinates the watch controls that live inside existing chrome: the
// "Watched" item in the gender dropdown (present only while watches
// exist) and the clear-all button in the table header. Watched is a
// first-class, mutually exclusive peer of the gender selections: its
// link navigates to the Combined view (gender-filtered pages do not
// even render cross-gender watched rows) carrying a #watched fragment,
// which this controller reads to apply the client-side filter.
// Individual rows manage their own state via watch_row_controller; this
// controller and the rows stay in sync through the window-level
// watches:changed event.
export default class extends Controller {
  static targets = ["watchedItem", "clearButton"]
  static values = { group: Number }

  connect() {
    this.seedFromFragment()
    this.applyOnlyState(this.watchedRequested())
    this.refresh()
  }

  // Selecting Watched while already on the Combined view — or a shared
  // #watch= link opened while already on the page — is a hash-only
  // change with no reload, so connect() never re-fires
  onHashChange() {
    this.seedFromFragment()
    this.applyOnlyState(this.watchedRequested())
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

  clear() {
    clearWatchedEfforts(this.groupValue)
    window.dispatchEvent(new CustomEvent("watches:changed"))
  }

  showAll() {
    this.applyOnlyState(false)
    if (this.watchedRequested()) {
      const hash = window.location.hash.replace(/(#|&)watched(&|$)/, "$1").replace(/[#&]$/, "")
      history.replaceState(null, "", window.location.pathname + window.location.search + hash)
    }
  }

  // While the watched filter is on, the dropdown follows its usual
  // selected-item convention: Watched becomes active and disabled, the
  // toggle reads "Watched", and the current-gender item (Combined,
  // post-navigation) is demoted to a plain selectable item so every
  // gender remains one click away
  applyOnlyState(on) {
    if (on === this.element.classList.contains("watches-only")) return

    this.element.classList.toggle("watches-only", on)
    if (!this.hasWatchedItemTarget) return

    const dropdown = this.watchedItemTarget.closest(".btn-group")
    const toggle = dropdown?.querySelector(".dropdown-toggle")
    const toggleText = toggle?.childNodes[0]

    if (on) {
      this.watchedItemTarget.classList.add("active", "disabled")
      this.originalToggleText = toggleText?.textContent
      if (toggleText) toggleText.textContent = "Watched "
      this.demotedGenderItem = dropdown?.querySelector("a.dropdown-item.active:not([data-spread-watches-target])")
      this.demotedGenderItem?.classList.remove("active", "disabled")
    } else {
      this.watchedItemTarget.classList.remove("active", "disabled")
      if (toggleText && this.originalToggleText) toggleText.textContent = this.originalToggleText
      this.demotedGenderItem?.classList.add("active", "disabled")
      this.demotedGenderItem = null
    }
  }

  watchedRequested() {
    return /(#|&)watched(&|$)/.test(window.location.hash)
  }

  seedFromFragment() {
    const match = window.location.hash.match(/watch=([\d,]+)/)
    if (!match) return

    mergeWatchedEfforts(this.groupValue, match[1].split(","))
  }
}

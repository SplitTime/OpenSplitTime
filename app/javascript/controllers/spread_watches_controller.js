import { Controller } from "@hotwired/stimulus"
import { clearWatchedEfforts, mergeWatchedEfforts, watchedEffortIds } from "../src/utils/watch_store"

// Coordinates the watch controls that live inside existing chrome.
// Watched mode is a ?watched query param, so the gender dropdown's
// selection states (active item, disabled item, toggle label) are all
// server-rendered; this controller only handles what the server cannot
// know from device-local storage: the Watched item's and clear button's
// visibility, the row-filtering class, and seeding from shared #watch=
// fragments. Individual rows manage their own state via
// watch_row_controller; everything syncs through the window-level
// watches:changed event.
export default class extends Controller {
  static targets = ["watchedItem", "clearButton"]
  static values = { eventGroupId: Number, followedUrl: String }

  connect() {
    this.seedFromFragment()
    if (this.watchedMode()) this.element.classList.add("watches-only")
    this.seedFromFollows().finally(() => this.refresh())
  }

  // Merges the signed-in user's followed entrants (notification
  // subscriptions) into the device-local watch set. The server renders
  // followedUrl only for signed-in users, so anonymous visits make no
  // request. Deferring refresh() until the fetch settles keeps a
  // bookmarked ?watched URL from bouncing to Combined before
  // server-known follows arrive on a fresh device.
  async seedFromFollows() {
    if (!this.hasFollowedUrlValue) return

    try {
      const response = await fetch(this.followedUrlValue, { headers: { "Accept": "application/json" } })
      if (!response.ok) return

      const { effort_ids: effortIds } = await response.json()
      if (!Array.isArray(effortIds) || effortIds.length === 0) return

      mergeWatchedEfforts(this.eventGroupIdValue, effortIds)
      window.dispatchEvent(new CustomEvent("watches:changed"))
    } catch {
      // Device-local watches remain authoritative when the request fails
    }
  }

  refresh() {
    const count = watchedEffortIds(this.eventGroupIdValue).length

    // The server renders the dropdown confidently in watched mode; with
    // nothing left to filter, quietly return to the Combined view
    if (count === 0 && this.watchedMode()) {
      this.exitWatchedMode()
      return
    }

    if (this.hasWatchedItemTarget) {
      this.watchedItemTarget.classList.toggle("d-none", count === 0)
    }
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.toggle("d-none", count === 0)
    }
  }

  clear() {
    clearWatchedEfforts(this.eventGroupIdValue)
    window.dispatchEvent(new CustomEvent("watches:changed"))
  }

  watchedMode() {
    return new URLSearchParams(window.location.search).has("watched")
  }

  exitWatchedMode() {
    const url = new URL(window.location)
    url.searchParams.delete("watched")
    url.hash = ""
    window.location.replace(url)
  }

  // Bound to hashchange because opening a shared #watch= link while
  // already on the page is a hash-only change with no reload, so
  // connect() never re-fires
  seedFromFragment() {
    const match = window.location.hash.match(/watch=([\d,]+)/)
    if (!match) return

    mergeWatchedEfforts(this.eventGroupIdValue, match[1].split(","))
    window.dispatchEvent(new CustomEvent("watches:changed"))
  }
}

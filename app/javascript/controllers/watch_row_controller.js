import { Controller } from "@hotwired/stimulus"
import { effortWatched, toggleWatchedEffort } from "../src/utils/watch_store"

// Lives on each watchable row. Applying state on connect means rows
// replaced by Turbo broadcasts re-apply their own watch automatically.
export default class extends Controller {
  static targets = ["icon"]
  static values = { effortId: Number, eventGroupId: Number }

  connect() {
    this.apply()
  }

  toggle() {
    toggleWatchedEffort(this.eventGroupIdValue, this.effortIdValue)
    this.apply()
    window.dispatchEvent(new CustomEvent("watches:changed"))
  }

  apply() {
    const watched = effortWatched(this.eventGroupIdValue, this.effortIdValue)

    this.element.classList.toggle("effort-watched", watched)
    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("fas", watched)
      this.iconTarget.classList.toggle("far", !watched)
      this.iconTarget.classList.toggle("text-warning", watched)
      this.iconTarget.classList.toggle("text-secondary", !watched)
    }
  }
}

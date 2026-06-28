import { Controller } from "@hotwired/stimulus"

// Renders each runner's release time = predicted arrival at the target aid station
// minus the travel buffer (minutes). The predicted arrival is carried on each release
// cell as a data attribute; the buffer comes from an input the steward can adjust, so
// release times recompute client-side without a page reload. Past times flip to "Now".
export default class extends Controller {
  static targets = ["buffer", "release"]

  connect() {
    this.refresh()
    this.timer = setInterval(() => this.refresh(), 10000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  bufferChanged() {
    this.refresh()
  }

  refresh() {
    const bufferMinutes = parseInt(this.bufferTarget.value, 10) || 0
    this.releaseTargets.forEach((cell) => this.renderRelease(cell, bufferMinutes))
  }

  renderRelease(cell, bufferMinutes) {
    const iso = cell.dataset.predictedArrival
    if (!iso) return

    const release = new Date(new Date(iso).getTime() - bufferMinutes * 60000)
    if (release <= new Date()) {
      cell.textContent = "Now"
    } else {
      cell.textContent = release.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })
    }
  }
}

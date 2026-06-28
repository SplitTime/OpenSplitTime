import { Controller } from "@hotwired/stimulus"

// Renders each runner's expected arrival at the target aid station and their release time
// (= expected arrival minus the travel buffer in minutes). The predicted arrival is carried
// on each cell as a data attribute; the buffer comes from an input the steward can adjust, so
// release times recompute client-side without a page reload. Past release times flip to "Now".
export default class extends Controller {
  static targets = ["buffer", "expected", "release"]

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
    this.expectedTargets.forEach((cell) => this.renderTime(cell, 0, false))
    this.releaseTargets.forEach((cell) => this.renderTime(cell, bufferMinutes, true))
  }

  renderTime(cell, offsetMinutes, flipToNow) {
    const iso = cell.dataset.predictedArrival
    if (!iso) return

    const time = new Date(new Date(iso).getTime() - offsetMinutes * 60000)
    if (flipToNow && time <= new Date()) {
      cell.textContent = "Now"
    } else {
      cell.textContent = time.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })
    }
  }
}

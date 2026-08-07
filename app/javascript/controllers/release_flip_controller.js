import { Controller } from "@hotwired/stimulus"

// Flips a pending release time to the green "Now" badge as the wall clock
// passes it, since no data change (and therefore no refresh broadcast) occurs
// at that moment. Purely presentational: the epoch is server-computed, and any
// subsequent refresh renders the badge server-side, on which this controller
// never attaches.
export default class extends Controller {
  static values = { epoch: Number }

  connect() {
    this.flipWhenDue()
    this.timer = setInterval(() => this.flipWhenDue(), 10_000)
  }

  flipWhenDue() {
    if (Date.now() / 1000 < this.epochValue) return

    this.element.innerHTML = '<span class="badge bg-success">Now</span>'
    clearInterval(this.timer)
  }

  disconnect() {
    clearInterval(this.timer)
  }
}

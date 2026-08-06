import { Controller } from "@hotwired/stimulus"

// Auto-submits the Crew Access controls form. Selects and switches submit immediately on
// change; the buffer and search inputs submit after a short debounce so the table updates
// live as the steward types or steps the value. The form targets the table's turbo frame,
// so only the runner table reloads — the controls (and search focus) stay put.
//
// The form also re-submits itself periodically, so the runner table stays live during a
// race — new arrivals appear and future release times flip to "Now" — while each viewer
// keeps their own buffer, sort, filters, and search.
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 300 },
    refreshInterval: { type: Number, default: 30_000 },
  }

  connect() {
    if (this.refreshIntervalValue > 0) {
      this.refreshTimer = setInterval(() => this.refresh(), this.refreshIntervalValue)
    }
  }

  submit() {
    this.element.requestSubmit()
  }

  debounce() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.submit(), this.delayValue)
  }

  refresh() {
    if (document.hidden) return

    this.submit()
  }

  disconnect() {
    clearTimeout(this.timer)
    clearInterval(this.refreshTimer)
  }
}

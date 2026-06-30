import { Controller } from "@hotwired/stimulus"

// Auto-submits the Crew Access controls form. Selects and switches submit immediately on
// change; the buffer and search inputs submit after a short debounce so the table updates
// live as the steward types or steps the value. The form targets the table's turbo frame,
// so only the runner table reloads — the controls (and search focus) stay put.
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  submit() {
    this.element.requestSubmit()
  }

  debounce() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.submit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}

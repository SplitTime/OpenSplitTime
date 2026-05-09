import { Controller } from "@hotwired/stimulus"

// Enables/disables the SMS consent checkbox based on whether
// the phone input contains a valid US or Canada number.
export default class extends Controller {
  static targets = ["phone", "consent"]

  connect() {
    this.toggle()
  }

  toggle() {
    const digits = this.phoneTarget.value.replace(/\D/g, "")
    const stripped = digits.replace(/^1/, "")
    const valid = stripped.length === 10

    if (valid) {
      this.consentTarget.disabled = false
    } else {
      this.consentTarget.disabled = true
      this.consentTarget.checked = false
    }
  }
}

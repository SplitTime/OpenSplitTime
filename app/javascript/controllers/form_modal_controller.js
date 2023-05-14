import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = [ "cancelButton" ]

  connect() {
    this.modal = new bootstrap.Modal(this.element)
  }

  open() {
    if (!this.modal.isOpened) {
      this.modal.show()
    }
  }

  close(event) {
    if (event.detail.success) {
      this.modal.hide()
    }
  }

  hide(event) {
    event.preventDefault()
    this.modal.hide()
  }

  autofocus() {
    const autofocusInput = this.element.querySelector("[autofocus]")
    if (autofocusInput) {
      autofocusInput.focus()
    }
  }

  conditionalReload(event) {
    const reloadIndicator = this.element.querySelector("[data-reload-on-submit]")
    if (event.detail.success && reloadIndicator) {
      reloadWithTurbo()
    }
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    force: Boolean,
  }

  keydown(event) {
    if (event.key === 'Shift') {
      this.toggleButton(this.forceValue)
    }
  }

  keyup(event) {
    if (event.key === 'Shift') {
      this.toggleButton(!this.forceValue)
    }
  }

  toggleButton(boolean) {
    if (boolean) {
      this.element.classList.remove('d-none')
    } else {
      this.element.classList.add('d-none')
    }
  }
}

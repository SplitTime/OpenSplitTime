import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    showWhenPressed: Boolean,
  }

  keydown(event) {
    if (event.key === 'Shift') {
      this.toggleButton(this.showWhenPressedValue)
    }
  }

  keyup(event) {
    if (event.key === 'Shift') {
      this.toggleButton(!this.showWhenPressedValue)
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

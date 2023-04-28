import { Controller } from "@hotwired/stimulus"
import { Toast } from "bootstrap"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 10000 },
  }

  connect() {
    const options = {
      delay: this.delayValue,
    }

    this.toast = new Toast(this.element, options)
    this.toast.show()
  }
}

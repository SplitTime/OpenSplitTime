import { Controller } from "@hotwired/stimulus"
import { Toast } from "bootstrap"

export default class extends Controller {
  connect() {
    this.toast = new Toast(this.element, {autohide: false} )
    this.toast.show()
  }
}

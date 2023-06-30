import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class extends Controller {
  connect() {
    document.addEventListener("show-toast", this.showToast)
  }

  showToast(event) {
    const url = "/toasts"
    const options = {
      body: event.detail,
      responseKind: "turbo-stream",
    }

    post(url, options)
  }
}

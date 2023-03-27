import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    window.onbeforeunload = null
    const form = this.element

    Array.from(form).forEach(function (el) {
      if (el.type === "checkbox" || el.type === "select-one") {
        el.addEventListener("input", function () {
          form.requestSubmit()
        })
      } else {
        el.addEventListener("focusout", function () {
          form.requestSubmit()
        })
      }
    })
  }
}

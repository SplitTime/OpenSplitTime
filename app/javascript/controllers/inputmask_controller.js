import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static values = {
    type: String // Must be an inputmask alias; see app/javascript/packs/application.js
  }

  connect() {
    const inputmask = new Inputmask(this.typeValue)
    inputmask.mask(this.element)
    this.element.addEventListener("blur", this.fillHandler.bind(this))
    this.element.addEventListener("keydown", this.submitHandler.bind(this))
  }

  fillHandler(event) {
    const field = event.target
    this.fill(field)
  }

  submitHandler(event) {
    if(event.key === "Enter") {
      const field = event.target
      this.fill(field)
    }
  }

  fill(field) {
    let dateFilledIn = /^[0-9:\/hms ]+$/.test(field.value)

    if(dateFilledIn) {
      field.value = field.value.replace(/[hms]/g, '0')
    }
  }
}

import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {

  static targets = ["countrySelect"]
  static values = { model: String }

  getSubregions() {
    const countryCode = this.countrySelectTarget.value
    const model = this.modelValue
    const url = "/carmen/subregion_options?model=" + model + "&parent_region=" + countryCode
    const options = { responseKind: "turbo-stream" }

    get(url, options).then (response => {
      if (!response.ok) { console.error(response) }
    })
  }
}

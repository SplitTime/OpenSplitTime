import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {

  static targets = ["dropdown"]

  replaceCategories() {
    const templateId = this.dropdownTarget.value;
    const url = "/results_templates/" + templateId
    const options = { responseKind: "turbo-stream" }

    get(url, options).then (response => {
      if (!response.ok) { console.error(response) }
    })
  }
}

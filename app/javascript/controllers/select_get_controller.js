import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static values = {
    urlPrefix: { type: String, default: "" },
    urlSuffix: { type: String, default: "" },
    default: { type: String, default: "" },
  }

  getUrl(event) {
    const selectValue = event.target.value || this.defaultValue
    const url = `${this.urlPrefixValue}${selectValue}${this.urlSuffixValue}`

    get(url, {
      responseKind: "turbo-stream",
    })
  }
}

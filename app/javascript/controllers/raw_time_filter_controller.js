import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    parameterizedSplitName: String,
  }

  connect() {
    if (!this.matchesCurrentFilters()) {
      this.element.remove()
    }
  }

  matchesCurrentFilters() {
    const params = new URLSearchParams(window.location.search)
    const splitNameFilter = params.get("filter[parameterized_split_name]")
    return !splitNameFilter || this.parameterizedSplitNameValue === splitNameFilter
  }
}

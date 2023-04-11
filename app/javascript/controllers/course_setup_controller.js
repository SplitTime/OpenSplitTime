import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "map",
  ]

  connect() {

  }

  aidStationChanged() {
    this.mapTarget.dispatchEvent(new CustomEvent("course-setup:aid-station-changed"))
  }
}

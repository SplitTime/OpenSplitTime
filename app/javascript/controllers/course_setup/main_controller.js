import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "map",
  ]

  aidStationChanged() {
    this.mapTarget.dispatchEvent(new CustomEvent("course-setup--main:refresh-markers"))
  }

  highlightMapMarker(event) {
    let payload = {
      detail: event.detail
    };

    this.mapTarget.dispatchEvent(new CustomEvent("course-setup--main:set-marker-highlight", payload))
  }

  refreshMapMarkers() {
    this.mapTarget.dispatchEvent(new CustomEvent("course-setup--main:refresh-markers"))
  }
}

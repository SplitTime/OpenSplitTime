import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "map",
    "splitRow",
    "splitTableBody",
  ]

  connect() {
    this.splitTableBodyTarget.addEventListener("mouseleave", this.unhighlightMapMarkers.bind(this))
    this.splitRowTargets.forEach((splitRow) => {
      splitRow.addEventListener("mouseenter", this.highlightMapMarker.bind(this))
    })
  }

  aidStationChanged() {
    this.mapTarget.dispatchEvent(new CustomEvent("course-setup--main:aid-station-changed"))
  }

  highlightMapMarker(event) {
    this.mapTarget.dispatchEvent(new CustomEvent("course-setup--main:set-marker-highlight", {detail: {splitId: parseInt(event.target.dataset.splitId)}}))
  }

  unhighlightMapMarkers() {
    this.mapTarget.dispatchEvent(new CustomEvent("course-setup--main:set-marker-highlight", {detail: {splitId: null}}))
  }
}

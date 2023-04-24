import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "splitRow",
  ]

  connect() {
    this.element.addEventListener("mouseleave", this.unhighlightMapMarkers.bind(this))
    this.splitRowTargets.forEach((splitRow) => {
      splitRow.addEventListener("mouseenter", this.highlightMapMarker.bind(this))
    })
  }

  highlightMapMarker(event) {
    const splitId = parseInt(event.target.dataset.splitId)
    this.dispatchHighlightEvent(splitId)
  }

  unhighlightMapMarkers() {
    this.dispatchHighlightEvent(null)
  }

  dispatchHighlightEvent(splitId) {
    const payload = {
      detail: {
        splitId: splitId,
      }
    }

    this.dispatch("set-marker-highlight", payload)
  }
}

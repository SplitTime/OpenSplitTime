import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "splitRow",
  ]

  connect() {
    this.splitRowTargets.forEach((splitRow) => {
      splitRow.addEventListener("click", this.highlightMapMarker.bind(this))
    })
  }

  highlightMapMarker(event) {
    const splitId = parseInt(event.currentTarget.dataset.splitId)
    this.dispatchHighlightEvent(splitId)
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

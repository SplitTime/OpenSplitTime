import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = [
    "deleteButton",
    "pattern",
  ]
  static values = {
    requiredPattern: String,
  }

  compare() {
    if (this.patternTarget.value === this.requiredPatternValue) {
      this.deleteButtonTarget.classList.remove("disabled")
    } else {
      this.deleteButtonTarget.classList.add("disabled")
    }
  }

  onClickDelete() {
    this.deleteButtonTarget.classList.add("disabled", "saving")
    this.deleteButtonTarget.value = "Deleting ..."
  }
}

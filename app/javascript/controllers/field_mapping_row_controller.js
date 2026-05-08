import { Controller } from "@hotwired/stimulus"

// Toggles the comments-only column (override + suppress_when inputs) based on
// the destination select's current value. Used in the field-mappings card on
// the Runsignup connection management page.
export default class extends Controller {
  static targets = ["destination", "commentsOnly"]
  static classes = ["commentsOnly"]

  connect() {
    this.toggle()
  }

  destinationChanged() {
    this.toggle()
  }

  toggle() {
    const isComments = this.destinationTarget.value === "comments"
    this.commentsOnlyTarget.classList.toggle(this.commentsOnlyClass, !isComments)
  }
}

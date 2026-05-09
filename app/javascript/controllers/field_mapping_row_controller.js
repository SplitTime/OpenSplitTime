import { Controller } from "@hotwired/stimulus"

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

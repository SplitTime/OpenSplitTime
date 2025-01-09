import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="link-disable"
export default class extends Controller {
  static values = { disableText: String };

  disable(_event) {
    this.element.classList.add("disabled");
    this.element.style.pointerEvents = "none"; // Prevent further interaction
    if (this.disableTextValue) {
      this.element.innerText = this.disableTextValue; // Replace the text
    }
  }
}

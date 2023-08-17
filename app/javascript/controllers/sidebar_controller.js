import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ["wrapper"];

  toggle(e) {
    e.preventDefault();
    if (this.wrapperTarget.classList.contains("toggled")) {
      this.wrapperTarget.classList.remove("toggled");
    } else {
      this.wrapperTarget.classList.add("toggled");
    }
  }
}

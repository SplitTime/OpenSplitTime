import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static values = {
    created: Number,
    fast: Boolean,
  }

  connect() {
    const five_seconds_ago = Math.round(Date.now() / 1000) - 5
    const subjectElement = this.element

    if (this.createdValue > five_seconds_ago) {
      const cssFadeClass = this.fastValue ? "bg-highlight-faded-fast" : "bg-highlight-faded"
      const delay = this.fastValue ? 200 : 2000
      subjectElement.classList.add("bg-highlight")

      setTimeout(function () {
        subjectElement.classList.remove("bg-highlight");
        subjectElement.classList.add(cssFadeClass);
      }, delay);

    }
  }
}

import { Controller } from "@hotwired/stimulus";
import flatpickr from "flatpickr";

export default class extends Controller {
  static values = {
    enableTime: {
      type: Boolean,
      default: false,
    },
  }

  connect() {
    const selector = `#${this.element.id}`
    const dateFormat = this.enableTimeValue ? "m/d/Y H:i:S" : "m/d/Y"
    const datetime = new Date(this.element.value)

    this._flatpickr = flatpickr(selector, {
      allowInput: true,
      enableTime: this.enableTimeValue,
      dateFormat: dateFormat,
      defaultDate: datetime,
    });

    this.element.addEventListener("keyup", (event) => {
      if (event.key === "Escape") {
        this.hide()
      }
    })
  }

  hide() {
    this._flatpickr.close()
  }
}

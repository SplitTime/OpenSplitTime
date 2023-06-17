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

    flatpickr(selector, {
      enableTime: this.enableTimeValue,
      dateFormat: dateFormat,
      defaultDate: datetime,
    });
  }
}

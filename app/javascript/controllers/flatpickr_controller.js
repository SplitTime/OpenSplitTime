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
    const controller = this
    const selector = `#${this.element.id}`
    const dateFormat = this.enableTimeValue ? "m/d/Y H:i:S" : "m/d/Y"
    const datetime = this.element.value ? new Date(this.element.value) : null

    flatpickr(selector, {
      allowInput: true,
      enableTime: this.enableTimeValue,
      dateFormat: dateFormat,
      defaultDate: datetime,
    });

    this.element.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && controller.element._flatpickr.isOpen) {
        event.stopPropagation()
        this.hide()
      }
    })
  }

  disconnect() {
    this.element._flatpickr.destroy()
  }

  hide() {
    this.element._flatpickr.close()
  }
}

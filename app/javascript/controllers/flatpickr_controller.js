import { Controller } from "@hotwired/stimulus";
import flatpickr from "flatpickr";

export default class extends Controller {
  connect() {
    const datetime = new Date(this.element.value)

    flatpickr("#event_scheduled_start_time_local", {
      enableTime: true,
      dateFormat: "m/d/Y H:i:S",
      defaultDate: datetime,
    });
  }
}

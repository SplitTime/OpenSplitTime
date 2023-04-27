import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {

  static values = {
    eventGroupId: Number,
  }

  connect() {
    this.triggerRawTimesPush();
  }

  triggerRawTimesPush() {
    const url = `/live/event_groups/${this.eventGroupIdValue}/trigger_raw_times_push`
    const options = {
      responseKind: "turbo-stream"
    }

    get(url, options)
  }
}

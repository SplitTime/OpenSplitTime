// Creates or deletes an aid station when the checkbox is checked or unchecked

import { Controller } from "@hotwired/stimulus"
import { post, destroy } from "@rails/request.js"

export default class extends Controller {
  static values = {
    aidStationId: Number,
    eventId: Number,
    splitId: Number,
  }

  connect() {
    this.element.addEventListener("change", this.createOrDeleteAidStation.bind(this))
  }

  createOrDeleteAidStation(event) {
    if (event.target.checked) {
      this.createAidStation()
    } else {
      this.deleteAidStation()
    }
  }

  createAidStation() {
    const url = `/events/${this.eventIdValue}/aid_stations`;

    post(url, {
      body: {
        aid_station: {
          split_id: this.splitIdValue
        },
      },
      responseKind: "turbo-stream",
    })
  }

  deleteAidStation() {
    const url = `/events/${this.eventIdValue}/aid_stations/${this.aidStationIdValue}`;

    destroy(url, {
      responseKind: "turbo-stream",
    })
  }
}

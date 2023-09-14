// Creates or deletes an aid station when the checkbox is checked or unchecked

import { Controller } from "@hotwired/stimulus"
import { post, destroy } from "@rails/request.js"

export default class extends Controller {
  static values = {
    eventGroupId: Number,
    eventId: Number,
    connectionId: Number,
    sourceId: String,
    sourceName: String,
    serviceIdentifier: String,
  }

  connect() {
    this.element.addEventListener("change", this.createOrDeleteConnection.bind(this))
  }

  createOrDeleteConnection(event) {
    if (event.target.checked) {
      this.createConnection()
    } else {
      this.deleteConnection()
    }
  }

  async createConnection() {
    const url = `/event_groups/${this.eventGroupIdValue}/events/${this.eventIdValue}/connections`;

    await post(url, {
      body: {
        connection: {
          service_identifier: this.serviceIdentifierValue,
          source_id: this.sourceIdValue,
          source_name: this.sourceNameValue,
        },
      },
      responseKind: "turbo-stream",
    })
  }

  async deleteConnection() {
    const url = `/event_groups/${this.eventGroupIdValue}/events/${this.eventIdValue}/connections/${this.connectionIdValue}`;

    await destroy(url, {
      responseKind: "turbo-stream",
      query: {
        "connection[source_name]": this.sourceNameValue,
      }
    })
  }
}

import { Controller } from "@hotwired/stimulus"
import { patch } from "@rails/request.js";
import { dispatchNotificationEvent } from "../../helpers"

export default class extends Controller {
  static values = {
    eventGroupId: Number,
    importAsyncBusy: {
      type: Boolean,
      default: false,
    }
  }

  pull(event) {
    const controller = this;
    const force = event.target.dataset.pullTimesForce

    if (controller.importAsyncBusyValue) return;
    controller.importAsyncBusyValue = true;

    const url = `/api/v1/event_groups/${controller.eventGroupIdValue}/pull_raw_times`
    const options = {
      query: {
        forcePull: force,
      },
    }

    patch(url, options).then(function (response) {
      if (response.ok) {
        return response.json
      } else {
        console.error('time row pull failed', response)
      }
    }).then(function (json) {
      const rawTimeRows = json.data.rawTimeRows;
      if (rawTimeRows.length === 0) {
        dispatchNotificationEvent({
          title: "You are up to date",
          body: "There are no raw times available to pull.",
          type: "info",
        })
      } else {
        rawTimeRows.forEach(rawTimeRow => {
          rawTimeRow.timestamp = Math.round(Date.now() / 1000)
        })

        controller.dispatch("pulled", {
          detail: {
            rawTimeRows: rawTimeRows,
          }
        })
      }
    }).catch(function (error) {
      dispatchNotificationEvent({
        title: "Raw times pull failed",
        body: error.message,
        type: "warning",
      })
    }).finally(function () {
      controller.importAsyncBusyValue = false;
    })
  }
}

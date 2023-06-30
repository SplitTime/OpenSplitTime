import { Controller } from "@hotwired/stimulus"
import { patch } from "@rails/request.js";
import { dispatchNotificationEvent } from "../../helpers"

export default class extends Controller {
  static values = {
    eventGroupId: Number,
    force: Boolean,
    importAsyncBusy: {
      type: Boolean,
      default: false,
    }
  }

  pull() {
    const controller = this;

    if (controller.importAsyncBusyValue) return;
    controller.importAsyncBusyValue = true;

    const url = `/api/v1/event_groups/${controller.eventGroupIdValue}/pull_raw_times`
    const options = {
      query: {
        forcePull: this.forceValue,
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
          body: "There are no raw times available to pull",
          type: "success",
        })
      } else {
        this.dispatch("pulled", {
          detail: {
            rawTimeRows: rawTimeRows,
          }
        })
      }
    }).catch(function (error) {
      dispatchNotificationEvent({
        title: "Raw times pull failed",
        body: error.message,
        type: "alert",
      })
    }).finally(function () {
      controller.importAsyncBusyValue = false;
    })
  }

  keydown(event) {
    if (event.key === 'Shift') {
      this.toggleButton(this.forceValue)
    }
  }

  keyup(event) {
    if (event.key === 'Shift') {
      this.toggleButton(!this.forceValue)
    }
  }

  toggleButton(boolean) {
    if (boolean) {
      this.element.classList.remove('d-none')
    } else {
      this.element.classList.add('d-none')
    }
  }
}

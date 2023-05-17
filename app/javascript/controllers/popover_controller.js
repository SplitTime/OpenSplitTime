import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"
import { Popover } from "bootstrap"

export default class extends Controller {
  static values = {
    effortIds: Array,
    target: String,
    theme: String,
  }

  connect() {
    const theme = this.themeValue
    const effortIds = this.effortIdsValue
    const target = this.targetValue

    this.element.style.cursor = "pointer"

    const popover = new Popover(
      this.element,
      {
        fetched: false,
        html: true,
      }
    )

    this.element.addEventListener("inserted.bs.popover", function (event) {
      if (effortIds.length > 0) {
        popover.tip.classList.add("efforts-popover");

        post("/efforts/mini_table/", {
          body: {
            effortIds: effortIds,
            target: target,
          },
          contentType: "application/json",
          responseKind: "turbo-stream"
        })

      } else {
        popover.tip.classList.add("static-popover");

        if (theme) {
          popover.tip.classList.add(`static-popover-${theme}`);
        }
      }
    })
  }
}

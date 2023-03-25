import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from "@rails/request.js"

export default class extends Controller {
  static values = {
    effortIds: Array,
    theme: String,
  }

  connect() {
    const theme = this.themeValue
    const effortIds = this.effortIdsValue

    this.element.style.cursor = "pointer"

    const popover = new bootstrap.Popover(
      this.element,
      {
        fetched: false,
        html: true,
      }
    )

    this.element.addEventListener("inserted.bs.popover", function (event) {
      if (effortIds.length > 0) {
        popover.tip.classList.add("efforts-popover");

        const request = new FetchRequest("post", "/efforts/mini_table/", {
          body: {effortIds: effortIds},
          contentType: "application/json",
          responseKind: "html"
        })

        if (!popover._config.fetched) {
          popover._config.fetched = true

          request.perform().then(function (response) {
            if (response.ok) {
              response.html.then(function (html) {
                popover.setContent({
                  ".popover-body": html
                })
              })
            } else {
              popover.setContent({
                ".popover-body": "Error loading efforts."
              })
            }
          }, function (error) {
            popover.setContent({
              ".popover-body": error
            })
          })
        }

      } else {
        popover.tip.classList.add("static-popover");

        if (theme) {
          popover.tip.classList.add(`static-popover-${theme}`);
        }
      }
    })
  }
}

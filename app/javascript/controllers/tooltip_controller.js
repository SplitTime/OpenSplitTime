import { Controller } from "@hotwired/stimulus"
import { Tooltip } from "bootstrap"

export default class extends Controller {
  connect() {
    new Tooltip(this.element)
  }

  disconnect() {
    const tooltip = Tooltip.getInstance(this.element)
    tooltip.dispose()
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {

    console.log("spread_table_controller connected")

    const effortHash = window.location.hash

    if (effortHash) {
      const effortId = effortHash.substring(2, effortHash.length)
      if (effortId && effortId.length > 1) {
        const row = document.getElementById(`effort_${effortId}`)
        if (row) {
          row.classList.add("bg-highlight")
        }
      }
    }
  }
}

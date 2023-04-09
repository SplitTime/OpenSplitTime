import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ["latitude", "longitude", "elevation"]

  updateLocation(event) {
    console.log(event.detail)
    this.latitudeTarget.value = event.detail.lat
    this.longitudeTarget.value = event.detail.lon
    this.elevationTarget.value = event.detail.elevation
  }
}

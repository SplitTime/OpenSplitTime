import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ["latitude", "longitude", "elevation"]

  connect() {
    this._elevator = new google.maps.ElevationService();
  }

  updateLocation(event) {
    const latLng = event.detail.latLng
    this._elevator.getElevationForLocations({
      locations: [latLng],
    })
      .then(({results}) => {
        if (results[0]) {
          const elevationInMeters = results[0].elevation;
          const elevation = Math.round(elevationInMeters * 3.28084);

          this.latitudeTarget.value = latLng.lat()
          this.longitudeTarget.value = latLng.lng()
          this.elevationTarget.value = elevation
        } else {
          console.error("No results found");
        }
      })
      .catch((e) =>
        console.error("Elevation service failed due to: " + e)
      );
  }
}

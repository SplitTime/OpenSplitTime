import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = [
    "latitude",
    "longitude",
    "elevation",
    "baseName",
    "map",
  ]

  connect() {
    this._elevator = new google.maps.ElevationService();
  }

  changed() {
    const latLng = new google.maps.LatLng(this.latitudeTarget.value, this.longitudeTarget.value)
    this.updateElevation(latLng);
    this.dispatchSplitLocation();
  }

  dispatchSplitLocation() {
    let payload = {
      detail: {
        splitLocation: {
          base_name: this.baseNameTarget.value,
          latitude: this.latitudeTarget.value,
          longitude: this.longitudeTarget.value,
        },
      }
    };

    this.mapTarget.dispatchEvent(new CustomEvent("split-location:changed", payload))
  }

  updateLocation(event) {
    const latLng = event.detail.latLng

    this.latitudeTarget.value = latLng.lat()
    this.longitudeTarget.value = latLng.lng()
    this.updateElevation(latLng)
    this.dispatchSplitLocation()
  }

  updateElevation(latLng) {
    const controller = this

    controller._elevator.getElevationForLocations({
      locations: [latLng],
    })
      .then(({results}) => {
        if (results[0]) {
          const elevationInMeters = results[0].elevation;
          this.elevationTarget.value = Math.round(elevationInMeters * 3.28084)
        } else {
          console.error("No results found");
        }
      })
      .catch((e) =>
        console.error("Elevation service failed due to: " + e)
      );
  }
}

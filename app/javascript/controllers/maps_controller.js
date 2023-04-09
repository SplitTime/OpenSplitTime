import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static values = {
    courseId: Number,
    splitId: Number,
  }

  connect() {
    const controller = this
    const courseId = this.courseIdValue;
    const splitId = this.splitIdValue;
    const splitProvided = splitId !== 0;
    const defaultLatLng = new google.maps.LatLng(40, -90);
    const defaultZoom = 4;

    let mapOptions = {
      mapTypeId: "terrain",
      center: defaultLatLng,
      zoom: defaultZoom,
    };

    this._gmap = new google.maps.Map(this.element, mapOptions);
    this._elevator = new google.maps.ElevationService();

    this._gmap.addListener("click", (event) => {
      this.dispatchClicked(event.latLng);
    });

    Rails.ajax({
      url: "/api/v1/courses/" + courseId,
      type: "GET",
      success: function (response) {
        const attributes = response.data.attributes;
        let locations = attributes.locations || [];

        if (splitProvided) {
          locations = locations.filter(function (e) {
            return e.id === parseInt(splitId)
          })
        }

        const trackPoints = attributes.trackPoints || [];
        const singleLocation = locations.length === 1 && splitProvided;

        controller.plotMarkersAndTrack(locations, trackPoints, singleLocation);
      }
    })
  }

  dispatchClicked(latLng) {
    const controller = this

    controller._elevator.getElevationForLocations({
      locations: [latLng],
    })
      .then(({results}) => {
        if (results[0]) {
          const elevationInMeters = results[0].elevation;
          const elevation = Math.round(elevationInMeters * 3.28084);

          controller.dispatch("clicked", {
            detail: {
              lat: latLng.lat(),
              lon: latLng.lng(),
              elevation: elevation,
            }
          })
        } else {
          console.error("No results found");
        }
      })
      .catch((e) =>
        console.error("Elevation service failed due to: " + e)
      );
  }

  plotMarkersAndTrack(locations, trackPoints, singleLocation) {
    if (locations.length === 0 && trackPoints.length === 0) { return }

    const controller = this
    let points = [];
    let bounds = new google.maps.LatLngBounds();

    trackPoints.forEach(function (trackPoint) {
      const lat = trackPoint.lat;
      const lon = trackPoint.lon;
      const p = new google.maps.LatLng(lat, lon);
      points.push(p);
      if (!singleLocation) {
        bounds.extend(p)
      }
    });

    let markers = locations.map(function (location) {
      if (location.latitude !== null && location.longitude !== null) {
        let lat = parseFloat(location.latitude);
        let lng = parseFloat(location.longitude);
        let point = new google.maps.LatLng(lat, lng);

        bounds.extend(point);

        let marker = new google.maps.Marker({
          position: point,
          map: controller._gmap
        });

        marker.infowindow = new google.maps.InfoWindow({
          content: location.base_name + " : " + location.latitude + ", " + location.longitude
        });

        marker.addListener('click', function () {
          markers.map(function (v) {
            if (v.infowindow) {
              v.infowindow.close();
            }
          });
          marker.infowindow.open(controller._gmap, marker);
        });

        return marker;
      }

    });

    let poly = new google.maps.Polyline({
      path: points,
      strokeColor: "#1000CA",
      strokeOpacity: .7,
      strokeWeight: 6
    });

    poly.setMap(controller._gmap);
    controller._gmap.fitBounds(bounds);
  };
}

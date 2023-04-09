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
    const defaultLatLng = new google.maps.LatLng(40, -90);
    const defaultZoom = 4;

    let mapOptions = {
      mapTypeId: "terrain",
      center: defaultLatLng,
      zoom: defaultZoom,
    };

    controller._splitProvided = (splitId !== 0);
    controller._elevator = new google.maps.ElevationService();
    controller._bounds = new google.maps.LatLngBounds();
    controller._gmap = new google.maps.Map(this.element, mapOptions);
    controller._gmap.maxDefaultZoom = 16;

    controller._gmap.addListener("click", (event) => {
      this.dispatchClicked(event.latLng);
    });

    google.maps.event.addListenerOnce(controller._gmap, "bounds_changed", function () {
      this.setZoom(Math.min(this.getZoom(), this.maxDefaultZoom))
    });

    Rails.ajax({
      url: "/api/v1/courses/" + courseId,
      type: "GET",
      success: function (response) {
        const attributes = response.data.attributes;
        let locations = attributes.locations || [];

        if (controller._splitProvided) {
          locations = locations.filter(function (e) {
            return e.id === parseInt(splitId)
          })
        }

        const trackPoints = attributes.trackPoints || [];
        const singleLocation = locations.length === 1 && controller._splitProvided;

        controller.plotTrack(trackPoints, singleLocation)
        controller.plotMarkers(locations)
        controller.fitBounds()
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

  plotTrack(trackPoints, singleLocation) {
    if (trackPoints.length === 0) {
      return
    }

    const controller = this
    let points = [];

    trackPoints.forEach(function (trackPoint) {
      const p = new google.maps.LatLng(trackPoint.lat, trackPoint.lon);
      points.push(p);
      if (!singleLocation) {
        controller._bounds.extend(p)
      }
    });

    let poly = new google.maps.Polyline({
      path: points,
      strokeColor: "#1000CA",
      strokeOpacity: .7,
      strokeWeight: 6
    });

    poly.setMap(controller._gmap);
  }

  plotMarkers(locations) {
    if (locations.length === 0) {
      return
    }

    const controller = this

    let markers = locations.map(function (location) {
      if (location.latitude && location.longitude) {
        let lat = parseFloat(location.latitude);
        let lng = parseFloat(location.longitude);
        let point = new google.maps.LatLng(lat, lng);

        controller._bounds.extend(point);

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
  }

  fitBounds() {
    if (this._bounds.isEmpty()) { return }

    this._gmap.fitBounds(this._bounds)
  }
}

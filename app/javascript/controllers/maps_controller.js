import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from "@rails/request.js"

export default class extends Controller {

  static values = {
    courseId: String,
    eventId: String,
    splitId: String,
    markerUrl: String,
  }

  connect() {
    const controller = this
    const courseId = this.courseIdValue;
    const eventId = this.eventIdValue;
    const splitId = this.splitIdValue;
    const defaultLatLng = new google.maps.LatLng(40, -90);
    const defaultZoom = 4;

    if (courseId.length === 0) {
      throw "Course ID is required."
    }

    controller._withoutEvent = (eventId.length === 0);
    controller._splitProvided = (splitId.length > 0);
    controller._splitLocation = null;
    controller._trackPoints = [];
    controller._locations = [];
    controller._bounds = new google.maps.LatLngBounds();

    const mapOptions = {
      mapTypeId: "terrain",
      center: defaultLatLng,
      zoom: defaultZoom,
      draggableCursor: controller._splitProvided ? "crosshair" : null,
    };

    controller._gmap = new google.maps.Map(controller.element, mapOptions);
    controller._gmap.maxDefaultZoom = 16;

    controller._gmap.addListener("click", (event) => {
      this.dispatchClicked(event.latLng);
    });

    google.maps.event.addListenerOnce(controller._gmap, "bounds_changed", function () {
      this.setZoom(Math.min(this.getZoom(), this.maxDefaultZoom))
    });

    controller._splitMarker = new google.maps.Marker({
      map: controller._gmap,
      position: null,
      zIndex: 1000,
      draggable: true,
    })

    controller._splitMarker.addListener("dragend", (event) => {
      this.dispatchClicked(event.latLng);
    })

    controller.fetchData().then(() => {
      controller.plotTrack()
      controller.plotSplitMarker()
      controller.plotMarkers()
      controller.fitBounds()
    })
  }

  async fetchData() {
    const controller = this
    const url = "/api/v1/courses/" + controller.courseIdValue

    const request = new FetchRequest("get", url, {responseKind: "json"})
    const response = await request.perform()

    if (response.ok) {
      const json = await response.json

      controller._trackPoints = json.data.attributes.trackPoints || []
      controller._locations = json.data.attributes.locations || []
      if (controller._splitProvided) {
        controller._splitLocation = controller._locations.find(function (location) {
          return location.id === parseInt(controller.splitIdValue)
        });
      }
    } else {
      console.error("Error fetching course data")
    }
  }

  dispatchClicked(latLng) {
    this.dispatch("clicked", {
      detail: { latLng: latLng }
    })
  }

  plotTrack() {
    const controller = this
    let points = [];
    if (controller._trackPoints.length === 0) { return }

    controller._trackPoints.forEach(function (trackPoint) {
      const p = new google.maps.LatLng(trackPoint.lat, trackPoint.lon);
      points.push(p);
      if (!controller._splitLocation) {
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

  plotSplitMarker() {
    const controller = this
    const location = controller._splitLocation;
    if (!location) { return }

    let lat = parseFloat(location.latitude);
    let lng = parseFloat(location.longitude);
    let latLng = new google.maps.LatLng(lat, lng);

    controller._bounds.extend(latLng);
    controller._splitMarker.setPosition(latLng);
  }

  plotMarkers() {
    const controller = this
    if (controller._locations.length === 0) { return }

    let markers = controller._locations.map(function (location, i) {
      if (location.latitude && location.longitude) {
        let lat = parseFloat(location.latitude);
        let lng = parseFloat(location.longitude);
        let point = new google.maps.LatLng(lat, lng);

        if (!controller._splitLocation) {
          controller._bounds.extend(point);
        }

        let marker = new google.maps.Marker({
          position: point,
          map: controller._gmap,
        });

        if (controller.hasMarkerUrlValue) {
          marker.setLabel((i + 1).toString())
          marker.setIcon({
            url: controller.markerUrlValue,
            labelOrigin: new google.maps.Point(16, 14),
            anchor: new google.maps.Point(16, 16)
          })
        }

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

  updateSplitLocation(event) {
    this._splitLocation = event.detail.splitLocation
    this.plotSplitMarker()
  }

  fitBounds() {
    if (this._bounds.isEmpty()) { return }

    this._gmap.fitBounds(this._bounds)
  }
}

import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from "@rails/request.js"

export default class extends Controller {

  static values = {
    courseId: String,
    eventId: String,
    splitId: String,
    activeMarkerUrl: String,
    inactiveMarkerUrl: String,
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
    controller._markers = [];
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
      controller._locations.forEach(function (location) {
        location.active = true
      })
      if (controller._splitProvided) {
        controller._splitLocation = controller._locations.find(function (location) {
          return location.id === parseInt(controller.splitIdValue)
        });
      }
      if (controller._withoutEvent) { return }

      await controller.fetchEventData()
    } else {
      console.error("Error fetching course data")
    }
  }

  async fetchEventData() {
    const controller = this
    const url = "/api/v1/events/" + controller.eventIdValue

    const request = new FetchRequest("get", url, {
        responseKind: "json",
        query: {include: "aid_stations"},
      }
    )
    const response = await request.perform()

    if (response.ok) {
      const json = await response.json

      const aidStations = json.included.filter(function (record) {
        return record.type === "aidStations"
      })

      const activeSplitIds = aidStations.map(function (record) {
        return record.attributes.splitId
      })

      controller._locations.forEach(function (location) {
        if (!activeSplitIds.includes(location.id)) {
          location.active = false
        }
      })

    } else {
      console.error("Error fetching event data")
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
      controller.conditionallyExtendBounds(p);
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
    controller.fitBounds();
  }

  plotMarkers() {
    const controller = this
    controller.removeMarkers()
    let markerIndex = 1;

    controller._markers = controller._locations.map(function (location) {
      if (location.latitude && location.longitude) {
        let point = new google.maps.LatLng(location.latitude, location.longitude);
        controller.conditionallyExtendBounds(point);

        let marker = new google.maps.Marker({
          position: point,
          map: controller._gmap,
        });

        controller.setMarkerIcon(marker, location, markerIndex)
        controller.setMarkerInfoWindow(marker, location)
        if (location.active) { markerIndex++ }

        return marker;
      }
    });
  }

  conditionallyExtendBounds(point) {
    const controller = this

    if (!controller._splitLocation) {
      controller._bounds.extend(point);
    }
  }

  fitBounds() {
    if (this._bounds.isEmpty()) { return }

    this._gmap.fitBounds(this._bounds)
  }

  removeMarkers() {
    const controller = this

    controller._markers.forEach(function (marker) {
      marker.setMap(null)
    })
    controller._markers.length = 0
  }

  setMarkerIcon(marker, location, markerIndex) {
    const controller = this

    if (location.active && controller.hasActiveMarkerUrlValue) {
      marker.setLabel((markerIndex).toString())
      marker.setIcon({
        url: controller.activeMarkerUrlValue,
        labelOrigin: new google.maps.Point(16, 14),
        anchor: new google.maps.Point(16, 16)
      })
    } else if (!location.active && controller.hasInactiveMarkerUrlValue) {
      marker.setIcon({
        url: controller.inactiveMarkerUrlValue,
        anchor: new google.maps.Point(16, 16)
      })
    }

  }

  setMarkerInfoWindow(marker, location) {
    const controller = this
    const inactiveText = location.active ? "" : "(inactive)"

    marker.infowindow = new google.maps.InfoWindow({
      content:
        "<div class='h5'>" +
        "<span class='h5 fw-bold'>" + location.base_name + "</span>" +
        "<span class='h6 ms-1'>" + inactiveText + "</span>" +
        "</div>" +
        "<div class='p'>" + location.latitude + ", " + location.longitude + "</div>"
    });

    marker.addListener('click', function () {
      controller._markers.map(function (v) {
        if (v.infowindow) {
          v.infowindow.close();
        }
      });
      marker.infowindow.open(controller._gmap, marker);
    });
  }

  updateMarkers() {
    this.fetchData().then(() => {
      this.plotMarkers()
      this.plotSplitMarker()
    })
  }

  updateSplitLocation(event) {
    this._splitLocation = event.detail.splitLocation
    this.plotSplitMarker()
  }
}

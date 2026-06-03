import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from "@rails/request.js"

export default class extends Controller {

  static values = {
    courseId: String,
    eventId: String,
    splitId: String,
    mapId: String,
    activeMarkerUrl: String,
    inactiveMarkerUrl: String,
    editable: Boolean,
  }

  async connect() {
    await Promise.all([
      google.maps.importLibrary("maps"),    // Map, Polyline, InfoWindow
      google.maps.importLibrary("marker"),  // AdvancedMarkerElement
      google.maps.importLibrary("core"),    // LatLng, LatLngBounds, event
    ])

    const controller = this
    const courseId = this.courseIdValue;
    const eventId = this.eventIdValue;
    const defaultLatLng = new google.maps.LatLng(40, -90);
    const defaultZoom = 4;

    if (!courseId.length) { throw "Course ID is required." }

    controller._withoutEvent = (!eventId.length);
    controller._splitLocation = null;
    controller._trackPoints = [];
    controller._locations = [];
    controller._markers = [];
    controller._bounds = new google.maps.LatLngBounds();

    const mapOptions = {
      mapId: this.mapIdValue,
      mapTypeId: "terrain",
      center: defaultLatLng,
      zoom: defaultZoom,
      draggableCursor: this.editableValue ? "crosshair" : null,
    };

    controller._gmap = new google.maps.Map(controller.element, mapOptions);
    controller._gmap.maxDefaultZoom = 16;

    controller._gmap.addListener("click", (event) => {
      this.dispatchClicked(event.latLng);
    });

    google.maps.event.addListenerOnce(controller._gmap, "bounds_changed", function () {
      this.setZoom(Math.min(this.getZoom(), this.maxDefaultZoom))
    });

    controller._splitMarker = new google.maps.marker.AdvancedMarkerElement({
      map: controller._gmap,
      position: null,
      zIndex: 1000,
      gmpDraggable: true,
    })

    controller._splitMarker.addListener("dragend", () => {
      this.dispatchClicked(this.latLngFrom(controller._splitMarker.position));
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
      if (controller.splitIdValue) {
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
    if (!controller._trackPoints.length) { return }

    controller._trackPoints.forEach(function (trackPoint) {
      const point = new google.maps.LatLng(trackPoint.lat, trackPoint.lon);
      points.push(point);
      controller.conditionallyExtendBounds(point);
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

    const latLng = this.latLngFromLocation(location);

    controller._bounds.extend(latLng);
    controller._splitMarker.position = latLng;
    controller.fitBounds();
  }

  plotMarkers() {
    const controller = this
    controller.removeMarkers()
    let markerIndex = 1;

    controller._markers = controller._locations.map(function (location) {
      if (location.latitude && location.longitude) {
        let point = controller.latLngFromLocation(location);
        controller.conditionallyExtendBounds(point);

        let marker = new google.maps.marker.AdvancedMarkerElement({
          position: point,
          map: controller._gmap,
          gmpClickable: true,
        });
        marker.splitId = location.id;

        controller.setMarkerContent(marker, location, markerIndex)
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
    const bounds = this._bounds
    if (bounds.isEmpty()) { return }

    // Don't zoom in too far on only one marker
    // https://stackoverflow.com/a/5345708/5961578
    const northEast = bounds.getNorthEast();
    const southWest = bounds.getSouthWest();

    if (northEast.equals(southWest)) {
      const extendPoint1 = new google.maps.LatLng(northEast.lat() + 0.01, northEast.lng() + 0.01);
      const extendPoint2 = new google.maps.LatLng(northEast.lat() - 0.01, northEast.lng() - 0.01);
      bounds.extend(extendPoint1);
      bounds.extend(extendPoint2);
    }

    this._gmap.fitBounds(bounds)
  }

  highlightMarker(event) {
    const controller = this

    controller._markers.forEach(function (marker) {
      if (!marker || !marker.content) { return }
      if (marker.splitId !== event.detail.splitId) { return }

      // A single bounce. translateY(50%) is the marker's resting transform (see
      // setMarkerContent); the animation lifts it 8px and settles back.
      marker.content.animate(
        [
          { transform: "translateY(50%)" },
          { transform: "translateY(calc(50% - 8px))" },
          { transform: "translateY(50%)" },
        ],
        { duration: 300, easing: "ease" }
      )
    })
  }

  latLngFromLocation(location) {
    return new google.maps.LatLng(location.latitude, location.longitude);
  }

  latLngFrom(position) {
    return position instanceof google.maps.LatLng
      ? position
      : new google.maps.LatLng(position.lat, position.lng);
  }

  refreshMarkers() {
    this.fetchData().then(() => {
      this.plotMarkers()
    })
  }

  removeMarkers() {
    const controller = this

    controller._markers.forEach(function (marker) {
      if (marker) { marker.map = null }
    })
    controller._markers.length = 0
  }

  setMarkerContent(marker, location, markerIndex) {
    const controller = this

    const url = location.active ? controller.activeMarkerUrlValue : controller.inactiveMarkerUrlValue
    if (!url) { return }

    // The dot SVG is 32x32 with its optical center at (16, 14). Center the numeric
    // label on the dot, and translateY(50%) re-centers the whole element on the
    // geographic point (AdvancedMarkerElement otherwise anchors at bottom-center).
    const content = document.createElement("div")
    Object.assign(content.style, {
      width: "32px",
      height: "32px",
      boxSizing: "border-box",
      paddingBottom: "4px",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      backgroundImage: `url(${url})`,
      backgroundRepeat: "no-repeat",
      backgroundPosition: "center",
      fontSize: "12px",
      fontWeight: "700",
      color: "#000",
      transform: "translateY(50%)",
    })
    if (location.active) { content.textContent = (markerIndex).toString() }

    marker.content = content
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

    marker.addEventListener('gmp-click', function () {
      controller._markers.map(function (v) {
        if (v.infowindow) {
          v.infowindow.close();
        }
      });
      marker.infowindow.open({ map: controller._gmap, anchor: marker });
    });
  }

  updateSplitLocation(event) {
    // If splitLocation was null at initialization, the bounds will include the entire track,
    // so empty the bounds to keep from zooming out when we plot the marker.
    if (!this._splitLocation) { this._bounds = new google.maps.LatLngBounds(); }

    this._splitLocation = event.detail.splitLocation
    this.plotSplitMarker()
  }
}

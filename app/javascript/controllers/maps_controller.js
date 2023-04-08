import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static values = {
    courseId: Number,
    splitId: Number,
  }

  connect() {

    const courseId = this.courseIdValue;
    const splitId = this.splitIdValue;
    const controller = this

    Rails.ajax({
      url: "/api/v1/courses/" + courseId,
      type: "GET",
      success: function (response) {
        const attributes = response.data.attributes;
        let locations = null;

        if (splitId === 0) {
          locations = attributes.locations;
        } else {
          locations = attributes.locations.filter(function (e) {
            return e.id === parseInt(splitId)
          })
        }

        const trackPoints = attributes.trackPoints || [];
        controller.gmapShow(locations, trackPoints);
      }
    })
  }

  gmapShow(locations, trackPoints) {
    locations = Array.isArray(locations) ? locations : [locations];
    trackPoints = Array.isArray(trackPoints) ? trackPoints : [trackPoints];

    let points = [];
    let bounds = new google.maps.LatLngBounds();

    trackPoints.forEach(function (trackPoint) {
      let lat = trackPoint.attr("lat");
      let lon = trackPoint.attr("lon");
      let p = new google.maps.LatLng(lat, lon);
      points.push(p);
      bounds.extend(p);
    });

    let mapOptions = {
      mapTypeId: 'terrain'
    };

    let map = new google.maps.Map(this.element, mapOptions);

    let markers = locations.map(function (location, i) {
      if (location.latitude !== null && location.longitude !== null) {
        let lat = parseFloat(location.latitude);
        let lng = parseFloat(location.longitude);
        let point = new google.maps.LatLng(lat, lng);

        bounds.extend(point);

        let marker = new google.maps.Marker({
          position: point,
          map: map
        });

        marker.infowindow = new google.maps.InfoWindow({
          content: location.base_name + " : " + location.latitude + ", " + location.longitude
        });

        marker.addListener('click', function () {
          markers.map(function (v, index) {
            if (v.infowindow) {
              v.infowindow.close();
            }
          });
          marker.infowindow.open(map, marker);
        });

        return marker;
      }

    });

    let poly = new google.maps.Polyline({
      path: points,
      strokeColor: "#1000CA",
      strokeOpacity: .7,
      strokeWeight: 4
    });

    poly.setMap(map);

    google.maps.event.addListenerOnce(map, 'bounds_changed', function () {
      this.setZoom(Math.min(15, this.getZoom()));
    });

    map.initialZoom = true;
    map.fitBounds(bounds);

  };
}

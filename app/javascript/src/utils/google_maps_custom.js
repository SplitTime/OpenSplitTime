var map;

var gmap_show = function (locations, trackPoints) {

    locations = Array.isArray(locations) ? locations : [locations];

    trackPoints = Array.isArray(trackPoints) ? trackPoints : [trackPoints];

    var points = [];

    var bounds = new google.maps.LatLngBounds();

    $(trackPoints).each(function () {
        var lat = $(this).attr("lat");
        var lon = $(this).attr("lon");
        var p = new google.maps.LatLng(lat, lon);
        points.push(p);
        bounds.extend(p);
    });

    var mapOptions = {
        mapTypeId: 'terrain'
    };

    map = new google.maps.Map(document.getElementById('map'), mapOptions);

    var markers = locations.map(function (location, i) {
        if (location.latitude !== null && location.longitude !== null) {
            var lat = parseFloat(location.latitude);
            var lng = parseFloat(location.longitude);
            var point = new google.maps.LatLng(lat, lng);

            bounds.extend(point);

            var marker = new google.maps.Marker({
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

    var poly = new google.maps.Polyline({
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

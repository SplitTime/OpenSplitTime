function gmap_show(location) {
    if ((location.latitude == null) || (location.longitude == null) ) {    // validation check if coordinates are there
        return 0;
    }

    handler = Gmaps.build('Google');    // map init
    handler.buildMap({ provider: {}, internal: {id: 'map'}}, function(){
        markers = handler.addMarkers([    // put marker method
            {
                "lat": location.latitude,    // coordinates from parameter location
                "lng": location.longitude,
                "picture": {    // setup marker icon
                    "url": 'http://www.travelaustralia.com.au/graphics/map_icons/icons/orange-dot.png',
                    "width":  32,
                    "height": 32
                },
                "infowindow": "<b>" + location.name + ":</b> " + location.latitude + ", " + location.longitude
            }
        ]);
        handler.bounds.extendWith(markers);
        handler.fitMapToBounds();
        handler.getMap().setZoom(12);    // set the default zoom of the map
    });
}

function gmap_form(location) {
    handler = Gmaps.build('Google');    // map init
    handler.buildMap({ provider: {}, internal: {id: 'map'}}, function(){
        if (location && location.latitude && location.longitude) {    // statement check - new or edit view
            markers = handler.addMarkers([    // print existent marker
                {
                    "lat": location.latitude,
                    "lng": location.longitude,
                    "picture": {
                        "url": 'http://www.travelaustralia.com.au/graphics/map_icons/icons/orange-dot.png',
                        "width":  32,
                        "height": 32
                    },
                    "infowindow": "<b>" + location.name + ":</b> " + location.latitude + ", " + location.longitude
                }
            ]);
            handler.bounds.extendWith(markers);
            handler.fitMapToBounds();
            handler.getMap().setZoom(12);
        }
        else {    // show the empty map
            handler.fitMapToBounds();
            handler.map.centerOn([40.0, -105.0]);
            handler.getMap().setZoom(5);
        }
    });

    var markerOnMap;

    function placeMarker(location) {    // simply method for put new marker on map
        if (markerOnMap) {
            markerOnMap.setPosition(location);
        }
        else {
            markerOnMap = new google.maps.Marker({
                position: location,
                map: handler.getMap()
            });
        }
    }

    google.maps.event.addListener(handler.getMap(), 'click', function(event) {    // event for click-put marker on map and pass coordinates to hidden fields in form
        placeMarker(event.latLng);
        document.getElementById("map_lat").value = event.latLng.lat();
        document.getElementById("map_lng").value = event.latLng.lng();
    });
}
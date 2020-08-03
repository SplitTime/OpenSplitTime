import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["mapInfo"]

    connect() {
        const courseId = this.mapInfoTarget.dataset.courseId;
        const splitId = this.mapInfoTarget.dataset.splitId;

        Rails.ajax({
            url: "/api/v1/courses/" + courseId,
            type: "GET",
            success: function (response) {
                const attributes = response.data.attributes;

                let locations = null;
                if(splitId === undefined) {
                    locations = attributes.locations;
                } else {
                    locations = attributes.locations.filter(function(e) {
                        return e.id === parseInt(splitId)
                    })
                }

                const trackPoints = attributes.trackPoints;
                gmap_show(locations, trackPoints);
            }
        })
    }
}

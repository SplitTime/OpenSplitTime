import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["mapInfo"]

    connect() {
        const locations = JSON.parse(this.mapInfoTarget.dataset.locations)
        const trackPoints = JSON.parse(this.mapInfoTarget.dataset.trackPoints)
        gmap_show(locations, trackPoints);
    }
}

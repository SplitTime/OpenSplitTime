import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["eventName", "eventShortName", "formData", "courseDropdown", "lapDropdown",
        "courseDistance", "totalDistance"];

    connect() {
        this.fillEventName();
        this.fillDistance()
    }

    fillEventName() {
        const shortName = this.eventShortNameTarget.value;
        const eventGroupName = this.formDataTarget.dataset.eventGroupName;

        if (shortName.length > 0) {
            this.eventNameTarget.innerHTML = eventGroupName + ' (' + shortName + ')'
        } else {
            this.eventNameTarget.innerHTML = eventGroupName
        }
    }

    fillDistance() {
        const select = this.courseDropdownTarget;
        const courseDistance = parseFloat(select.options[select.selectedIndex].dataset.distance);
        const distanceUnit = this.formDataTarget.dataset.prefDistanceUnit;
        const laps = parseInt(this.lapDropdownTarget.value);

        if (isNaN(courseDistance)) {
            this.courseDistanceTarget.innerHTML = 'No course selected';
            this.totalDistanceTarget.innerHTML = 'No course selected'
        } else if (laps === 0) {
            this.courseDistanceTarget.innerHTML = courseDistance + ' ' + distanceUnit;
            this.totalDistanceTarget.innerHTML = 'Unlimited (time-based)'
        } else {
            this.courseDistanceTarget.innerHTML = courseDistance + ' ' + distanceUnit;
            this.totalDistanceTarget.innerHTML = laps * courseDistance + ' ' + distanceUnit
        }
    }
}

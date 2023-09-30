import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = [
    "courseDistance",
    "courseForm",
    "courseIdField",
    "courseInfoFrame",
    "courseSelector",
    "eventName",
    "eventShortName",
    "formData",
    "lapDropdown",
    "totalDistance",
  ];

  connect() {
    this.fillEventName();
    this.fillDistance()
  }

  courseSelectorTargetConnected() {
    this.fillDistance()
    this.setCourseId()
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
    const select = this.courseSelectorTarget;
    const courseDistance = parseFloat(select.options[select.selectedIndex].dataset.distance);
    const distanceUnit = this.formDataTarget.dataset.prefDistanceUnit;
    const laps = parseInt(this.lapDropdownTarget.value);
    const totalDistance = parseFloat((laps * courseDistance).toFixed(1));

    if (isNaN(courseDistance)) {
      this.courseDistanceTarget.innerHTML = 'No course selected';
      this.totalDistanceTarget.innerHTML = 'No course selected';
    } else if (laps === 0) {
      this.courseDistanceTarget.innerHTML = courseDistance + ' ' + distanceUnit;
      this.totalDistanceTarget.innerHTML = 'Unlimited (time-based)'
    } else {
      this.courseDistanceTarget.innerHTML = courseDistance + ' ' + distanceUnit;
      this.totalDistanceTarget.innerHTML = totalDistance + ' ' + distanceUnit
    }
  }

  setCourseId() {
    this.courseIdFieldTarget.value = this.courseSelectorTarget.value
  }

  toggleCourseForm() {
    const courseId = this.courseSelectorTarget.value

    if (courseId === "") {
      this.courseFormTarget.classList.remove("d-none")
    } else {
      this.courseFormTarget.classList.add("d-none")
    }
  }
}

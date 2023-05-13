import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = [
    "militaryTime",
    "elapsedTime",
    "elapsedTimeShort",
    "absoluteTimeLocal",
  ];

  connect() {
    const militaryMask = new Inputmask("datetime", {
      inputFormat: "HH:MM:ss",
      placeholder: "hh:mm:ss",
      insertMode: false,
      showMaskOnHover: false,
    })

    const elapsedMask = new Inputmask("datetime", {
      inputFormat: "H2:MM:ss",
      placeholder: "hh:mm:ss",
      insertMode: false,
      showMaskOnHover: false,
    });

    const elapsedShortMask = new Inputmask("datetime", {
      inputFormat: "H2:MM",
      placeholder: "hh:mm",
      insertMode: false,
      showMaskOnHover: false,
    });

    const absoluteTimeLocalMask = new Inputmask("datetime", {
      inputFormat: "mm/dd/yyyy HH:MM:ss",
      placeholder: "mm/dd/yyyy hh:mm:ss",
      insertMode: false,
      showMaskOnHover: true,
    });

    this.militaryTimeTargets.forEach((element) => {
      militaryMask.mask(element)
      element.addEventListener("blur", this.fillHandler.bind(this))
    })

    this.elapsedTimeTargets.forEach((element) => {
      elapsedMask.mask(element)
      element.addEventListener("blur", this.fillHandler.bind(this))
    })

    this.elapsedTimeShortTargets.forEach((element) => {
      elapsedShortMask.mask(element)
      element.addEventListener("blur", this.fillHandler.bind(this))
    })

    this.absoluteTimeLocalTargets.forEach((element) => {
      absoluteTimeLocalMask.mask(element)
      element.addEventListener("blur", this.fillHandler.bind(this))
    })
  }

  fillHandler(event) {
    const field = event.target
    let dateFilledIn = /^[0-9:\/hms ]+$/.test(field.value)

    if(dateFilledIn) {
      field.value = field.value.replace(/[hms]/g, '0')
    }
  }
}

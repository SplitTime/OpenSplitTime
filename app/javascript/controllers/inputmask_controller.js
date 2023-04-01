import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = [
    "militaryTime",
    "elapsedTime",
    "elapsedTimeShort",
  ];

  connect() {
    $(this.militaryTimeTargets).inputmask("datetime", {
      inputFormat: "HH:MM:ss",
      placeholder: "hh:mm:ss",
      insertMode: false,
      showMaskOnHover: false,
    });

    $(this.elapsedTimeTargets).inputmask("datetime", {
      inputFormat: "H2:MM:ss",
      placeholder: "hh:mm:ss",
      insertMode: false,
      showMaskOnHover: false,
    });

    $(this.elapsedTimeShortTargets).inputmask("datetime", {
      inputFormat: "H2:MM",
      placeholder: "hh:mm",
      insertMode: false,
      showMaskOnHover: false,
    });
  }

  fill() {
    const fields = this.militaryTimeTargets.concat(this.elapsedTimeTargets).concat(this.elapsedTimeShortTargets);
    for (let field of fields) {
      field.value = field.value.replace(/[^\d:]/g, '0')
    }

  }

}

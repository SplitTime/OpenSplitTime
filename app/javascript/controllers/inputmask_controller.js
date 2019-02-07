import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["militaryTime", "elapsedTime", "elapsedTimeShort"];

    connect() {
        const maskOptions = {
            placeholder: "hh:mm:ss",
            insertMode: false,
            showMaskOnHover: false,
        };

        $(this.militaryTimeTargets).inputmask("hh:mm:ss", maskOptions);
        $(this.elapsedTimeTargets).inputmask("99:s:s", maskOptions);
        $(this.elapsedTimeShortTargets).inputmask("99:s", maskOptions);
    }

    fill() {
        const fields = this.militaryTimeTargets.concat(this.elapsedTimeTargets).concat(this.elapsedTimeShortTargets);
        for (let field of fields) {
            field.value = field.value.replace(/[^\d:]/g, '0')
        }

    }

}

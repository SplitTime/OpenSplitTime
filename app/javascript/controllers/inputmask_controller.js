import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["militaryTime", "elapsedTime"];

    connect() {
        const maskOptions = {
            placeholder: "hh:mm:ss",
            insertMode: false,
            showMaskOnHover: false,
        };

        $(this.militaryTimeTargets).inputmask("hh:mm:ss", maskOptions);
        $(this.elapsedTimeTargets).inputmask("99:s:s", maskOptions);
    }

    fill(e) {
        let field = e.srcElement;
        if (field.value.match(/[^\d:]/)) {
            field.value = field.value.replace(/[^\d:]/g, '0')
        }
    }

}

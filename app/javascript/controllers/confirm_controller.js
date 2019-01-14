import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["pattern", "deleteButton"]

    compare() {
        if (this.patternTarget.value.toLowerCase() === this.patternTarget.dataset.patternRequired.toLowerCase()) {
            $(this.deleteButtonTarget).removeClass("disabled")
        } else {
            $(this.deleteButtonTarget).addClass("disabled")
        }
    }
}

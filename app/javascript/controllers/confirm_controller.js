import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["pattern", "deleteButton"]

    compare() {
        if (this.patternTarget.value === this.patternTarget.dataset.patternRequired) {
            $(this.deleteButtonTarget).removeClass("disabled")
        } else {
            $(this.deleteButtonTarget).addClass("disabled")
        }
    }

    onClickDelete() {
        var $button = $(this.deleteButtonTarget);
        $button.addClass("disabled saving")
            .html( "Deleting <strong><span>.</span><span>.</span><span>.</span></strong>" )
    }
}

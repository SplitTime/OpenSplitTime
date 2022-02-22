import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ["error"]

    hideErrors() {
        $(this.errorTarget).fadeOut()
    }

    reloadPage() {
        reloadWithTurbo()
    }

    showErrors() {
        $(this.errorTarget).fadeIn()
    }
}

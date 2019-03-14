import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["error"]

    hideErrors() {
        $(this.errorTarget).fadeOut()
    }

    reloadPage() {
        reloadWithTurbolinks()
    }

    showErrors() {
        $(this.errorTarget).fadeIn()
    }
}

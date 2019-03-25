import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["submitButton"];

    reloadPage() {
        reloadWithTurbolinks()
    }

    submit() {
        this.submitButtonTarget.click()
    }
}

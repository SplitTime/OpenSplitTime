import ApplicationController from "./application_controller";

export default class extends ApplicationController {

    static targets = ["error"]

    hideErrors() {
        $(this.errorTarget).fadeOut()
    }

    reloadPage() {
        super.reloadWithTurbo();
    }

    showErrors() {
        $(this.errorTarget).fadeIn()
    }
}

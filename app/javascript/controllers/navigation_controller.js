import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ["refreshButton", "priorButton", "nextButton", "monitorButton", "setupButton"];

    connect() {
        console.log("Connected to the navigation controller")
    }

    evaluateKeyup(e) {
        let shortcutInvoked = (e.ctrlKey === true || e.target.tagName !== "INPUT") && e.altKey === false;

        if (shortcutInvoked) {
            if (e.key === "r" && this.hasRefreshButtonTarget) {
                this.refreshButtonTarget.click()
            } else if (e.key === "p" && this.hasPriorButtonTarget) {
                this.priorButtonTarget.click()
            } else if (e.key === "n" && this.hasNextButtonTarget) {
                this.nextButtonTarget.click()
            } else if (e.key === "m" && this.hasMonitorButtonTarget) {
                this.monitorButtonTarget.click()
            } else if (e.key === "s" && this.hasSetupButtonTarget) {
                this.setupButtonTarget.click()
            }
        }
    }
}

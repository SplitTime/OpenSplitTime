import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["refreshButton"];

    spinIcon(e) {
        let icon = e.currentTarget.getElementsByTagName('I')[0];
        icon.classList.add("fa-spin");
    }

    evaluateKeyup(e) {
        if((e.ctrlKey === true || e.target.tagName !== 'INPUT') && e.altKey === false && e.key === 'r') {
            this.refreshButtonTarget.click()
        }
    }
}

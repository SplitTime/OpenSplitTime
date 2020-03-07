import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["button", "icon"];

    spin() {
        this.iconTarget.classList.add("fa-spin");
    }

    evaluate(e) {
        if((e.ctrlKey === true || e.target.tagName !== 'INPUT') && e.altKey === false && e.key === 'r') {
            this.buttonTarget.click()
        }
    }
}

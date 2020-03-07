import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["icon"];

    spin() {
        this.iconTarget.classList.add("fa-spin");
    }
}

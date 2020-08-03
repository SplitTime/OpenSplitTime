import {Controller} from "stimulus"

export default class extends Controller {

    static targets = [];

    spinIcon(e) {
        let icon = e.currentTarget.getElementsByTagName('I')[0];
        icon.classList.add('fa-spin');
    }
}

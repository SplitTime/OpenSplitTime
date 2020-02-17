import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["error", "errorMessage"];

    hideErrors() {
        $(this.errorTarget).fadeOut()
    }

    reloadPage(event) {
        const [data, _status, _xhr] = event.detail;

        const newId = data.id;
        const resourceType = data.type;
        let searchString;
        if(window.location.search.length === 0) {
            searchString = '?'
        } else {
            searchString = window.location.search + '&'
        }

        let url = window.location.pathname + searchString + resourceType + '_id=' + newId;
        Turbolinks.visit(url)
    }

    showErrors(event) {
        const [data, _status, _xhr] = event.detail;

        this.errorMessageTarget.innerHTML = data.errors.title;
        $(this.errorMessageTarget).append('<br/>');
        $(this.errorMessageTarget).append(data.errors.detail.messages);
        $(this.errorTarget).fadeIn()
    }
}

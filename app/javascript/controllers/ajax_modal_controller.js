import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["error", "errorMessage"];

    hideErrors() {
        $(this.errorTarget).fadeOut()
    }

    reloadPage(event) {
        const [data, _status, _xhr] = event.detail;

        console.log(data);

        const newId = data.id;
        const resourceType = data.type;

        let url = window.location.pathname + '?' + resourceType + '_id=' + newId;
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

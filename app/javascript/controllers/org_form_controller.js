import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["error", "errorMessage"];

    onClickSubmit() {
        $(this.errorTarget).fadeOut()
    }

    onPostSuccess(event) {
        const [data, _status, xhr] = event.detail;
        let newOrgId = data.id;

        let url = window.location.pathname + '?organization_id=' + newOrgId;
        Turbolinks.visit(url)
    }

    onPostError(event) {
        const [data, _status, xhr] = event.detail;

        this.errorMessageTarget.innerHTML = data.errors.title;
        $(this.errorMessageTarget).append('<br/>');
        $(this.errorMessageTarget).append(data.errors.detail.messages);
        $(this.errorTarget).fadeIn()
    }
}

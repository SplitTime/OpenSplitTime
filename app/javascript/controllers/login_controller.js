import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ["error"]

    onClickSubmit() {
        $(this.errorTarget).fadeOut()
    }

    onPostSuccess() {
        reloadWithTurbo()
    }

    onPostError() {
        $(this.errorTarget).fadeIn()
    }
}

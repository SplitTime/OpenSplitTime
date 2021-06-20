import {Controller} from "stimulus"

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

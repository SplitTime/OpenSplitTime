import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["error"]

    onClickSubmit() {
        $(this.errorTarget).fadeOut()
    }

    onPostSuccess() {
        reloadWithTurbolinks()
    }

    onPostError() {
        $(this.errorTarget).fadeIn()
    }
}

import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    connect() {
        const form = this.element

        Array.from(form).forEach(function (el) {
            el.addEventListener("input", function () {
                form.requestSubmit()
            })
        })
    }
}

import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    connect() {
        const form = this.element

        Array.from(form).forEach(function (el) {
            if (el.type === "checkbox") {
                el.addEventListener("input", function () {
                    form.requestSubmit()
                })
            } else {
                el.addEventListener("focusout", function () {
                    form.requestSubmit()
                })
            }
        })
    }
}

import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ["submitButton"]

    connect() {
        const controller = this
        const form = this.element
        this.disableSubmitButton()

        Array.from(form).forEach(function (el) {
            if(el.type !== "hidden") {
                el.dataset.origValue = el.value
                el.addEventListener("input", function () {
                    controller.enableSubmitIfChanged()
                })
            }
        })
    }

    disableSubmitButton() {
        this.submitButtonTarget.classList.add("disabled")
        this.submitButtonTarget.disabled = true
    }

    enableSubmitButton() {
        this.submitButtonTarget.classList.remove("disabled")
        this.submitButtonTarget.disabled = false
    }

    enableSubmitIfChanged() {
        if(this.formHasChanges()) {
            this.enableSubmitButton();
        } else {
            this.disableSubmitButton();
        }
    }

    formHasChanges() {
        const form = this.element
        return Array.from(form).some(el => 'origValue' in el.dataset && el.dataset.origValue !== el.value)
    }
}

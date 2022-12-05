// This controller allows an element to be hidden and shown using a button.
// The button can change text and/or class depending on the status of the element,
// using the defined values.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ["button", "element"]
    static values = {
        buttonHideClass: String,
        buttonHideText: String,
        buttonShowClass: String,
        buttonShowText: String,
    }

    connect() {
        this.showButton()
        this.hideElement()
    }

    toggleElement() {
        if (this.elementTarget.classList.contains("d-none")) {
            this.showElement();
        } else {
            this.hideElement();
        }
    }

    showButton() {
        this.buttonTarget.classList.remove("d-none")
    }

    hideElement() {
        this.elementTarget.classList.add("d-none")
        this.buttonTarget.innerHTML = this.buttonShowTextValue
        this.buttonTarget.classList.remove(this.buttonHideClassValue)
        this.buttonTarget.classList.add(this.buttonShowClassValue)
    }

    showElement() {
        this.elementTarget.classList.remove("d-none")
        this.buttonTarget.innerHTML = this.buttonHideTextValue
        this.buttonTarget.classList.remove(this.buttonShowClassValue)
        this.buttonTarget.classList.add(this.buttonHideClassValue)
    }
}

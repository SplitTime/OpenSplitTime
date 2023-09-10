import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    const controller = this
    const form = this.element
    this._submitButton = form.querySelector("input[type='submit']")
    if (!this._submitButton) { return }

    this.disableSubmitButton()

    Array.from(form).forEach(function (el) {
      if (el.type !== "hidden") {
        el.dataset.origValue = el.value
        el.addEventListener("input", function () {
          controller.enableSubmitIfChanged()
        })
      }
    })
  }

  disableSubmitButton() {
    this._submitButton.classList.add("disabled")
    this._submitButton.disabled = true
  }

  enableSubmitButton() {
    this._submitButton.classList.remove("disabled")
    this._submitButton.disabled = false
  }

  enableSubmitIfChanged() {
    if (this.formHasChanges()) {
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

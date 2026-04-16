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
        el.dataset.origValue = el.type === "checkbox" ? el.checked : el.value
        el.addEventListener(el.type === "checkbox" ? "change" : "input", function () {
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
    return Array.from(form).some(el => {
      if (!('origValue' in el.dataset)) return false
      const current = el.type === "checkbox" ? String(el.checked) : el.value
      return el.dataset.origValue !== current
    })
  }
}

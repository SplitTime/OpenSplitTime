import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value)

    const button = this.buttonTarget
    const originalText = button.textContent
    button.textContent = "Copied"
    button.classList.add("btn-success")
    button.classList.remove("btn-outline-secondary")

    setTimeout(() => {
      button.textContent = originalText
      button.classList.remove("btn-success")
      button.classList.add("btn-outline-secondary")
    }, 2000)
  }
}

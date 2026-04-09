import { StreamActions } from "@hotwired/turbo"

StreamActions.remove_tr_with_fade = function () {
  this.targetElements.forEach((element) => {
    element.classList.add("bg-highlight")

    setTimeout(() => {
      element.classList.remove("bg-highlight")
      element.classList.add("fade")

      setTimeout(() => element.remove(), 200)
    }, 100)
  })
}

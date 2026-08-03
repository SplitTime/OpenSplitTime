import { Controller } from "@hotwired/stimulus"

// Horizontally scrollable strip with arrow controls. Arrows appear only
// when the content overflows; the selected item is centered on connect.
export default class extends Controller {
  static targets = ["viewport", "selected", "prevButton", "nextButton"]

  initialize() {
    this.updateArrows = this.updateArrows.bind(this)
  }

  connect() {
    if (this.hasSelectedTarget) {
      this.centerSelected()
    }
    this.updateArrows()
    window.addEventListener("resize", this.updateArrows)
  }

  disconnect() {
    window.removeEventListener("resize", this.updateArrows)
  }

  prev() {
    this.scrollByPage(-1)
  }

  next() {
    this.scrollByPage(1)
  }

  updateArrows() {
    const viewport = this.viewportTarget
    const maxScroll = viewport.scrollWidth - viewport.clientWidth
    const overflowing = maxScroll > 1

    this.prevButtonTarget.classList.toggle("d-none", !overflowing)
    this.nextButtonTarget.classList.toggle("d-none", !overflowing)

    if (overflowing) {
      this.prevButtonTarget.disabled = viewport.scrollLeft <= 0
      this.nextButtonTarget.disabled = viewport.scrollLeft >= maxScroll - 1
    }
  }

  centerSelected() {
    const viewport = this.viewportTarget
    const selected = this.selectedTarget
    const delta = selected.getBoundingClientRect().left - viewport.getBoundingClientRect().left

    viewport.scrollLeft += delta - (viewport.clientWidth - selected.offsetWidth) / 2
  }

  scrollByPage(direction) {
    const viewport = this.viewportTarget

    viewport.scrollBy({ left: direction * viewport.clientWidth * 0.75, behavior: "smooth" })
  }
}

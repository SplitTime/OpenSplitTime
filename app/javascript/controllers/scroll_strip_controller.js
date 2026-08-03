import { Controller } from "@hotwired/stimulus"

// Horizontally scrollable strip with arrow controls. Arrows appear only
// when the content overflows; the selected item is centered on connect.
export default class extends Controller {
  static targets = ["viewport", "selected", "prevButton", "nextButton"]

  initialize() {
    this.updateArrows = this.updateArrows.bind(this)
  }

  connect() {
    this.settle()
    // Web font loading changes button widths; re-settle with final metrics
    if (document.fonts) {
      document.fonts.ready.then(() => this.settle())
    }
    window.addEventListener("resize", this.updateArrows)
  }

  disconnect() {
    window.removeEventListener("resize", this.updateArrows)
    clearTimeout(this.snapTimer)
  }

  settle() {
    if (this.hasSelectedTarget) {
      this.centerSelected()
    }
    this.updateArrows()
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
      const atStart = viewport.scrollLeft <= 1
      const atEnd = viewport.scrollLeft >= maxScroll - 1

      this.prevButtonTarget.classList.toggle("invisible", atStart)
      this.prevButtonTarget.disabled = atStart
      this.nextButtonTarget.classList.toggle("invisible", atEnd)
      this.nextButtonTarget.disabled = atEnd

      // Once scrolling settles, snap any sub-pixel or rounding remainder
      // so content is never left clipped by a hair at either edge
      clearTimeout(this.snapTimer)
      this.snapTimer = setTimeout(() => this.snapToEdge(), 150)
    }
  }

  snapToEdge() {
    const viewport = this.viewportTarget
    const maxScroll = viewport.scrollWidth - viewport.clientWidth
    if (maxScroll <= 1) return

    if (viewport.scrollLeft > 0 && viewport.scrollLeft <= 1) {
      viewport.scrollLeft = 0
    } else if (viewport.scrollLeft < maxScroll && viewport.scrollLeft >= maxScroll - 1) {
      viewport.scrollLeft = maxScroll
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

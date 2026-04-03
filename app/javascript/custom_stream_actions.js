import { StreamActions } from "@hotwired/turbo"

StreamActions.remove_tr_with_fade = function () {
  this.targetElements.forEach((element) => {
    const cells = element.querySelectorAll("td, th")
    const highlightDuration = 200
    const collapseDuration = 500

    // Capture cell dimensions before any DOM changes
    const measurements = Array.from(cells).map((cell) => {
      const style = getComputedStyle(cell)
      return {
        height: cell.offsetHeight,
        paddingTop: style.paddingTop,
        paddingBottom: style.paddingBottom,
      }
    })

    // Wrap each cell's content in a div that takes over the cell's height and padding
    cells.forEach((cell, i) => {
      const m = measurements[i]
      const wrapper = document.createElement("div")
      wrapper.style.overflow = "hidden"
      wrapper.style.height = m.height + "px"
      wrapper.style.paddingTop = m.paddingTop
      wrapper.style.paddingBottom = m.paddingBottom
      wrapper.style.boxSizing = "border-box"

      while (cell.firstChild) {
        wrapper.appendChild(cell.firstChild)
      }
      cell.appendChild(wrapper)
      cell.style.padding = "0"
      cell.style.border = "none"
    })

    element.style.border = "none"

    // Flash highlight
    element.classList.add("bg-highlight")

    // After highlight is visible, begin the collapse
    setTimeout(() => {
      cells.forEach((cell) => {
        const wrapper = cell.firstElementChild
        wrapper.style.transition = `height ${collapseDuration}ms ease-in-out, padding ${collapseDuration}ms ease-in-out, opacity ${collapseDuration}ms ease-in-out`
      })

      element.classList.add("bg-highlight-faded-fast")
      element.classList.remove("bg-highlight")

      // Force layout
      element.offsetHeight

      requestAnimationFrame(() => {
        cells.forEach((cell) => {
          const wrapper = cell.firstElementChild
          wrapper.style.height = "0"
          wrapper.style.paddingTop = "0"
          wrapper.style.paddingBottom = "0"
          wrapper.style.opacity = "0"
        })

        setTimeout(() => element.remove(), collapseDuration)
      })
    }, highlightDuration)
  })
}

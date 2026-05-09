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

// Triggers a top-level Turbo navigation from inside a turbo-stream response.
// Useful when a form submitted from within a turbo-frame needs the response
// to navigate the entire page rather than just swap the frame's contents.
//
// Usage from a controller:
//   render turbo_stream: helpers.tag.turbo_stream(action: "visit", href: some_path)
StreamActions.visit = function () {
  const href = this.getAttribute("href")
  if (href) Turbo.visit(href)
}

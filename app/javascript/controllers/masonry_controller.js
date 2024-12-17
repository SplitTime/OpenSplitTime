import { Controller } from "@hotwired/stimulus"
import Masonry from "masonry-layout"

export default class extends Controller {
  connect() {
    this.masonry = new Masonry(this.element)

    // Frames resize when they load, so Masonry needs to recalculate the layout
    const frames = this.element.getElementsByTagName("turbo-frame")

    Array.from(frames).forEach((frame) => {
      frame.addEventListener("turbo:frame-load", () => {
        this.masonry.layout();
      });
    });
  }

  disconnect() {
    this.masonry.destroy()
  }

  layout() {
    this.masonry.layout()
  }
}

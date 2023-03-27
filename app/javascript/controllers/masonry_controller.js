import { Controller } from "@hotwired/stimulus"
import Masonry from "masonry-layout"

export default class extends Controller {
  connect() {
    this.masonry = new Masonry(this.element)
  }

  disconnect() {
    this.masonry.destroy()
  }

  layout() {
    this.masonry.layout()
  }
}

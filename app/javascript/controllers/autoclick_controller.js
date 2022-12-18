import { Controller } from "@hotwired/stimulus"
import { useIntersection } from 'stimulus-use'

export default class extends Controller {
    options = {
        threshold: 1
    }

    connect() {
        useIntersection(this, this.options)
    }

    appear(_entry) {
        this.element.click()
    }
}

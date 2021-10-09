import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ["element"]
    static values = { created: Number }

    connect() {
        const five_seconds_ago = Math.round(Date.now() / 1000) - 5
        const subjectElement = this.elementTarget

        if (this.createdValue > five_seconds_ago) {
            subjectElement.classList.add("bg-highlight")

            setTimeout(function () {
                subjectElement.classList.remove("bg-highlight");
                subjectElement.classList.add("bg-highlight-faded");
            }, 2000);

        }
    }
}

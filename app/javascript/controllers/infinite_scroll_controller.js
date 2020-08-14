import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["link", "result"]

    load(event) {
        event.preventDefault()

        const htmlTemplate = this.data.get("htmlTemplate")
        const nextPageUrl = this.data.get("nextPageUrl")
        const endOfListHtml = "<p>End of List</p>"

        if (nextPageUrl) {
            const url = nextPageUrl + "&html_template=" + htmlTemplate

            Rails.ajax({
                type: "GET",
                url: url,
                dataType: "json",
                success: (data) => {
                    this.resultTarget.innerHTML += data.html
                    this.data.set("nextPageUrl", data.links.next)
                    if (data.links.next === null) {
                        this.linkTarget.innerHTML = endOfListHtml
                    }
                }
            })
        } else {
            this.linkTarget.innerHTML = endOfListHtml
        }
    }
}

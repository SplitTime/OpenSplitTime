import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["link", "result"]

    initialize() {
        let options = {
            rootMargin: '100px',
        }

        this.intersectionObserver = new IntersectionObserver(entries => this.processIntersectionEntries(entries), options)
    }

    connect() {
        this.intersectionObserver.observe(this.linkTarget)
    }

    disconnect() {
        this.intersectionObserver.unobserve(this.linkTarget)
    }

    processIntersectionEntries(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                this.load()
            }
        })
    }

    loadFromClick(event) {
        event.preventDefault()
        this.load()
    }

    load() {
        const nextPageUrl = this.data.get("nextPageUrl")
        const htmlTemplate = this.data.get("htmlTemplate")
        const endOfListHtml = "<p>End of List</p>"

        if (nextPageUrl !== "null") {
            const url = nextPageUrl + "&html_template=" + htmlTemplate

            Rails.ajax({
                type: "GET",
                url: url,
                dataType: "json",
                success: (data) => {
                    this.data.set("nextPageUrl", data.links.next)
                    this.resultTarget.innerHTML += data.html
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

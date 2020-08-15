import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["search", "result", "projectionsModal"];

    connect() {
        this.searchTarget.focus()
    }

    checkInput(event) {
        if (event.type === "keyup" && event.keyCode !== 13) { return }

        const inputBox = this.searchTarget
        if (inputBox.value.length === 0) { return }

        setTimeout(function () {
            inputBox.focus()
            inputBox.select()
        }, 10);

        this.getEffort(inputBox.value)
    }

    getEffort(bibNumber) {
        const eventGroupId = this.data.get("eventGroupId");
        const url = "/event_groups/" + eventGroupId + "/efforts?filter[bib_number]=" + bibNumber + "&html_template=finish_line_effort"

        Rails.ajax({
            type: "GET",
            url: url,
            dataType: "json",
            success: (data) => {
                const id = data.efforts[0] ? data.efforts[0].id : null
                this.data.set("effortId", id)
                this.resultTarget.innerHTML = data.html
            }
        })
    }

    lookup(event) {
        if (event.type === "keyup" && event.keyCode !== 13) { return }

        const bibNumber = event.target.dataset.bibNumber
        this.searchTarget.value = bibNumber
        this.getEffort(bibNumber)
    }

    showProjectionsModal() {
        const effortId = this.data.get("effortId")
        const url = "/efforts/" + effortId + "/projections?html_template=split_times/projections_list"

        Rails.ajax({
            type: "GET",
            url: url,
            dataType: "json",
            success: (data) => {
                const title = "#" + data.efforts.bib_number + " " + data.efforts.first_name + " " + data.efforts.last_name

                $(this.projectionsModalTarget).modal("show")
                this.projectionsModalTarget.querySelector(".modal-title").innerHTML = "<strong>" + title + "</strong>"
                this.projectionsModalTarget.querySelector(".modal-body").innerHTML = data.html
            }
        })
    }
}

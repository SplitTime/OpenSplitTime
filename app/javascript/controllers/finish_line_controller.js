import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ['search', 'result'];

    connect() {
        this.searchTarget.focus()
    }

    checkInput(event) {
        if (event.type === 'keyup' && event.keyCode !== 13) { return }

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
        const url = '/event_groups/' + eventGroupId + '/efforts?filter[bib_number]=' + bibNumber + '&html_template=finish_line_effort'

        Rails.ajax({
            type: 'GET',
            url: url,
            dataType: 'json',
            success: (data) => {
                this.resultTarget.innerHTML = data.html
            }
        })
    }

    lookup(event) {
        if (event.type === 'keyup' && event.keyCode !== 13) { return }

        const bibNumber = event.target.dataset.bibNumber
        this.searchTarget.value = bibNumber
        this.getEffort(bibNumber)
    }
}

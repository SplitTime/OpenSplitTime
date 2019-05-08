import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ['startEffortsModal', 'actualStartTimeField', 'assumedStartTimeFilter', 'scheduledStartTime',
        'error']

    showModal(event) {
        const title = event.target.dataset.title;
        const displayTime = event.target.dataset.displaytime;
        const time = event.target.dataset.time;

        $(this.startEffortsModalTarget).modal('show');
        this.startEffortsModalTarget.querySelector('.modal-title').innerHTML = '<strong>' + title + '</strong>';
        this.actualStartTimeFieldTarget.value = displayTime;
        this.scheduledStartTimeTarget.innerHTML = displayTime;
        if (this.assumedStartTimeFilterTarget) {
            this.assumedStartTimeFilterTarget.value = time;
        }
    }

    hideErrors() {
        $(this.errorTarget).fadeOut()
    }

    showErrors() {
        $(this.errorTarget).fadeIn()
    }

    reloadPage() {
        reloadWithTurbolinks()
    }
}

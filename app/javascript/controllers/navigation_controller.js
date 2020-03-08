import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ['refreshButton', 'priorButton', 'nextButton'];

    spinIcon(e) {
        let icon = e.currentTarget.getElementsByTagName('I')[0];
        icon.classList.add('fa-spin');
    }

    evaluateKeyup(e) {
        let shortcutInvoked = (e.ctrlKey === true || e.target.tagName !== 'INPUT') && e.altKey === false;

        if (shortcutInvoked) {
            if (e.key === 'r' && this.hasRefreshButtonTarget) {
                this.refreshButtonTarget.click()
            } else if (e.key === 'p' && this.hasPriorButtonTarget) {
                this.priorButtonTarget.click()
            } else if (e.key === 'n' && this.hasNextButtonTarget) {
                this.nextButtonTarget.click()
            }
        }
    }
}

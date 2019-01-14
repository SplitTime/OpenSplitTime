import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["error"]

    onClickSubmit() {
        $(this.errorTarget).fadeOut()
    }

    onPostSuccess() {
        reloadWithTurbolinks()
    }

    onPostError() {
        $(this.errorTarget).fadeIn()
    }
}

var reloadWithTurbolinks = (function () {
    var scrollPosition;

    function reload() {
        scrollPosition = [window.scrollX, window.scrollY];
        Turbolinks.visit(window.location.toString(), {action: 'replace'})
    }

    document.addEventListener('turbolinks:load', function () {
        if (scrollPosition) {
            window.scrollTo.apply(window, scrollPosition);
            scrollPosition = null
        }
    });

    return reload
})();

var reloadWithTurbo = (function () {
    var scrollPosition;

    function reload() {
        scrollPosition = [window.scrollX, window.scrollY];
        Turbo.visit(window.location.toString(), {action: 'replace'})
    }

    document.addEventListener('turbo:load', function () {
        if (scrollPosition) {
            window.scrollTo.apply(window, scrollPosition);
            scrollPosition = null
        }
    });

    return reload
})();

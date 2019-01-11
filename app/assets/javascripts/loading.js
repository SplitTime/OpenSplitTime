// This isn't necessarily specific to toggle buttons
document.addEventListener("turbolinks:load", function () {

    var timeout = null;

    // Change the link's icon while the request is performing
    $('body').on('click', '.click-spinner', function () {
        var icon = $(this).find('i');
        icon.data('old-class', icon.attr('class'));
        icon.attr('class', 'fas fa-sync fa-spin');
        // TODO: REPLACE WITH STIMULUS
        if (timeout) clearTimeout(timeout);
        timeout = setTimeout(function() {
            revert(icon);
        }, 2000);
    });

    // Change the link's icon back after it's finished.
    $(document).on('ajax:complete', function (e) {
        revert($(e.target).find('i'));
    });

    function revert($icon) {
        if ($icon.data('old-class')) {
            $icon.attr('class', $icon.data('old-class'));
            $icon.data('old-class', null);
        }
    }

    // Redirect if not authorized
    $(document).on('ajax:error', function (e) {
        if (e.detail[1] === 'Unauthorized') {
            window.location.replace('/users/sign_in');
        }
    });
});

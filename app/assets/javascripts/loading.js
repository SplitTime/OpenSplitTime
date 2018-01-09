// This isn't necessarily specific to toggle buttons
$(function () {

    // Change the link's icon while the request is performing
    $('a[data-remote]').on('click', function () {
        var icon = $(this).find('i');
        icon.data('old-class', icon.attr('class'));
        icon.attr('class', 'glyphicon glyphicon-refresh spin');
    });

    // Change the link's icon back after it's finished.
    $(document).on('ajax:complete', function (e) {
        var icon = $(e.target).find('i');
        if (icon.data('old-class')) {
            icon.attr('class', icon.data('old-class'));
            icon.data('old-class', null);
        }
    });

    // Redirect if not authorized
    $(document).ajaxError(function (event, jqxhr) {
        if (jqxhr.status == 401) {
            window.location.replace('/users/sign_in');
        }
    });

})
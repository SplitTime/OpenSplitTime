import 'bootstrap-notify';

var originalNotify = $.notify;
$.notify = function(content, options) {
    var retval = originalNotify(content, options);
    return retval;
}

$.notifyDefaults({
    template: 
'<aside data-notify="container" class="col-xs-11 col-sm-4 alert growl alert-{0}" role="alert">\
    <button type="button" aria-hidden="true" class="close" data-notify="dismiss">×</button>\
    <span data-notify="wrapper">\
        <span data-notify="icon"></span>\
        <span data-notify="content">\
            <span data-notify="title">{1}</span>\
            <span data-notify="message">{2}</span>\
            <div class="progress" data-notify="progressbar">\
                <div class="progress-bar progress-bar-{0}" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width: 0%;"></div>\
            </div>\
            <a href="{3}" target="{4}" data-notify="url"></a>\
        </span>\
    </span>\
</aside>',
    type: 'orange',
    z_index: 1071 // Bootstrap uses up to 1070
});

$(document).on("turbolinks:load", () => {
    $(document).on('ajax:error', (e) => {
        let errors = e.detail[0].errors;
        if ($.isArray(errors)) {
            errors.forEach(error => {
                $.notify({
                    title: error.title,
                    message: error.detail.messages.join(', ')
                }, {
                    type: 'danger'
                });
            });
        } else if (e.detail[2].status === 0) {
            $.notify({
                title: 'Communication Error:',
                message: 'Server is not responding'
            }, {
                type: 'danger'
            });
        }
    });
});
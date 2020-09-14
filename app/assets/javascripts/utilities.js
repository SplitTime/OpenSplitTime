(function ($) {

    var utilities = {
        isMobileSafari: function () {
            return navigator.userAgent.match(/(iPod|iPhone|iPad)/) && navigator.userAgent.match(/AppleWebKit/)
        }
    };

    var datetimepicker = {
        init: function () {
            $.fn.datetimepicker.Constructor.Default = $.extend({}, $.fn.datetimepicker.Constructor.Default, {
                icons: {
                    time: 'far fa-clock',
                    date: 'far fa-calendar-alt',
                    up: 'fas fa-arrow-up',
                    down: 'fas fa-arrow-down',
                    previous: 'fas fa-chevron-left',
                    next: 'fas fa-chevron-right',
                    today: 'far fa-calendar-check',
                    clear: 'fas fa-trash-alt',
                    close: 'fas fa-times'
                }
            });

            $('[id^="datetimepicker"]').datetimepicker({
                sideBySide: true
            });

            $('[id^="datepicker"]').datetimepicker({
                format: 'L',
                viewMode: $(this).find(':input').val() ? 'days' : 'decades',
                viewDate: moment('1900-01-01'),
                useCurrent: false
            });
        }
    };

    var init = function () {
        datetimepicker.init();
    };

    document.addEventListener("turbolinks:load", init );
    $(document).bind( 'vue-ready', init );

})(jQuery);

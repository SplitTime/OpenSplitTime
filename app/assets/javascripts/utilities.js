(function ($) {

	var utilities = {
		isMobileSafari: function () {
		    return navigator.userAgent.match(/(iPod|iPhone|iPad)/) && navigator.userAgent.match(/AppleWebKit/)
		}
	};

	var effortsPopover = {
		init: function () {
			$('[data-toggle="efforts-popover"]')
				.attr('tabindex', '0')
				.attr('role', 'button')
				.data('ajax', null)
				.popover({
					'html': 'append',
					'trigger': 'focus'
				}).on('show.bs.popover', effortsPopover.onShowPopover);
			if ( utilities.isMobileSafari() ) {
				$( 'body' ).css( 'cursor', 'pointer' );
			}
		},
		onShowPopover: function (e) {
			$self = $(this);
			var ajax = $self.data('ajax');
			if ( !ajax || typeof ajax.status == 'undefined' ) {
				var $popover = $self.data('bs.popover');
				$popover.tip().addClass('efforts-popover');
				var data = {
					effortIds: $self.data('effort-ids')
				};
				$self.data('ajax', $.get('/efforts/mini_table/', data)
					.done(function (response) {
						$popover.options.content = $(response);
						$popover.show();
					}).always(function () {
						$self.data('ajax', null);
					})
				);
				e.preventDefault();
			}
		}
	};

    var staticPopover = {
        init: function () {
            $('[data-toggle="static-popover"]')
                .attr('tabindex', '0')
                .attr('role', 'button')
                .popover({
                    'html': 'append',
                    'trigger': 'focus'
                }).on('show.bs.popover', staticPopover.onShowPopover);
            if ( utilities.isMobileSafari() ) {
                $( 'body' ).css( 'cursor', 'pointer' );
            }
        },
        onShowPopover: function (e) {
            $self = $(this);
            var ajax = $self.data('ajax');
            if ( !ajax || typeof ajax.status == 'undefined' ) {
                var $popover = $self.data('bs.popover');
                $popover.tip().addClass('static-popover');
                $self.data('ajax', $.get('/photo_credits/')
                    .done(function (response) {
                        $popover.options.content = $(response);
                        $popover.show();
                    }).always(function () {
                        $self.data('ajax', null);
                    })
                );
                e.preventDefault();
            }
        }
    };

	$(document).ready(function () {
		effortsPopover.init();
		staticPopover.init();
	});
})(jQuery);
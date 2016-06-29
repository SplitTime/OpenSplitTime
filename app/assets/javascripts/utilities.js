(function ($) {

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
		},
		onShowPopover: function (e) {
			$self = $(this);
			var ajax = $self.data('ajax');
			if ( !ajax || typeof ajax.status == 'undefined' ) {
				var $popover = $self.data('bs.popover');
				var data = {
					effortIds: $self.data('effort-ids')
				};
				$self.data('ajax', $.get('/efforts/mini_table/', data)
					.done(function (response) {
						$popover.options.content = $(response);
						$popover.tip().addClass('.efforts-popover');
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
    });
})(jQuery);
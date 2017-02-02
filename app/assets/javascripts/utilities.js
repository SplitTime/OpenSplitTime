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
                $self.data('ajax', $.post('/efforts/mini_table/', data)
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

    var photoPopover = {
        init: function () {
            $('[data-toggle="photo-popover"]')
                .attr('tabindex', '0')
                .attr('role', 'button')
                .data('ajax', null)
                .popover({
                    'html': 'append',
                    'trigger': 'focus'
                }).on('show.bs.popover', photoPopover.onShowPopover);
            if ( utilities.isMobileSafari() ) {
                $( 'body' ).css( 'cursor', 'pointer' );
            }
        },
        onShowPopover: function (e) {
            $self = $(this);
            var ajax = $self.data('ajax');
            if ( !ajax || typeof ajax.status == 'undefined' ) {
                var $popover = $self.data('bs.popover');
                $popover.tip().addClass('photo-popover');
                var data = {
                    effortId: $self.data('effort-id')
                };
                $self.data('ajax', $.get('/efforts/show_photo/', data)
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
            $('[data-toggle="static-popover"],[data-toggle="static-popover-dark"]')
                .attr('tabindex', '0')
                .attr('role', 'button')
                .popover({
                    'html': 'append',
                    'trigger': 'focus',
                    'container': 'body'
                }).on('show.bs.popover', staticPopover.onShowPopover);
            if ( utilities.isMobileSafari() ) {
                $( 'body' ).css( 'cursor', 'pointer' );
            }
        },
        onShowPopover: function (e) {
            var $popover = $(this).data('bs.popover');
            $popover.tip()
                .addClass('static-popover')
                .addClass($(this).data('toggle'));
        }
    };

    /*
    <label class="switchery-label">
      <span>Rapid<br>Mode</span>
      <input type="checkbox" id="js-rapid-mode" data-toggle="switchery" data-size="small"/>
    </label>
     */

    var switchery = {
    	init: function () {
    		$( '[data-toggle="switchery"]' ).each( function( i, el ) {
				$( el ).data( 'switchery', new Switchery( el, {
					size: $( el ).data( 'size' )
				} ) );
    		} );
    	}
    };

    var init = function () {
        effortsPopover.init();
        staticPopover.init();
        switchery.init();
    };

    $(document).ready( init );
    $(document).bind( 'vue-ready', init );

})(jQuery);
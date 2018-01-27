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
            $('[data-toggle="static-popover"],[data-toggle="static-popover-dark"]').each( function( i, el ) {
                $( el ).attr( 'tabindex', $( el ).attr( 'tabindex' ) || '0' )
                .attr('role', 'button')
                .popover({
                    'html': 'append',
                    'trigger': 'focus',
                    'container': 'body'
                }).on('show.bs.popover', staticPopover.onShowPopover);
            } );
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

    var errorAlert = (function(){
        var $container = null;

        var buildAlert = function( $contents ) {
            var $alert = $( '<div class="alert alert-danger" role="alert"></div>' );
            $alert.append( '<button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>' );
            $alert.append( $contents );
            return $alert;
        }

        var buildJSONAPIErrors = function( errors ) {
            var $contents = '';
            for ( var i = 0; i < errors.length; i++ ) {
                var title = errors[i].title || 'Unknown Error';
                var detail = errors[i].detail;
                if ( $.isPlainObject( detail ) && detail.messages ) {
                    detail = detail.messages.join( ',&nbsp;' );
                } else if ( !detail instanceof String ) {
                    detail = '';
                }
                $contents += ( $contents === '' ) ? '' : '<br>';
                $contents += '<strong>' + title + '</strong>&nbsp;' + detail;
                if ( errors[i].dump ) {
                    $contents += '<br>' + JSON.stringify( errors[i].dump, null, ' ' );
                }
            }
            return $( '<span>' + $contents + '</span>' );
        }

        return {
            error: function( event, errors ) {
                var $alert;
                if ( $.isArray( errors ) && errors.length > 0 ) {
                    if ( $.isPlainObject( errors[0] ) ) {
                        // Interpret as JSONAPI errors
                        $alert = buildJSONAPIErrors( errors );
                    } else {
                        // Interpret as array of string errors
                        $alert = $( '<span>' + errors.join( ',&nbsp;' ) + '</span>' );
                    }
                }
                if ( $alert ) {
                    $alert = buildAlert( $alert );
                    $alert.hide();
                    $container.append( $alert );
                    $alert.slideDown();
                }
            },
            init: function () {
                if ( $container === null ) {
                    $container = $( '<aside id="global-alerts"><div class="container"></div></aside>' );
                    $( 'body' ).append( $container );
                    $container = $container.find( 'div' );
                    $( document ).bind( 'global-error', errorAlert.error );
                }
            },
        };
    })();

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
					size: $( el ).data( 'size' ),
                    color: '#2A9FD8'
				} ) );
    		} );
    	}
    };


    var datepicker = {
        init: function () {
            var update = function( e ) {
                /*
                 * BruceLampson on Dec 31, 2016
                 * https://github.com/RobinHerbots/Inputmask/issues/1468
                 */
                var event = document.createEvent( 'HTMLEvents' );
                event.initEvent( 'input', true, true );
                e.currentTarget.dispatchEvent( event );
                $( this ).trigger( 'change' );
            };
            $( '[data-toggle="datetimepicker"]' ).each( function( i, el ) {
                $( el ).datetimepicker( {
                    format: $( el ).data( 'format' ) || false
                } ).on( 'dp.change', function( e ) {
                    update( e );
                } );
            } );

            $('#datetimepicker').datetimepicker();
        }
    };

    var init = function () {
        effortsPopover.init();
        staticPopover.init();
        switchery.init();
        datepicker.init();
        errorAlert.init();
        $( document ).on('ajax:error', function(e) {
            if ($.isArray(e.detail[0].errors)) {
                $(document).trigger('global-error', [e.detail[0].errors]);
            }
        });
    };

    document.addEventListener("turbolinks:load", init );
    $(document).bind( 'vue-ready', init );

})(jQuery);

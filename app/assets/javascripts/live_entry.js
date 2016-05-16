( function( $ ) {

	/**
	 * UI object for the live event view
	 *
	 */
	var liveEntry = {

		init: function() {
			liveEntry.addEffortToCache();
			liveEntry.updateEventName();
			liveEntry.addSplitToSelect();
			liveEntry.addEffortForm();
			liveEntry.editEffortModal();
		},

		/**
		 * This is the static event array for the live_entry view.
		 * Once the live_entry UI has been wired up to the database
		 * remove this file.
		 *
		 */
		eventLiveEntryStaticData: {
			eventName: "Hardrock 100 2016",
			splits: [
				{
					name: "Hardrock Clockwise Start",
					distance: 0.0,
					id: 0
				},
				{
					name: "KT",
					distance: 11.4,
					id: 1
				},
				{
					name: "Chapman",
					distance: 18.4,
					id: 2
				},
				{
					name: "Telluride",
					distance: 27.7,
					id: 3
				},
				{
					name: "Kroger",
					distance: 32.7,
					id: 4
				},
				{
					name: "Governor",
					distance: 36.0,
					id: 5
				},
				{
					name: "Ouray",
					distance: 43.9,
					id: 6
				},
				{
					name: "Engineer",
					distance: 51.8,
					id: 7
				},
				{
					name: "Grouse",
					distance: 58.3,
					id: 8
				},
				{
					name: "Burrows",
					distance: 67.9,
					id: 9
				},
				{
					name: "Sherman",
					distance: 71.7,
					id: 10
				},
				{
					name: "Pole Creek",
					distance: 71.7,
					id: 11
				},
				{
					name: "Maggie",
					distance: 85.1,
					id: 12
				},
				{
					name: "Cunningham",
					distance: 91.2,
					id: 13
				},
				{
					name: "Hardrock Clockwise Finish",
					distance: 100.5,
					id: 14
				}
			]
		},

		/**
		 * Add the Effort data to the "cache" table on the page
		 *
		 */
		addEffortToCache: function() {

			$( document ).on( 'click', '#js-add-to-cache', function( event ) {
				event.preventDefault();

				var effortUpdateData = $( this ).serializeArray();

				console.log( effortUpdateData );

				return false;
			} );
		},

		/**
		 * Disables or enables fields for the effort lookup form
		 *
		 * @param {bool} True to enable, false to disable
		 */
		toggleFields: function( enable ) {
			if ( enable == true ) {
				$( '#js-add-effort-form input:not(#js-bib-number)' ).removeAttr( 'disabled' );
			} else {
				$( '#js-add-effort-form input:not(#js-bib-number)' ).attr( 'disabled', 'disabled' );
				$( '#js-add-effort-form input:not(#js-bib-number)' ).val( '' );
				$( '#js-bib-number' ).val( '' );

			}
		},

		/**
		 * Clears out the splits slider data fields
		 *
		 */
		 clearSplitsData: function() {
		 	$( '#js-effort-name' ).html( '' );
			$( '#js-effort-last-reported' ).html( '' )
			$( '#js-effort-split-from' ).html( '' );
			$( '#js-effort-split-spent' ).html( '' );
		 },

		/**
		 * Contains functionality for the effort form
		 *
		 */
		addEffortForm: function() {

			// When bib number field is focused, disabled fields
			$( '#js-bib-number' ).on( 'blur', function() {
				if ( $( this ).val() == '' ) {
					liveEntry.toggleFields( false );
					liveEntry.clearSplitsData();
				}
			} );

			// Listen for keydown on bibNumber
			$( '#js-bib-number' ).on( 'keydown', function( event ) {
				var $this = $( this );
				if ( event.keyCode == 13 || event.keyCode == 9 ) {
					event.preventDefault();

					// If value is empty, disable fields
					if ( $this.val() == '' ) {
						liveEntry.toggleFields( false );
						liveEntry.clearSplitsData();
					} else {

						// Ajax endpoint for the effort data
						// Get the event ID from the hidden span element
						var eventId = $( '#js-event-id' ).text();

						// Get bibNumber from the input field
						var data = { bibNumber: $this.val() };
						$.get( '/events/' + eventId + '/live_entry_ajax_getEffort', data, function( response ) {
							if ( response.success == true ) {

								// If success == true, this means the bib number lookup found an "effort"
								$( '#js-live-bib' ).val( 'true' );
								$( '#js-effort-name' ).html( response.name );
								$( '#js-effort-last-reported' ).html( response.lastReportedSplitTime )
							} else {

								// If success == false, this means the bib number lookup failed, but we still need to capture the data
								$( '#js-live-bib' ).val( 'false' );
								$( '#js-effort-name' ).html( 'n/a' );
								$( '#js-effort-last-reported' ).html( 'n/a' )
							}
						} );
						liveEntry.toggleFields( true );
						$( '#js-time-in' ).focus();
					}
					return false;
				}

				// switch ( $this.attr( 'id' ) ) {
				// 	case 'js-bib-number':
				// 		if ( $this.val() == '' ) {
				// 			$next = $( '#js-bib-number' );
				// 		} else {
				// 			toggleFields( true );
				// 			$next = $( '#js-time-in' );
				// 		}
				// 		break;
				// 	case 'js-time-in':
				// 		$next = $( '#js-time-out' );
				// 		break;
				// 	case 'js-time-out':
				// 		$next = $( '#js-pacer-in' );
				// 		break;
				// }

				// if ( event.keyCode == 13 ) {
				// 	event.preventDefault();
				// 	switch ( $this.attr( 'id' ) ) {
				// 		case 'js-bib-number':
				// 			if ( $this.val() == '' ) {
				// 				$next = $( '#js-bib-number' );
				// 			} else {
				// 				toggleFields( true );
				// 				$next = $( '#js-time-in' );
				// 			}
				// 			break;
				// 		case 'js-time-in':
				// 			$next = $( '#js-time-out' );
				// 			break;
				// 		case 'js-time-out':
				// 			$next = $( '#js-pacer-in' );
				// 			break;
				// 	}
				// 	$next.focus();
				// 	return false;
				// }
			} );

			// Listen for keydown in pacer-in and pacer-out. Enter checks the box,
			// tab moves to next field.
			$( '#js-pacer-in, #js-pacer-out').on( 'keydown', function( event ) {
				var $this = $( this );
				switch ( $this.attr( 'id' ) ) {
					case '#js-pacer-in':
						$next = $( '#js-pacer-out' );
						break;
					case '#js-pacer-out':
						$next = $( '#js-add-to-cache' );
						break;
				}
				if ( $this.attr( 'id' ) == 'js-pacer-in' ) {
					$next = $( '#js-pacer-out' );
				}

				switch ( event.keyCode ) {
					case 13: // Enter pressed
						console.log($this.attr( 'checked' ));
						if ( $this.attr( 'checked' ) == 'checked' ) {
							$this.removeAttr( 'checked' );
						} else {
							$this.attr( 'checked', 'checked' );
						}
						break;
					case 9: // Tab pressed
						$next.focus();
						break;
				}
			} );

			// $( '#js-get-effort-form' ).on( 'submit', function( event ) {
			// 	event.preventDefault();
			// 	var $this = $( this );
			// 	var bibNumber = $this.find( '#bib-number' ).val();
			// 	if ( bibNumber.length > 0 ) {

			// 		// Get the event ID from the hidden span element
			// 		var eventId = $( '#js-event-id' ).text();

			// 		// Get bibNumber from the input field
			// 		var data = { bibNumber: bibNumber };
			// 		$.get( '/events/' + eventId + '/live_entry_ajax_getEffort', data, function( response ) {
			// 			if ( response.success == true ) {
			// 				toggleFields( true );
			// 			} else {
			// 				toggleFields( false );
			// 			}
			// 		} );
			// 	} else {
			// 		toggleFields( false );
			// 	}
			// 	return false;
			// } );
		},

		/**
		 * Populate the h2 with the eventName
		 *
		 */
		updateEventName: function() {

			$( '.page-title h2' ).text( liveEntry.eventLiveEntryStaticData.eventName );

		},

		/**
		 * Add the Splits data to the select drop down table on the page
		 *
		 */
		addSplitToSelect: function() {

			// Populate select list with actual splits
			var splitItems = '<option selected="selected" value="">- Select -</option>';

			for ( var i = 0; i < liveEntry.eventLiveEntryStaticData.splits.length; i++ ) {
				splitItems += '<option value="' + liveEntry.eventLiveEntryStaticData.splits[ i ].name + '" data-split-id="' + liveEntry.eventLiveEntryStaticData.splits[ i ].id + '" >' + liveEntry.eventLiveEntryStaticData.splits[ i ].name + '</option>';
			}

			$( '#split-select' ).html( splitItems );
		},

		/**
		 * Open modal to edit the Effort data in the "cache" row
		 *
		 */
		editEffortModal: function() {
			var modalHtml = '';

			$( document ).on( 'click', '.js-edit-effort', function( event ) {
				event.preventDefault();

				var $thisRow = $( this ).closest( 'tr' );
				var effortId = $thisRow.attr( 'data-effort-id' );
				var bibNum = $thisRow.attr( 'data-bib-number' );
				var effortName = $thisRow.attr( 'data-effort-name' );
				var splitName = $thisRow.attr( 'data-split-name' );
				var timeIn = $thisRow.attr( 'data-time-in' );
				var timeOut = $thisRow.attr( 'data-time-out' );
				var pacerIn = $thisRow.attr( 'data-pacer-in' );
				var pacerOut = $thisRow.attr( 'data-pacer-out' );

				$( '.edit-effort-modal .modal-title .bib-number' ).html( bibNum );
				$( '.edit-effort-modal .modal-title .split-name' ).html( splitName );
				$( '.edit-effort-modal .js-effort-id' ).val( effortId );
				$( '.edit-effort-modal .js-split-name' ).val( splitName );
				$( '.edit-effort-modal .js-bib-number' ).val( bibNum );
				$( '.edit-effort-modal .js-effort-name' ).val( effortName );
				$( '.edit-effort-modal .js-time-in' ).val( timeIn );
				$( '.edit-effort-modal .js-time-out' ).val( timeOut );

				if( pacerIn === 'true' ) {
					$( '.edit-effort-modal .js-pacer-in' ).prop( 'checked', true );
				} else {
					$( '.edit-effort-modal .js-pacer-in' ).prop( 'checked', false );
				}

				if( pacerOut === 'true' ) {
					$( '.edit-effort-modal .js-pacer-out' ).prop( 'checked', true );
				} else {
					$( '.edit-effort-modal .js-pacer-out' ).prop( 'checked', false );
				}

				return false;
			} );
		}

	};

	$( document ).ready( function() {
		liveEntry.init();
	} );
} )( jQuery );

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
			liveEntry.getEffort();
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
					distance: 0.0
				},
				{
					name: "KT",
					distance: 11.4
				},
				{
					name: "Chapman",
					distance: 18.4
				},
				{
					name: "Telluride",
					distance: 27.7
				},
				{
					name: "Kroger",
					distance: 32.7
				},
				{
					name: "Governor",
					distance: 36.0
				},				
				{
					name: "Ouray",
					distance: 43.9
				},
				{
					name: "Engineer",
					distance: 51.8
				},
				{
					name: "Grouse",
					distance: 58.3
				},
				{ 
					name: "Burrows",
					distance: 67.9
				},
				{
					name: "Sherman",
					distance: 71.7
				},
				{
					name: "Pole Creek",
					distance: 71.7
				},
				{
					name: "Maggie",
					distance: 85.1
				},
				{
					name: "Cunningham",
					distance: 91.2
				},
				{
					name: "Hardrock Clockwise Finish",
					distance: 100.5
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
		 * Submit handler for getting an effort from the db
		 * 
		 */
		getEffort: function() {

			/**
			 * Disables or enables fields for the effort lookup form
			 *
			 * @param {bool} True to enable, false to disable
			 */
			function toggleFields( enable ) {
				if ( enable == true ) {
					$( '#js-add-effort-form input' ).removeAttr( 'disabled' );
				} else {
					$( '#js-add-effort-form input' ).attr( 'disabled', 'disabled' );
					$( '#js-get-effort-form #bib-number' ).html( '' );
				}
			};

			$( '#js-get-effort-form' ).on( 'submit', function( event ) {
				event.preventDefault();
				var $this = $( this );
				var bibNumber = $this.find( '#bib-number' ).val();
				if ( bibNumber.length > 0 ) {

					// Get the event ID from the hidden span element
					var eventId = $( '#js-event-id' ).text();

					// Get bibNumber from the input field
					var data = { bibNumber: bibNumber };
					$.get( '/events/' + eventId + '/live_entry_ajax_getEffort', data, function( response ) {
						if ( response.success == true ) {
							toggleFields( true );
						} else {
							toggleFields( false );
						}
					} );
				} else {
					toggleFields( false );
				}
				return false;
			} );
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
				splitItems += '<option value="' + liveEntry.eventLiveEntryStaticData.splits[ i ].name + '">' + liveEntry.eventLiveEntryStaticData.splits[ i ].name + '</option>';
			}

			$( '#split-select' ).html( splitItems );

		}

	};

	$( document ).ready( function() {
		liveEntry.init();
	} );
} )( jQuery );

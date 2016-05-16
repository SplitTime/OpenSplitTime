( function( $ ) {

	/**
	 * UI object for the live event view
	 *
	 */
	var liveEntry = {

		init: function() {
			console.log('doc ready!');

			liveEntry.addEffortToCache();
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
					distance: 0
				},
				{
					name: "KT In",
					distance: 11.4
				},
				{
					name: "KT Out",
					distance: 11.4
				},
				{
					name: "Chapman In",
					distance: 18.4
				},
				{
					name: "Chapman Out",
					distance: 18.4
				},
				{
					name: "Telluride In",
					distance: 27.7
				},
				{
					name: "Telluride Out",
					distance: 27.7
				},
				{
					name: "Kroger In",
					distance: 32.7
				},
				{
					name: "Kroger Out",
					distance: 32.7
				},
				{
					name: "Governor In",
					distance: 36.0
				},
				{
					name: "Governor Out",
					distance: 36.0
				},
				{
					name: "Ouray In",
					distance: 43.9
				},
				{
					name: "Ouray Out",
					distance: 43.9
				},
				{
					name: "Engineer In",
					distance: 51.8
				},
				{
					name: "Engineer Out",
					distance: 51.8
				},
				{
					name: "Grouse In",
					distance: 58.3
				},
				{
					name: "Grouse Out",
					distance: 58.3
				},
				{
					name: "Burrows In",
					distance: 67.9
				},
				{
					name: "Burrows Out",
					distance: 67.9
				},
				{
					name: "Sherman In",
					distance: 71.7
				},
				{
					name: "Sherman Out",
					distance: 71.7
				},
				{
					name: "Pole Creek In",
					distance: 71.7
				},
				{
					name: "Pole Creek Out",
					distance: 80.8
				},
				{
					name: "Maggie In",
					distance: 85.1
				},
				{
					name: "Maggie Out",
					distance: 85.1
				},
				{
					name: "Cunningham In",
					distance: 91.2
				},
				{
					name: "Cunningham Out",
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

			$( document ).on( 'submit', '#js-update-effort-form', function( event ) {
				event.preventDefault();

				var effortUpdateData = $( this ).serializeArray();

				console.log( effortUpdateData );


				return false;
			} );
		}
	};

	$( document ).ready( function() {
			liveEntry.init();
	} );
} )( jQuery );

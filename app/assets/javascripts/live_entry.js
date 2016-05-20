( function( $ ) {

	/**
	 * UI object for the live event view
	 *
	 */
	var liveEntry = {

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
		 * Stores the ID for the current event
		 * this is pulled from the url and dumped on the page
		 * then stored in this variable
		 * 
		 * @type integer
		 */
		currentEventId: null,

		/**
		 * When you type in a bib number into the live entry form this is set
		 * 
		 * @type integer
		 */
		currentEffortId: null,

		/**
		 * This kicks off the full UI
		 * 
		 */
		init: function() {

			// Sets the currentEventId once
			liveEntry.currentEventId = $( '#js-event-id' ).text();
			liveEntry.effortsCache.init();
			liveEntry.header.init();
			liveEntry.liveEntryForm.init();
			liveEntry.effortsDataTable.init();
			liveEntry.splitSlider.init();
			

			// liveEntry.setStoredEfforts();
			// liveEntry.addEffortToCacheTable();
			// liveEntry.updateEventName();
			// liveEntry.buildSplitSelect();
			// liveEntry.editEffort();
			// liveEntry.buildSplitSlider();
		},

		/**
		 * Contains functionality for the efforts cache
		 * 
		 */
		effortsCache: {

			/**
			 * Inits the efforts cache
			 * 
			 */
			init: function() {

				// Set the initial cache object in local storage
				var effortsCache = localStorage.getItem( 'effortsCache' );
				if( effortsCache === null || effortsCache.length == 0 ) {
					localStorage.setItem( 'effortsCache', JSON.stringify( liveEntry.efforts ) );
				}
			},

			/**
			 * Get local data Efforts Storage Object
			 *
			 * @return object Returns object from local storage
			 */
			getStoredEfforts: function() {
				return JSON.parse( localStorage.getItem('effortsCache') )
			},

			/**
			 * Stringify then Save/Push all efforts to local object
			 *
			 * @param object effortsObject Pass in the object of the updated object with all added or removed objects.
			 * @return null
			 */
			setStoredEfforts: function( effortsObject ) {
				localStorage.setItem( 'effortsCache', JSON.stringify( effortsObject ) );
				return null;
			},

			/**
			 * Delete the matching effort
			 *
			 * @param object 	effort 	Pass in the object/effort we want to delete.
			 * @return null
			 */
			deleteStoredEffort: function( effort ) {
				var storedEfforts = liveEntry.getStoredEfforts();
				var effortToDelete = JSON.stringify( effort );

				$.each( storedEfforts, function( index ) {
					var loopedEffort = JSON.stringify( $( this ) );
					if ( loopedEffort == effortToDelete ) {
						delete storedEfforts[index];
						return false;
					}
				} );

				localStorage.setItem( 'effortsCache', JSON.stringify( storedEfforts ) );
				return null;
			},

			/**
			 * Compare effort to all efforts in local storage. Add if it doesn't already exist, or throw an error message.
			 *
			 * @param  object effort Pass in Object of the effort to check it against the stored objects		 *
			 * @return boolean	True if match found, False if no match found
			 */
			isMatchedEffort: function( effort ) {
				var storedEfforts = liveEntry.getStoredEfforts();
				var tempEffort = JSON.stringify( effort );
				var flag = false;

				$.each( storedEfforts, function() {
					var loopedEffort = JSON.stringify( $( this ) );
					if ( loopedEffort == tempEffort ) {
						flag = true;
					}
				} );

				if( flag == false ) {
					return false;
				} else {
					return true;
				};
			},
		},
		/**
		 * Functionality to build header lives here
		 *
		 */
		header: {
			init: function() {
				liveEntry.header.updateEventName();
				liveEntry.header.buildSplitSelect();
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
			buildSplitSelect: function() {

				// Populate select list with actual splits
				var splitItems = '';
				for ( var i = 0; i < liveEntry.eventLiveEntryStaticData.splits.length; i++ ) {
					splitItems += '<option value="' + liveEntry.eventLiveEntryStaticData.splits[ i ].name + '" data-split-id="' + liveEntry.eventLiveEntryStaticData.splits[ i ].id + '" >' + liveEntry.eventLiveEntryStaticData.splits[ i ].name + '</option>';
				}
				$( '#split-select' ).html( splitItems );
			},
		},

		/**
		 * Contains functionality for the effort form
		 *
		 */
		liveEntryForm: {
			init: function() {
				// Apply input masks on time in / out
				var maskOptions = {
					placeholder: "HH:MM:SS",
					insertMode: false,
					showMaskOnHover: false,
				};

				$( '#js-time-in' ).inputmask( "hh:mm:ss", maskOptions );
				$( '#js-time-out' ).inputmask( "hh:mm:ss", maskOptions );
				$( '#js-bib-number' ).inputmask( "9999999999999999999", {placeholder:""} );

				// Clears the live entry form when the clear button is clicked
				$( '#js-clear-entry-form' ).on( 'click', function( event ) {
					event.preventDefault();
					liveEntry.liveEntryForm.clearSplitsData();
					liveEntry.liveEntryForm.toggleFields( false );
					return false;
				} );

				// Listen for keydown on bibNumber
				$( '#js-bib-number' ).on( 'keydown', function( event ) {

					// Check for tab or enter
					if ( event.keyCode == 13 || event.keyCode == 9 ) {
						event.preventDefault();
						var bibNumber = $( this ).val();
						if ( bibNumber == '' ) {
							liveEntry.liveEntryForm.toggleFields( false );
							liveEntry.liveEntryForm.clearSplitsData();
						} else {

							// Ajax endpoint for the effort data
							var data = { bibNumber: bibNumber };
							$.get( '/events/' + liveEntry.currentEventId + '/live_entry_ajax_get_effort', data, function( response ) {
								if ( response.success == true ) {
									liveEntry.currentEffortId = response.effortId;

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
							liveEntry.liveEntryForm.toggleFields( true );
							if ( ! event.shiftKey ) {
								$( '#js-time-in' ).focus();	
							}
						}
						return false;
					}
				} );

				$( '#js-time-in' ).on( 'keydown', function( event ) {
					if ( event.keyCode == 13 || event.keyCode == 9 ) {
						event.preventDefault();
						var timeIn = $( this ).val();

						// Validate the military time string
						if ( liveEntry.liveEntryForm.validateTimeFields( timeIn ) ) {

							// currentEffortId may be null here
							var data = { timeIn:timeIn, effortId: liveEntry.currentEffortId };
							$.get( '/events/' + liveEntry.currentEventId + '/live_entry_ajax_get_time_from', data, function( response ) {
								if ( response.success == true ) {
									$( '#js-last-reported' ).html( response.timeFromLastReported );
								}
								if ( event.shiftKey ) {
									$( '#js-bib-number' ).focus();
								} else {
									$( '#js-time-out' ).focus();
								}
							} );
						} else {
							 $( this ).val( '' );
						}
						return false;
					}
				} );

				$( '#js-time-out' ).on( 'keydown', function( event ) {
					if ( event.keyCode == 13 || event.keyCode == 9 ) {
						event.preventDefault();
						var timeOut = $( this ).val();

						// Validate the military time string
						if ( liveEntry.liveEntryForm.validateTimeFields( timeOut ) ) {

							// currentEffortId may be null here
							var data = { timeOut:timeOut, effortId: liveEntry.currentEffortId };
							$.get( '/events/' + liveEntry.currentEventId + '/live_entry_ajax_get_time_spent', data, function( response ) {
								if ( response.success == true ) {
									$( '#js-time-spent' ).html( response.timeSpent );
								}
								if ( event.shiftKey ) {
									$( '#js-time-in' ).focus();
								} else {
									$( '#js-pacer-in' ).focus();
								}
							} );
						} else {
							 $( this ).val( '' );
						}
						return false;
					}
				} );

				// Listen for keydown in pacer-in and pacer-out. 
				// Enter checks the box, tab moves to next field.
				$( '#js-pacer-in' ).on( 'keydown', function( event ) {
					event.preventDefault();
					var $this = $( this );
					switch ( event.keyCode ) {
						case 13: // Enter pressed
							if ( $this.is(':checked') ) {
								$this.prop( 'checked', false );
							} else {
								$this.prop( 'checked', true );
							}
							break;
						case 9: // Tab pressed
							if ( event.shiftKey ) {
								$( '#js-time-out' ).focus();
							} else {
								$( '#js-pacer-out' ).focus();
							}
							break;
					}
					return false;
				} );

				$( '#js-pacer-out' ).on( 'keydown', function( event ) {
					event.preventDefault();
					var $this = $( this );
					switch ( event.keyCode ) {
						case 13: // Enter pressed
							if ( $this.is(':checked') ) {
								$this.prop( 'checked', false );
							} else {
								$this.prop( 'checked', true );
							}
							break;
						case 9: // Tab pressed
							if ( event.shiftKey ) {
								$( '#js-pacer-in' ).focus();
							} else {
								$( '#js-add-to-cache' ).focus();
							}
							break;
					}
					return false;
				} );
			},

			/**
			 * Disables or enables fields for the effort lookup form
			 *
			 * @param bool 	True to enable, false to disable
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
				$( '#js-effort-name' ).html( '&nbsp;' );
				$( '#js-effort-last-reported' ).html( '&nbsp;' )
				$( '#js-last-reported' ).html( '&nbsp;' );
				$( '#js-effort-split-from' ).html( '&nbsp;' );
				$( '#js-effort-split-spent' ).html( '&nbsp;' );
				$( '#js-time-in' ).val( '' );
				$( '#js-time-out' ).val( '' );
				$( '#js-live-bib' ).val( '' );
				$( '#js-pacer-in' ).attr( 'checked', false );
				$( '#js-pacer-out' ).attr( 'checked', false );				
			},

			/**
			 * Valiates the time fields
			 *
			 * @param string time time format from the input mask
			 */
			validateTimeFields: function( time ) {
				time = time.replace(/\D/g, '');
				if ( time.length == 6 ) {
					return true;
				} else {
					return false;
				}
			}
		}, // END liveEntryForm form

		/**
		 * Contains functionality for efforts cache table
		 * 
		 */
		effortsDataTable: {
			init: function() {

				// Initiate DataTable Plugin
				$( '.js-provisional-data-table' ).DataTable();	

				// Attach add listener
				$( '#js-add-to-cache' ).on( 'click', function( event ) {
					event.preventDefault();
					var thisEffort = {};

					// Check table stored efforts for highest unique ID then create a new one.
					var i = 0;
					var storedEfforts = liveEntry.effortsCache.getStoredEfforts();
					var storedUniqueIds = [];
					if ( storedEfforts.length > 0 ) {
						$.each( storedEfforts, function( index, value ) {
							var thisEffort = $( this );
							storedUniqueIds.push( thisEffort[index].uniqueId );
						} );
						var highestUniqueId = Math.max.apply( Math, storedUniqueIds );
						thisEffort.uniqueId = highestUniqueId;
					} else {
						thisEffort.uniqueId = i++;
					}

					// Build up the effort
					thisEffort.eventId 		= liveEntry.currentEventId;
					thisEffort.splitId 		= $( document ).find( '#split-select option:selected' ).attr( 'data-split-id' );
					thisEffort.splitName 	= $( document ).find( '#split-select option:selected' ).html();
					thisEffort.effortId 	= liveEntry.currentEffortId;
					thisEffort.bibNumber 	= $( '#js-bib-number' ).val();
					thisEffort.liveBib 		= $( '#js-live-bib' ).val();
					thisEffort.effortName 	= $( '#js-effort-name' ).html();
					thisEffort.timeIn 		= $( '#js-time-in' ).val();
					thisEffort.timeOut 		= $( '#js-time-out' ).val();
					if ( $( '#js-pacer-in' ).prop( 'checked' ) == true ) {
						thisEffort.pacerIn = true;
						thisEffort.pacerInHtml = 'Yes';
					} else {
						thisEffort.pacerIn = false;
						thisEffort.pacerInHtml = 'No';
					}

					if ( $( '#js-pacer-out' ).prop( 'checked' ) == true ) {
						thisEffort.pacerOut = true;
						thisEffort.pacerOutHtml = 'Yes';
					} else {
						thisEffort.pacerOut = false;
						thisEffort.pacerOutHtml = 'No';
					}
					if( ! liveEntry.isMatchedEffort( thisEffort ) ) {
						storedEfforts.push( thisEffort );
						liveEntry.effortsCache.setStoredEfforts( storedEfforts );
						liveEntry.effortsDataTable.addEffortToTable( thisEffort );
					} else {
						console.log( 'match found.' )
					}
					return false;
				} );
			},

			/**
			 * Add a new row to the table (with js dataTables enabled)
			 * 
			 * @param object effort Pass in the object of the effort to add
			 */
			addEffortToTable: function( effort ) {

				// initiate datatable plugin
				var table = $( document ).find( '.provisional-data-table' ).DataTable();

				var trHtml = '\
					<tr class="effort-station-row js-effort-station-row" data-effort-object="' + JSON.stringify( effort ) + '" >\
						<td class="split-name js-split-name">' + effort.splitName + '</td>\
						<td class="bib-number js-bib-number">' + effort.bibNumber + '</td>\
						<td class="time-in js-time-in">' + effort.timeIn + '</td>\
						<td class="time-out js-time-out">' + effort.timeOut + '</td>\
						<td class="pacer-in js-pacer-in">' + effort.pacerInHtml + '</td>\
						<td class="pacer-out js-pacer-out">' + effort.pacerInHtml + '</td>\
						<td class="effort-name js-effort-name">' + effort.effortName + '</td>\
						<td class="row-edit-btns">\
							<button class="effort-row-btn fa fa-pencil edit-effort js-edit-effort btn btn-primary"></button>\
							<button class="effort-row-btn fa fa-close delete-effort js-delete-effort btn btn-danger"></button>\
							<button class="effort-row-btn fa fa-check submit-effort js-submit-effort btn btn-success"></button>\
						</td>\
					</tr>';
				//table.row().add( ).draw();
			},

			/**
			 * Move a "cached" table row to "top form" section for editing.
			 *
			 */
			editEffort: function() {

				$( '.js-provisional-data-table .js-effort-station-row' ).each( function() {

					var $thisRow = $( this );
					var dataTable = $thisRow.closest( '.js-provisional-data-table' ).DataTable();
					var effort = {};
					effort.uniqueId = $thisRow.attr( 'data-unique-id' );
					effort.eventId = $thisRow.attr( 'data-event-id' );
					effort.splitId = $thisRow.attr( 'data-split-id' );
					effort.effortId = $thisRow.attr( 'data-effort-id' );
					effort.bibNum = $thisRow.attr( 'data-bib-number' );
					effort.effortName = $thisRow.attr( 'data-effort-name' );
					effort.splitName = $thisRow.attr( 'data-split-name' );
					effort.timeIn = $thisRow.attr( 'data-time-in' );
					effort.timeOut = $thisRow.attr( 'data-time-out' );
					effort.pacerIn = $thisRow.attr( 'data-pacer-in' );
					effort.pacerOut = $thisRow.attr( 'data-pacer-out' );

					$thisRow.on( 'click', '.js-edit-effort', function( event ) {
						event.preventDefault();

						// remove table row
						$thisRow.fadeOut( 'fast', function() {
							dataTable.row( $( this ).closest( 'tr' ) ).remove().draw();
						} );

						console.log( effort );


						var repopulateEffortForm = function( effortData ) {
							var storedEfforts = getStoredEfforts();
							console.log( storedEfforts );

							$( document ).find( '#bib-number' ).val( effortData.bibNum );
						}
						repopulateEffortForm( effort );

						// $( '.edit-effort-modal .modal-title .split-name' ).html( effortData.splitName );
						// $( '.edit-effort-modal .js-effort-id-input' ).val( effortData.effortId );
						// $( '.edit-effort-modal .js-split-name-input' ).val( effortData.splitName );
						// $( '.edit-effort-modal .js-bib-number-input' ).val( effortData.bibNum );
						// $( '.edit-effort-modal .js-effort-name-input' ).val( effortData.effortName );
						// $( '.edit-effort-modal .js-time-in-input' ).val( effortData.timeIn );
						// $( '.edit-effort-modal .js-time-out-input' ).val( effortData.timeOut );

						// if( effortData.pacerIn === 'true' ) {
						// 	$( '.edit-effort-modal .js-pacer-in-check' ).prop( 'checked', true );
						// } else {
						// 	$( '.edit-effort-modal .js-pacer-in-check' ).prop( 'checked', false );
						// }

						// if( effortData.pacerOut === 'true' ) {
						// 	$( '.edit-effort-modal .js-pacer-out-check' ).prop( 'checked', true );
						// } else {
						// 	$( '.edit-effort-modal .js-pacer-out-check' ).prop( 'checked', false );
						// }
					} );

					$thisRow.on( 'click', '.js-delete-effort', function( event ) {
						event.preventDefault();
						liveEntry.deleteEffortRows( $thisRow );
						console.log( 'row removed' );
						return false;
					} );

					$thisRow.on( 'click', '.js-submit-effort', function( event ) {
						event.preventDefault();
						liveEntry.submitEffortRows( $thisRow );
						console.log( 'row submitted' );
						return false;
					} );

				} );

				$( '.js-delete-all-efforts' ).on( 'click', function( event ) {
						event.preventDefault();
						liveEntry.deleteEffortRows( $( '.js-provisional-data-table .js-effort-station-row' ) );
						console.log( 'rows removed' );
						return false;
				} );

				$( '.js-submit-all-efforts' ).on( 'click', function( event ) {
						event.preventDefault();
						liveEntry.submitEffortRows( $( '.js-provisional-data-table .js-effort-station-row' ) );
						console.log( 'rows submitted' );
						return false;
				} );
			},

			/**
			 * Removes each of supplied efforts in one batch
			 * 
			 * @param  object $effortRows jQuery object containing each row to remove
			 */
			deleteEffortRows: function( $effortRows ) {
				$effortRows.fadeOut( 'fast', function() {
					var dataTable = $( this ).closest( '.js-provisional-data-table' ).DataTable();
					dataTable.row( $( this ).closest( 'tr' ) ).remove().draw();
				} );
			},

			/**
			 * Submits each of supplied efforts in one batch
			 * 
			 * @param  object $effortRows jQuery object containing each row to submit
			 */
			submitEffortRows: function( $effortRows ) {
				var data = { efforts: [] };
				$effortRows.each( function() {
					var $thisRow = $( this );
					var effort = {};
					effort.uniqueId = $thisRow.attr( 'data-unique-id' );
					effort.eventId = $thisRow.attr( 'data-event-id' );
					effort.splitId = $thisRow.attr( 'data-split-id' );
					effort.effortId = $thisRow.attr( 'data-effort-id' );
					effort.bibNum = $thisRow.attr( 'data-bib-number' );
					effort.effortName = $thisRow.attr( 'data-effort-name' );
					effort.splitName = $thisRow.attr( 'data-split-name' );
					effort.timeIn = $thisRow.attr( 'data-time-in' );
					effort.timeOut = $thisRow.attr( 'data-time-out' );
					effort.pacerIn = $thisRow.attr( 'data-pacer-in' );
					effort.pacerOut = $thisRow.attr( 'data-pacer-out' );
					data.efforts.push( effort );
				} );
				$.get( '/events/' + liveEntry.currentEventId + '/live_entry_ajax_set_split_times', data, function( response ) {
					console.log( response );
				} );
			}
		}, // END effortsDataTable

		splitSlider: {

			/**
			 * Init splits slider
			 *
			 */
			init: function() {
				liveEntry.splitSlider.buildSplitSlider();
			},

			/**
			 * Builds the splits slider based on the splits data
			 *
			 */
			buildSplitSlider: function() {

				// Inject initial html
				var splitSliderItems = '';
				for ( var i = 0; i < liveEntry.eventLiveEntryStaticData.splits.length; i++ ) {
					splitSliderItems += '<div class="split-slider-item js-split-slider-item" data-split-id="' + liveEntry.eventLiveEntryStaticData.splits[ i ].id + '" ><span class="split-slider-item-dot"></span><span class="split-slider-item-name">' + liveEntry.eventLiveEntryStaticData.splits[ i ].name + '</span><span class="split-slider-item-distance">' + liveEntry.eventLiveEntryStaticData.splits[ i ].distance + ' m</span></div>';
				}
				$( '#js-split-slider' ).html( splitSliderItems );

				// Set default states
				$( '.js-split-slider-item' ).eq( 0 ).addClass( 'active middle' );
				$( '.js-split-slider-item' ).eq( 1 ).addClass( 'active end' );
				$( '#js-split-slider' ).addClass( 'begin' );
				$( '#split-select' ).on( 'change', function() {
					var currentItemId = $( '.js-split-slider-item.active.middle' ).attr( 'data-split-id' );
					var selectedItemId = $( 'option:selected' ).attr( 'data-split-id' );
					if ( currentItemId - selectedItemId > 1 ) {
						liveEntry.splitSlider.changeSplitSlider( selectedItemId - 0 + 1 );
					} else if ( selectedItemId - currentItemId > 1 ) {
						liveEntry.splitSlider.changeSplitSlider( selectedItemId - 1 );
					}
					setTimeout( function() {
						$( '#js-split-slider' ).addClass( 'animate' );
						liveEntry.splitSlider.changeSplitSlider( selectedItemId );
						setTimeout( function () {
							$( '#js-split-slider' ).removeClass( 'animate' );
						}, 600 );
					}, 1 );
				} );
			},

			/**
			 * Switches the Split Slider to the specified Aid Station
			 * 
			 * @param  integer splitId The station id to switch to
			 */
			changeSplitSlider: function( splitId ) {
				
				// remove all positioning classes
				$( '#js-split-slider' ).removeClass( 'begin end' );
				$( '.js-split-slider-item' ).removeClass( 'active inactive middle begin end' );
				var $selectedSliderItem = $( '.js-split-slider-item[data-split-id="' + splitId + '"]' );

				// Add position classes to the current selected slider item
				$selectedSliderItem.addClass( 'active middle' );
				$selectedSliderItem
					.next( '.js-split-slider-item' ).addClass( 'active end' )
					.next( '.js-split-slider-item' ).addClass( 'inactive end' );
				$selectedSliderItem
					.prev( '.js-split-slider-item' ).addClass( 'active begin' )
					.prev( '.js-split-slider-item' ).addClass( 'inactive begin' );;

				// Check if the slider is at the beginning
				if ( $selectedSliderItem.prev('.js-split-slider-item').length === 0 ) {

					// Add appropriate positioning classes
					$( '#js-split-slider' ).addClass( 'begin' );
				}

				// Check if the slider is at the end
				if ( $selectedSliderItem.next( '.js-split-slider-item' ).length === 0 ) {
					$( '#js-split-slider' ).addClass( 'end' );
				}
			}
		} // END splitSlider
	};

	$( document ).ready( function() {
		liveEntry.init();
	} );
} )( jQuery );

(function ($) {

    /**
     * UI object for the live event view
     *
     */
    var liveEntry = {


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

        eventLiveEntryData: null,

        lastReportedSplitId: null,

        lastReportedBitkey: null,

        timeFromStartIn: null,

        timeFromStartOut: null,

        currentSplitId: null,


        getEventLiveEntryData: function () {
            return $.get('/live/events/' + liveEntry.currentEventId + '/get_event_data', function (response) {
                liveEntry.eventLiveEntryData = response

            })

        },

        /**
         * This kicks off the full UI
         *
         */
        init: function () {
            // localStorage.clear();

            // Sets the currentEventId once
            liveEntry.currentEventId = $('#js-event-id').text();
            liveEntry.getEventLiveEntryData().done(function () {
                liveEntry.timeRowsCache.init();
                liveEntry.header.init();
                liveEntry.liveEntryForm.init();
                liveEntry.timeRowsTable.init();
                liveEntry.splitSlider.init();
            });
        },

        /**
         * Contains functionality for the times data cache
         *
         */
        timeRowsCache: {

            /**
             * Inits the times data cache
             *
             */
            init: function () {

                // Set the initial cache object in local storage
                var timeRowsCache = localStorage.getItem('timeRowsCache');
                if (timeRowsCache === null || timeRowsCache.length == 0) {
                    localStorage.setItem('timeRowsCache', JSON.stringify([]));
                }
            },

            /**
             * Get local timeRows Storage Object
             *
             * @return object Returns object from local storage
             */
            getStoredTimeRows: function () {
                return JSON.parse(localStorage.getItem('timeRowsCache'))
            },

            /**
             * Stringify then Save/Push all timeRows to local object
             *
             * @param object timeRowsObject Pass in the object of the updated object with all added or removed objects.
             * @return null
             */
            setStoredTimeRows: function (timeRowsObject) {
                localStorage.setItem('timeRowsCache', JSON.stringify(timeRowsObject));
                return null;
            },

            /**
             * Delete the matching timeRow
             *
             * @param object    timeRow    Pass in the object/timeRow we want to delete.
             * @return null
             */
            deleteStoredTimeRow: function (timeRow) {
                var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                $.each(storedTimeRows, function (index) {
                    if (this.uniqueId == timeRow.uniqueId) {
                        storedTimeRows = storedTimeRows.slice(index + 1);
                        return false;
                    }
                });
                localStorage.setItem('timeRowsCache', JSON.stringify(storedTimeRows));
                return null;
            },

            /**
             * Compare timeRow to all timeRows in local storage. Add if it doesn't already exist, or throw an error message.
             *
             * @param  object timeRow Pass in Object of the timeRow to check it against the stored objects         *
             * @return boolean    True if match found, False if no match found
             */
            isMatchedTimeRow: function (timeRow) {
                var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                var tempTimeRow = JSON.stringify(timeRow);
                var flag = false;

                $.each(storedTimeRows, function () {
                    var loopedTimeRow = JSON.stringify($(this));
                    if (loopedTimeRow == tempTimeRow) {
                        flag = true;
                    }
                });

                if (flag == false) {
                    return false;
                } else {
                    return true;
                }
                ;
            },
        },
        /**
         * Functionality to build header lives here
         *
         */
        header: {
            init: function () {
                liveEntry.header.updateEventName();
                liveEntry.header.buildSplitSelect();
            },

            /**
             * Populate the h2 with the eventName
             *
             */
            updateEventName: function () {
                $('.page-title h2').text(liveEntry.eventLiveEntryData.eventName);
            },

            /**
             * Add the Splits data to the select drop down table on the page
             *
             */
            buildSplitSelect: function () {
                var $select = $( '#split-select' );
                // Populate select list with event splits
                // Sub_split_in and sub_split_out are boolean fields indicating the existence of in and out time fields respectively.
                var splitItems = '';
                for (var i = 1; i < liveEntry.eventLiveEntryData.splits.length; i++) {
                    splitItems += '<option value="' + liveEntry.eventLiveEntryData.splits[i].base_name + '" data-sub-split-in="' + liveEntry.eventLiveEntryData.splits[i].sub_split_in + '" data-sub-split-out="' + liveEntry.eventLiveEntryData.splits[i].sub_split_out + '" data-split-id="' + liveEntry.eventLiveEntryData.splits[i].id + '" >' + liveEntry.eventLiveEntryData.splits[i].base_name + '</option>';
                }
                $select.html( splitItems );
                // Syncronize Select with splitId
                $select.children().first().prop( 'selected', true );
                liveEntry.currentSplitId = $('option:selected').attr('data-split-id');
            },
        },

        /**
         * Contains functionality for the timeRow form
         *
         */
        liveEntryForm: {
            init: function () {
                // Apply input masks on time in / out
                var maskOptions = {
                    placeholder: "hh:mm:ss",
                    insertMode: false,
                    showMaskOnHover: false,
                };

                $('#js-time-in').inputmask("hh:mm:ss", maskOptions);
                $('#js-time-out').inputmask("hh:mm:ss", maskOptions);
                $('#js-bib-number').inputmask("9999999999999999999", {placeholder: ""});

                // Clears the live entry form when the clear button is clicked
                $('#js-clear-entry-form').on('click', function (event) {
                    event.preventDefault();
                    liveEntry.liveEntryForm.clearSplitsData();
                    liveEntry.liveEntryForm.toggleFields(false);
                    return false;
                });

                // Listen for keydown on bibNumber
                $('#js-bib-number').on('keydown', function (event) {

                    // Check for tab or enter
                    if (event.keyCode == 13 || event.keyCode == 9) {
                        event.preventDefault();
                        var bibNumber = $(this).val();
                        if (bibNumber == '') {
                            liveEntry.liveEntryForm.toggleFields(false);
                            liveEntry.liveEntryForm.clearSplitsData();
                        } else {

                            // Ajax endpoint for the timeRow data
                            var data = {bibNumber: bibNumber};
                            $.get('/live/events/' + liveEntry.currentEventId + '/get_effort', data, function (response) {
                                if (response.success == true) {
                                    liveEntry.currentEffortId = response.effortId;
                                    liveEntry.lastReportedSplitId = response.lastReportedSplitId;
                                    liveEntry.lastReportedBitkey = response.lastReportedBitkey;

                                    // If success == true, this means the bib number lookup found an effort
                                    $('#js-live-bib').val('true');
                                    $('#js-effort-name').html(response.name);
                                    $('#js-effort-last-reported').html(response.reportText)
                                } else {

                                    // If success == false, this means the bib number lookup failed, but we still need to capture the data
                                    $('#js-live-bib').val('false');
                                    $('#js-effort-name').html('n/a');
                                    $('#js-effort-last-reported').html('n/a')
                                }
                            });
                            liveEntry.liveEntryForm.toggleFields(true);
                            if (!event.shiftKey) {
                                $('#js-time-in').focus();
                            }
                        }
                        return false;
                    }
                });

                // TODO: Would like to have shift-tab functionality for moving to previous field

                $('#js-time-in').on('keydown', function (event) {
                    if (event.keyCode == 13 || event.keyCode == 9) {
                        event.preventDefault();
                        var timeIn = $(this).val();

                        // Validate the military time string
                        if (liveEntry.liveEntryForm.validateTimeFields(timeIn)) {

                            // currentEffortId may be null here
                            var data = {
                                timeIn: timeIn,
                                effortId: liveEntry.currentEffortId,
                                lastReportedSplitId: liveEntry.lastReportedSplitId,
                                lastReportedBitkey: liveEntry.lastReportedBitkey,
                                splitId: liveEntry.currentSplitId  // TODO: Winter--can we put a listener on the splitSelect menu that will set this and keep it in sync?
                            };

                            // TODO: if response.finished = true, set timeFromLastReported and timeSpent to 'n/a'
                            $.get('/live/events/' + liveEntry.currentEventId + '/get_time_from_last', data, function (response) {
                                if (response.success == true) {
                                    $('#js-last-reported').html( response.timeFromLastReported );
                                    liveEntry.timeFromStartIn = response.timeFromStartIn;
                                }
                                if (event.shiftKey) {
                                    $('#js-bib-number').focus();
                                } else {
                                    $('#js-time-out').focus();
                                }
                            });
                        } else {
                            $(this).val('');
                        }
                        return false;
                    }
                });

                $('#js-time-out').on('keydown', function (event) {
                    if (event.keyCode == 13 || event.keyCode == 9) {
                        event.preventDefault();
                        var timeOut = $(this).val();

                        // Validate the military time string
                        if (liveEntry.liveEntryForm.validateTimeFields(timeOut)) {

                            // currentEffortId may be null here
                            var data = {
                                timeOut: timeOut,
                                effortId: liveEntry.currentEffortId,
                                splitId: liveEntry.currentSplitId,
                                timeFromStartIn: liveEntry.timeFromStartIn
                            };

                            $.get('/live/events/' + liveEntry.currentEventId + '/get_time_spent', data, function (response) {
                                if ( response.success == true ) {
                                    $('#js-time-spent').html( response.timeInAid );
                                    liveEntry.timeFromStartOut = response.timeFromStartOut;
                                }
                                if ( event.shiftKey ) {
                                    $('#js-time-in').focus();
                                } else {
                                    $('#js-pacer-in').focus();
                                }
                            });
                        } else {
                            $(this).val('');
                        }
                        return false;
                    }
                });

                // Listen for keydown in pacer-in and pacer-out.
                // Enter checks the box, tab moves to next field.
                $('#js-pacer-in').on('keydown', function (event) {
                    event.preventDefault();
                    var $this = $(this);
                    switch (event.keyCode) {
                        case 13: // Enter pressed
                            if ($this.is(':checked')) {
                                $this.prop('checked', false);
                            } else {
                                $this.prop('checked', true);
                            }
                            break;
                        case 9: // Tab pressed
                            if (event.shiftKey) {
                                $('#js-time-out').focus();
                            } else {
                                $('#js-pacer-out').focus();
                            }
                            break;
                    }
                    return false;
                });

                $('#js-pacer-out').on('keydown', function (event) {
                    event.preventDefault();
                    var $this = $(this);
                    switch (event.keyCode) {
                        case 13: // Enter pressed
                            if ($this.is(':checked')) {
                                $this.prop('checked', false);
                            } else {
                                $this.prop('checked', true);
                            }
                            break;
                        case 9: // Tab pressed
                            if (event.shiftKey) {
                                $('#js-pacer-in').focus();
                            } else {
                                $('#js-add-to-cache').focus();
                            }
                            break;
                    }
                    return false;
                });
            },

            /**
             * Disables or enables fields for the effort lookup form
             *
             * @param bool    True to enable, false to disable
             */
            toggleFields: function (enable) {
                if (enable == true) {
                    $('#js-add-effort-form input:not(#js-bib-number)').removeAttr('disabled');
                } else {
                    $('#js-add-effort-form input:not(#js-bib-number)').attr('disabled', 'disabled');
                    $('#js-add-effort-form input:not(#js-bib-number)').val('');
                    $('#js-bib-number').val('');
                }
            },

            /**
             * Clears out the splits slider data fields
             *
             */
            clearSplitsData: function () {
                $('#js-effort-name').html('&nbsp;');
                $('#js-effort-last-reported').html('&nbsp;')
                $('#js-effort-split-from').html('&nbsp;');
                $('#js-last-reported').html('&nbsp;');
                $('#js-time-spent').html('&nbsp;');
                $('#js-time-in').val('');
                $('#js-time-out').val('');
                $('#js-live-bib').val('');
                $('#js-pacer-in').attr('checked', false);
                $('#js-pacer-out').attr('checked', false);
            },

            /**
             * Valiates the time fields
             *
             * @param string time time format from the input mask
             */
            validateTimeFields: function (time) {
                time = time.replace(/\D/g, '');
                if (time.length == 4) {
                    time = time.concat('00');
                }
                if ((time.length == 0) || (time.length == 6)) {
                    return true;
                } else {
                    return false;
                }
            }
        }, // END liveEntryForm form

        /**
         * Contains functionality for times data cache table
         *
         * TODO: timeRows need to send back the following fields:
         * 		- EffortId
         * 		- SplitId
         * 		- timeFromStartIn: (int) seconds from start
         * 		- timeFromStartOut: (int) seconds from start
         *   	- PacerIn: (bool)
         *      - PacerOut: (bool)
         *      - timeExistsIn (bool)
         *      - timeExistsOut (bool)
         *      - timeStatusIn ('good', 'questionable', 'bad')
         *      - timeStatusOut ('good', 'questionable', 'bad')
         */
        timeRowsTable: {

            /**
             * Stores the object from DataTable
             *
             * @type object
             */
            $dataTable: null,

            /**
             * Inits the provisional data table
             *
             */
            init: function () {

                // Initiate DataTable Plugin
                liveEntry.timeRowsTable.$dataTable = $('#js-provisional-data-table').DataTable();
                liveEntry.timeRowsTable.populateTableFromCache();
                liveEntry.timeRowsTable.timeRowControls();

                // Attach add listener
                $('#js-add-to-cache').on('click', function (event) {
                    event.preventDefault();

                    var data = {
                        effortId: liveEntry.currentEffortId,
                        splitId: liveEntry.currentSplitId,
                        timeFromStartIn: liveEntry.timeFromStartIn,
                        timeFromStartOut: liveEntry.timeFromStartOut
                    };

                    $.get('/live/events/' + liveEntry.currentEventId + '/verify_times_data', data, function (response) {
                        if ( response.success == true ) {
                            var thisTimeRow = {};

                            // Check table stored timeRows for highest unique ID then create a new one.
                            var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                            var storedUniqueIds = [];
                            if (storedTimeRows.length > 0) {
                                $.each(storedTimeRows, function (index, value) {
                                    storedUniqueIds.push(this.uniqueId);
                                });
                                var highestUniqueId = Math.max.apply(Math, storedUniqueIds);
                                thisTimeRow.uniqueId = highestUniqueId + 1;
                            } else {
                                thisTimeRow.uniqueId = 0;
                            }

                            // Build up the timeRow
                            thisTimeRow.eventId = liveEntry.currentEventId;
                            thisTimeRow.splitId = $(document).find('#split-select option:selected').attr('data-split-id');
                            thisTimeRow.splitName = $(document).find('#split-select option:selected').html();
                            thisTimeRow.effortId = liveEntry.currentEffortId;
                            thisTimeRow.timeFromStartIn = liveEntry.timeFromStartIn;
                            thisTimeRow.timeFromStartOut = liveEntry.timeFromStartOut;
                            thisTimeRow.timeInStatus = response.timeInStatus;
                            thisTimeRow.timeOutStatus = response.timeOutStatus;
                            thisTimeRow.bibNumber = $('#js-bib-number').val();
                            thisTimeRow.liveBib = $('#js-live-bib').val();
                            thisTimeRow.effortName = $('#js-effort-name').html();
                            thisTimeRow.timeIn = $('#js-time-in').val();
                            thisTimeRow.timeOut = $('#js-time-out').val();

                            // TODO: need to save TimeFromStartIn and TimeFromStartOut
                            if ($('#js-pacer-in').prop('checked') == true) {
                                thisTimeRow.pacerIn = true;
                                thisTimeRow.pacerInHtml = 'Yes';
                            } else {
                                thisTimeRow.pacerIn = false;
                                thisTimeRow.pacerInHtml = 'No';
                            }
                            if ($('#js-pacer-out').prop('checked') == true) {
                                thisTimeRow.pacerOut = true;
                                thisTimeRow.pacerOutHtml = 'Yes';
                            } else {
                                thisTimeRow.pacerOut = false;
                                thisTimeRow.pacerOutHtml = 'No';
                            }
                            if (!liveEntry.timeRowsCache.isMatchedTimeRow(thisTimeRow)) {
                                storedTimeRows.push(thisTimeRow);
                                liveEntry.timeRowsCache.setStoredTimeRows(storedTimeRows);
                                liveEntry.timeRowsTable.addTimeRowToTable(thisTimeRow);
                            }

                            // Clear data and disable fields once we've collected all the data
                            liveEntry.liveEntryForm.clearSplitsData();
                            liveEntry.liveEntryForm.toggleFields(false);
                        }
                    });
                    return false;
                });
            },

            populateTableFromCache: function () {
                var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                $.each(storedTimeRows, function (index) {
                    liveEntry.timeRowsTable.addTimeRowToTable(this);
                });
            },

            /**
             * Add a new row to the table (with js dataTables enabled)
             *
             * @todo  when adding a 
             * @param object timeRow Pass in the object of the timeRow to add
             */
            addTimeRowToTable: function (timeRow) {

                var rowClass = '';
                if ( timeRow.timeInStatus === 'bad' || timeRow.timeOutStatus === 'bad' ) {
                    rowClass = 'bad';
                } else if ( timeRow.timeInStatus === 'questionable' || timeRow.timeOutStatus === 'questionable' ) {
                    rowClass = 'questionable';
                }

                // Base64 encode the stringifyed timeRow to add to the timeRow
                // This is ie9 incompatible
                var base64encodedTimeRow = btoa(JSON.stringify(timeRow));
                var trHtml = '\
					<tr class="effort-station-row js-effort-station-row ' + rowClass + '" data-encoded-effort="' + base64encodedTimeRow + '" >\
						<td class="split-name js-split-name">' + timeRow.splitName + '</td>\
						<td class="bib-number js-bib-number">' + timeRow.bibNumber + '</td>\
                        <td class="time-in js-time-in ' + timeRow.timeInStatus + '">' + timeRow.timeIn + '</td>\
                        <td class="time-out js-time-out ' + timeRow.timeOutStatus + '">' + timeRow.timeOut + '</td>\
						<td class="pacer-in js-pacer-in">' + timeRow.pacerInHtml + '</td>\
						<td class="pacer-out js-pacer-out">' + timeRow.pacerInHtml + '</td>\
						<td class="effort-name js-effort-name">' + timeRow.effortName + '</td>\
						<td class="row-edit-btns">\
							<button class="effort-row-btn fa fa-pencil edit-effort js-edit-effort btn btn-primary"></button>\
							<button class="effort-row-btn fa fa-close delete-effort js-delete-effort btn btn-danger"></button>\
							<button class="effort-row-btn fa fa-check submit-effort js-submit-effort btn btn-success"></button>\
						</td>\
					</tr>';
                liveEntry.timeRowsTable.$dataTable.row.add($(trHtml)).draw();
            },

            /**
             * Move a "cached" table row to "top form" section for editing.
             *
             */
            timeRowControls: function () {

                $(document).on('click', '.js-edit-effort', function (event) {
                    event.preventDefault();
                    var $row = $(this).closest('tr');
                    var clickedTimeRow = JSON.parse(atob($row.attr('data-encoded-effort')));

                    // remove timeRow from cache
                    liveEntry.timeRowsCache.deleteStoredTimeRow(clickedTimeRow);

                    // remove table row
                    $row.fadeOut('fast', function () {
                        liveEntry.timeRowsTable.$dataTable.row($row).remove().draw();
                    });

                    // Put bib number back into the bib number field
                    var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                    $('#js-bib-number').val(clickedTimeRow.bibNumber).focus();
                });

                $(document).on('click', '.js-delete-effort', function (event) {
                    var $row = $(this).closest('tr');
                    var clickedTimeRow = JSON.parse(atob($row.attr('data-encoded-effort')));

                    // remove timeRow from cache
                    liveEntry.timeRowsCache.deleteStoredTimeRow(clickedTimeRow);

                    // remove table row
                    $row.fadeOut('fast', function () {
                        liveEntry.timeRowsTable.$dataTable.row($row).remove().draw();
                    });

                });

                $(document).on('click', '.js-submit-effort', function () {
                    var $row = $(this).closest('tr');
                    var clickedTimeRow = JSON.parse(atob($row.attr('data-encoded-effort')));
                    var data = {timeRows: [clickedTimeRow]};
                    $.get('/live/events/' + liveEntry.currentEventId + '/set_split_times', data, function (response) {
                        if (response.success) {
                            $row.find('.js-delete-effort').click();
                        }
                    });
                });

                $('#js-delete-all-efforts').on('click', function (event) {
                    event.preventDefault();
                    $('.js-effort-station-row').each(function () {
                        var $row = $(this).closest('tr');
                        var timeRowObject = JSON.parse(atob($row.attr('data-encoded-effort')));

                        // remove timeRow from cache
                        liveEntry.timeRowsCache.deleteStoredTimeRow(timeRowObject);

                        // remove table row
                        $row.fadeOut('fast', function () {
                            liveEntry.timeRowsTable.$dataTable.row($row).remove().draw();
                        });
                    });
                    return false;
                });

                $('#js-submit-all-efforts').on('click', function (event) {
                    event.preventDefault();
                    var data = {timeRows: []};
                    $('.js-effort-station-row').each(function () {
                        var $row = $(this).closest('tr');
                        var timeRowObject = JSON.parse(atob($row.attr('data-encoded-effort')));
                        data.timeRows.push(timeRowObject);
                    });

                    $.get('/live/events/' + liveEntry.currentEventId + '/set_split_times', data, function (response) {
                        if (response.success) {
                            $('#js-delete-all-efforts').click();
                        }
                    });
                    return false;
                });
            },
        }, // END timeRowsTable

        splitSlider: {

            /**
             * Init splits slider
             *
             */
            init: function () {
                liveEntry.splitSlider.buildSplitSlider();
                liveEntry.splitSlider.changeSplitSlider( liveEntry.currentSplitId );
            },

            /**
             * Builds the splits slider based on the splits data
             *
             */
            buildSplitSlider: function () {

                // Inject initial html
                var splitSliderItems = '';
                for (var i = 0; i < liveEntry.eventLiveEntryData.splits.length; i++) {
                    splitSliderItems += '<div class="split-slider-item js-split-slider-item" data-split-id="' + liveEntry.eventLiveEntryData.splits[i].id + '" ><span class="split-slider-item-dot"></span><span class="split-slider-item-name">' + liveEntry.eventLiveEntryData.splits[i].base_name + '</span><span class="split-slider-item-distance">' + liveEntry.eventLiveEntryData.splits[i].distance_from_start + '</span></div>';
                }
                $('#js-split-slider').html(splitSliderItems);

                // Set default states
                $('.js-split-slider-item').eq(0).addClass('active middle');
                $('.js-split-slider-item').eq(1).addClass('active end');
                $('#js-split-slider').addClass('begin');
                $('#split-select').on('change', function () {
                    var currentItemId = $('.js-split-slider-item.active.middle').attr('data-split-id');
                    var selectedItemId = $('option:selected').attr('data-split-id');
                    if (currentItemId - selectedItemId > 1) {
                        liveEntry.splitSlider.changeSplitSlider(selectedItemId - 0 + 1);
                    } else if (selectedItemId - currentItemId > 1) {
                        liveEntry.splitSlider.changeSplitSlider(selectedItemId - 1);
                    }
                    setTimeout(function () {
                        $('#js-split-slider').addClass('animate');
                        liveEntry.splitSlider.changeSplitSlider(selectedItemId);
                        liveEntry.currentSplitId = selectedItemId;
                        setTimeout(function () {
                            $('#js-split-slider').removeClass('animate');
                        }, 600);
                    }, 1);
                });
            },

            /**
             * Switches the Split Slider to the specified Aid Station
             *
             * @param  integer splitId The station id to switch to
             */
            changeSplitSlider: function (splitId) {

                // remove all positioning classes
                $('#js-split-slider').removeClass('begin end');
                $('.js-split-slider-item').removeClass('active inactive middle begin end');
                var $selectedSliderItem = $('.js-split-slider-item[data-split-id="' + splitId + '"]');

                // Add position classes to the current selected slider item
                $selectedSliderItem.addClass('active middle');
                $selectedSliderItem
                    .next('.js-split-slider-item').addClass('active end')
                    .next('.js-split-slider-item').addClass('inactive end');
                $selectedSliderItem
                    .prev('.js-split-slider-item').addClass('active begin')
                    .prev('.js-split-slider-item').addClass('inactive begin');
                ;

                // Check if the slider is at the beginning
                if ($selectedSliderItem.prev('.js-split-slider-item').length === 0) {

                    // Add appropriate positioning classes
                    $('#js-split-slider').addClass('begin');
                }

                // Check if the slider is at the end
                if ($selectedSliderItem.next('.js-split-slider-item').length === 0) {
                    $('#js-split-slider').addClass('end');
                }
            }
        } // END splitSlider
    }; // END liveEntry

    $('.events.live_entry').ready(function () {
        liveEntry.init();
    });
})(jQuery);
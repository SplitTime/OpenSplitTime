(function ($) {

    /**
     * UI object for the live event view
     *
     */
    var liveEntry = {


        /**
         * Stores the ID for the current event_group
         * this is pulled from the url and dumped on the page
         * then stored in this variable
         *
         * @type integer
         */
        currentEventGroupId: null,

        currentEffortData: {},

        lastEffortRequest: {},

        eventLiveEntryData: null,

        lastReportedSplitId: null,

        lastReportedBitkey: null,

        currentStationIndex: null,

        getEventLiveEntryData: function () {
            return $.get('/api/v1/event_groups/' + liveEntry.currentEventGroupId + '?include=events.efforts')
                .then(function (response) {
                    liveEntry.eventLiveEntryData = response;
                    liveEntry.timeRowsCache.init();
                    liveEntry.header.init();
                    liveEntry.liveEntryForm.init();
                    liveEntry.timeRowsTable.init();
                    liveEntry.splitSlider.init();
                    liveEntry.pusher.init();
                    liveEntry.bibEventMap = {};

                    response.included
                        .filter(function(current){
                            return current.type === 'efforts';
                        }).forEach(n => {
                            liveEntry.bibEventMap[n.attributes.bibNumber] = n.attributes.eventId;
                        });
                });
        },

        splitsAttributes: function () {
          return liveEntry.eventLiveEntryData.data.attributes.combinedSplitAttributes
        },

        eventIdFromBib: function(bibNumber) {
            if (typeof liveEntry.bibEventMap !== 'undefined' && bibNumber !== '') {
                return liveEntry.bibEventMap[bibNumber]
            } else {
                return null
            }
        },

        getSplitId: function (eventId, splitIndex) {
            let id = String(eventId);
            return liveEntry.splitsAttributes()[splitIndex].entries[0].eventSplitIds[id]
        },

        /**
         * This kicks off the full UI
         *
         */
        init: function () {
            // localStorage.clear();

            // Sets the currentEventGroupId once
            liveEntry.currentEventGroupId = $('#js-event-group-id').data('event-group-id');
            liveEntry.getEventLiveEntryData();
            liveEntry.importLiveWarning = $('#js-import-live-warning').hide().detach();
            liveEntry.importLiveError = $('#js-import-live-error').hide().detach();
            liveEntry.newTimesAlert = $('#js-new-times-alert').hide();
            liveEntry.PopulatingFromRow = false;
            
        },

        pusher: {
            init: function() {
                // Listen to push notifications
                var liveTimesPusherKey = $('#js-live-times-pusher').data('key');
                var pusher = new Pusher(liveTimesPusherKey);
                var channel = {};
                if (typeof liveEntry.eventLiveEntryData === 'undefined') {
                    // Just for safety, abort this init if there is no event data
                    // and avoid breaking execution
                    return;
                }
                if (typeof liveEntry.eventLiveEntryData.eventId === 'undefined') {
                    // Just for safety, abort this init if there is no eventID
                    // and avoid breaking execution
                    return;
                }
                channel = pusher.subscribe('live_times_available_' + liveEntry.eventLiveEntryData.eventId);
                channel.bind('pusher:subscription_succeeded', function() {
                    // Force the server to trigger a push for initial display
                    liveEntry.triggerLiveTimesPush();
                });
                channel.bind('update', function (data) {
                    // New value pushed from the server
                    // Display updated number of new live times on Pull Times button
                    if (typeof data.count === 'number') {
                        liveEntry.pusher.displayNewCount(data.count);
                        return;
                    }
                    liveEntry.pusher.displayNewCount(0);
                });
            },
            displayNewCount: function(count) {
                var text = '';
                if (count > 0) {
                    $('#js-new-times-alert').fadeTo(500, 1);
                    text = count;
                } else {
                    $('#js-new-times-alert').fadeTo(500, 0, function() {$('#js-new-times-alert').hide()});
                }
                $('#js-pull-times-count').text(text);
            }
        },

        triggerLiveTimesPush: function() {
            var endpoint = '/api/v1/events/' + liveEntry.eventLiveEntryData.eventId + ' /trigger_live_times_push';
            $.ajax({
                url: endpoint,
                cache: false
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
             * Check table stored timeRows for highest unique ID, then return a new one.
             * @return integer Unique Time Row Id
             */
            getUniqueId: function () {
                // Check table stored timeRows for highest unique ID then create a new one.
                var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                var storedUniqueIds = [];
                if (storedTimeRows.length > 0) {
                    $.each(storedTimeRows, function (index, value) {
                        storedUniqueIds.push(this.uniqueId);
                    });
                    var highestUniqueId = Math.max.apply(Math, storedUniqueIds);
                    return highestUniqueId + 1;
                } else {
                    return 0;
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
                        storedTimeRows.splice(index, 1);
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
                $('.page-title h2').text(liveEntry.eventLiveEntryData.data.attributes.name.concat(': Live Data Entry'));
            },

            /**
             * Add the Splits data to the select drop down table on the page
             *
             */
            buildSplitSelect: function () {
                var $select = $('#split-select');
                // Populate select list with event splits
                // Sub_split_in and sub_split_out are boolean fields indicating the existence of in and out time fields respectively.
                var splitItems = '';
                for (var i = 0; i < liveEntry.splitsAttributes().length; i++) {
                    let subSplitIn = liveEntry.splitsAttributes()[i].entries.reduce((p, c) => p || c.subSplitKind === 'in', false);
                    let subSplitOut = liveEntry.splitsAttributes()[i].entries.reduce((p, c) => p || c.subSplitKind === 'out', false);
                    splitItems += '<option data-sub-split-in="'+ subSplitIn +'" data-sub-split-out="'+ subSplitOut +'" value="' + i + '">';
                    splitItems += liveEntry.splitsAttributes()[i].title + '</option>';

                }
                $select.html(splitItems);
                // Syncronize Select with splitId
                $select.children().first().prop('selected', true);
                liveEntry.currentStationIndex = $select.val();
            },
        },

        /**
         * Contains functionality for the timeRow form
         *
         */
        liveEntryForm: {
            lastBib: null,
            lastSplit: null,
            init: function () {
                // Apply input masks on time in / out
                var maskOptions = {
                    placeholder: "hh:mm:ss",
                    insertMode: false,
                    showMaskOnHover: false,
                };

                $('#js-add-effort-form [data-toggle="tooltip"]').tooltip({container: 'body'});

                $('#js-time-in').inputmask("hh:mm:ss", maskOptions);
                $('#js-time-out').inputmask("hh:mm:ss", maskOptions);
                $('#js-bib-number').inputmask("Regex", {regex: "[0-9|*]{0,6}"});
                $('#js-lap-number').inputmask("integer", { min: 1, max: liveEntry.eventLiveEntryData.maximumLaps || undefined });

                // Enabled / Disable Laps field
                $('#js-bib-number').closest('div').toggleClass('col-xs-3', liveEntry.eventLiveEntryData.multiLap || false);
               liveEntry.eventLiveEntryData.multiLap && $('.lap-disabled').removeClass('lap-disabled');

                // Styles the Dropped Here button
                $('#js-dropped').on('change', function (event) {
                    var $root = $(this).parent();
                    if ($(this).prop('checked')){
                        $root.addClass('btn-warning').removeClass('btn-default');
                        $('.glyphicon', $root).addClass('glyphicon-check').removeClass('glyphicon-unchecked');
                    } else {
                        $root.addClass('btn-default').removeClass('btn-warning');
                        $('.glyphicon', $root).addClass('glyphicon-unchecked').removeClass('glyphicon-check');
                    }
                });

                // Clears the live entry form when the clear button is clicked
                $('#js-clear-entry-form').on('click', function (event) {
                    event.preventDefault();
                    liveEntry.liveEntryForm.clearSplitsData();
                    $('#js-bib-number').focus();
                    return false;
                });

                // Listen for keydown on bibNumber
                $('#js-bib-number').on('blur', function (event) {
                    liveEntry.liveEntryForm.fetchEffortData();
                });

                $('#js-time-in').on('blur', function (event) {
                    var timeIn = $(this).val();
                    timeIn = liveEntry.liveEntryForm.validateTimeFields(timeIn);
                    if (timeIn === false) {
                        $(this).val('');
                    } else {
                        $(this).val(timeIn);
                        liveEntry.liveEntryForm.fetchEffortData();
                    }
                });

                $('#js-time-out').on('blur', function (event) {
                    var timeIn = $(this).val();
                    timeIn = liveEntry.liveEntryForm.validateTimeFields(timeIn);
                    if (timeIn === false) {
                        $(this).val('');
                    } else {
                        $(this).val(timeIn);
                        liveEntry.liveEntryForm.fetchEffortData();
                    }
                });

                $('#js-rapid-time-in,#js-rapid-time-out').on('click', function (event) {
                    if ( $( this ).siblings( 'input:disabled' ).length ) return;
                    var rapid = $(this).closest('.form-group').toggleClass( 'has-highlight' ).hasClass( 'has-highlight' );
                    $(this).closest('.form-group').toggleClass( 'rapid-mode', rapid );
                });

                // Enable / Disable Rapid Entry Mode
                $('#js-rapid-mode').on('change', function (event) {
                    liveEntry.liveEntryForm.rapidEntry = $(this).prop('checked');
                    $('#js-time-in, #js-time-out').closest('.form-group').toggleClass('has-success', $(this).prop('checked'));
                }).change();

                // Listen for keydown in pacer-in and pacer-out.
                // Enter checks the box, tab moves to next field.

                $('#js-dropped-button').on('click', function (event) {
                    event.preventDefault();
                    $('#js-dropped').prop('checked', !$('#js-dropped').prop('checked')).change();
                    return false;
                });

                $('#js-html-modal').on('show.bs.modal', function(e) {
                    $(this).find('modal-body').html('');
                    var $source = $(e.relatedTarget);
                    var $body = $(this).find('.js-modal-content');
                    if ($source.attr('data-effort-id')) {
                        var data = {
                            'effortId': $source.attr('data-effort-id')
                        }
                        $.get('/live/events/' + liveEntry.currentEventGroupId + '/effort_table', data)
                            .done( function(a,b,c) {
                                $body.html(a);
                            });
                    } else {
                        e.preventDefault();
                    }
                });
            },

            /**
             * Fetches any available information for the data entered.
             */
            fetchEffortData: function() {
                var currentSplit, timeData;
                if (liveEntry.PopulatingFromRow) {
                    // Do nothing.
                    // This fn is being called from several places based
                    // on different actions.
                    // None of them are needed if the form is being populated
                    // by the system from a Local row's data
                    // (User clicks on Edit icon in a Local Data Workspace row)
                    // This flag will be on while the form is populated by that action
                    // and turnedd of when that's done.
                    return $.Deferred().resolve();
                }
                liveEntry.liveEntryForm.prefillCurrentTime();
                var bibNumber = $('#js-bib-number').val();
                var bibChanged = ( bibNumber != liveEntry.liveEntryForm.lastBib );
                var splitChanged = ( liveEntry.currentStationIndex != liveEntry.liveEntryForm.lastSplit );
                liveEntry.liveEntryForm.lastBib = bibNumber;
                liveEntry.liveEntryForm.lastSplit = liveEntry.currentStationIndex;

                var currentEventId = liveEntry.eventIdFromBib(bibNumber);

                // This is the splitEntry data corresponding to the selected AidStation
                // Looks like: 
                currentSplitEntries = liveEntry.splitsAttributes()[liveEntry.currentStationIndex].entries;

                // Each subsplit populates one item in the timeData array to be sent to the server
                // timeData: [{splitId: x, time: '12:34', subSplitKind: 'in', lap: 1}, {splitId: x, time: '12:34', subSplitKind: 'out', lap: 1}]
                timeData = currentSplitEntries.map(function(eachVal) {
                    var newObj = {};
                    newObj.subSplitKind = eachVal.subSplitKind;
                    newObj.lap = $('#js-lap-number').val();
                    // splitId defaults to null if no bibNumber was entered
                    newObj.splitId = currentEventId !== null ? eachVal.eventSplitIds[currentEventId] : null;
                    return newObj;
                });
                timeData.forEach(function(el, index) {

                    // Use time IN for the first subsplit and time OUT for the second one, if there is one
                    // This should be updated when Group Live Entry supports variable time fields
                    timeData[index]['time'] = index === 1 ? $('#js-time-out').val() : $('#js-time-in').val();
                    timeData[index]['lap'] = $('#js-lap-number').val();
                });
                var data = {
                    timeData: timeData,
                    bibNumber: bibNumber,
                };

                if ( JSON.stringify(data) == JSON.stringify(liveEntry.lastEffortRequest) ) {
                    return $.Deferred().resolve(); // We already have the information for this data.
                }
                if (typeof currentEventId === 'undefined' || currentEventId === null) {
                    return $.Deferred().resolve(); // No eventId
                }
                return $.get('/api/v1/events/' + currentEventId + '/live_effort_data', data, function (response) {
                    $('#js-live-bib').val('true');
                    $('#js-effort-name').html( response.effortName ).attr('data-effort-id', response.effortId );
                    $('#js-effort-last-reported').html( response.reportText );
                    $('#js-prior-valid-reported').html( response.priorValidReportText );
                    $('#js-time-prior-valid-reported').html( response.timeFromPriorValid );
                    $('#js-time-spent').html( response.timeInAid );
                    if ( !$('#js-lap-number').val() || bibChanged || splitChanged ) {
                        $('#js-lap-number').val( response.expectedLap );
                        $('#js-lap-number:focus').select();
                    }

                    $('#js-time-in')
                        .removeClass('exists null bad good questionable')
                        .addClass(response.timeInExists ? 'exists' : '')
                        .addClass(response.timeInStatus);
                    $('#js-time-out')
                        .removeClass('exists null bad good questionable')
                        .addClass(response.timeOutExists ? 'exists' : '')
                        .addClass(response.timeOutStatus);

                    liveEntry.currentEffortData = response;
                    liveEntry.lastEffortRequest = data;
                });
            },

            /**
             * Retrieves the entire form formatted as a timerow
             * @return {[type]} [description]
             */
            getTimeRow: function () {
                if ($('#js-bib-number').val() == '' &&
                    $('#js-time-in').val() == '' &&
                    $('#js-time-out').val() == '') {
                    return null;
                }

                var thisTimeRow = {};
                thisTimeRow.liveBib = $('#js-live-bib').val();
                thisTimeRow.lap = $('#js-lap-number').val();
                thisTimeRow.splitName = $('#split-select option:selected').html();
                thisTimeRow.effortName = $('#js-effort-name').html();
                thisTimeRow.bibNumber = $('#js-bib-number').val();
                thisTimeRow.eventId = liveEntry.eventIdFromBib(thisTimeRow.bibNumber);
                thisTimeRow.splitId = liveEntry.getSplitId(thisTimeRow.eventId, $('#split-select').val());
                thisTimeRow.timeIn = $('#js-time-in:not(:disabled)').val() || '';
                thisTimeRow.timeOut = $('#js-time-out:not(:disabled)').val() || '';
                thisTimeRow.pacerIn = $('#js-pacer-in:not(:disabled)').prop('checked') || false;
                thisTimeRow.pacerOut = $('#js-pacer-out:not(:disabled)').prop('checked') || false;
                thisTimeRow.droppedHere = $('#js-dropped').prop('checked');
                thisTimeRow.splitDistance = liveEntry.currentEffortData.splitDistance;
                thisTimeRow.timeInStatus = liveEntry.currentEffortData.timeInStatus;
                thisTimeRow.timeOutStatus = liveEntry.currentEffortData.timeOutStatus;
                thisTimeRow.timeInExists = liveEntry.currentEffortData.timeInExists;
                thisTimeRow.timeOutExists = liveEntry.currentEffortData.timeOutExists;
                thisTimeRow.liveTimeIdIn = $('#js-live-time-id-in').val() || '';
                thisTimeRow.liveTimeIdOut = $('#js-live-time-id-out').val() || '';
                return thisTimeRow;
            },

            loadTimeRow: function (timeRow) {
                liveEntry.lastEffortRequest = {};
                liveEntry.currentEffortData = timeRow;
                $('#js-bib-number').val(timeRow.bibNumber).focus();
                $('#js-lap-number').val(timeRow.lap);
                $('#js-time-in').val(timeRow.timeIn);
                $('#js-time-out').val(timeRow.timeOut);
                $('#js-pacer-in').prop('checked', timeRow.pacerIn);
                $('#js-pacer-out').prop('checked', timeRow.pacerOut);
                $('#js-dropped').prop('checked', timeRow.droppedHere).change();
                $('#js-live-time-id-in').val(timeRow.liveTimeIdIn);
                $('#js-live-time-id-out').val(timeRow.liveTimeIdOut);
                liveEntry.splitSlider.changeSplitSlider(timeRow.splitId);
            },

            /**
             * Clears out the splits slider data fields
             * @param  {Boolean} clearForm Determines if the form is cleared as well.
             */
            clearSplitsData: function () {
                $('#js-effort-name').html('n/a').removeAttr('href');
                $('#js-effort-last-reported').html('n/a')
                $('#js-prior-valid-reported').html('n/a')
                $('#js-time-prior-valid-reported').html('n/a');
                $('#js-effort-split-from').html('--:--');
                $('#js-time-spent').html('-- minutes');
                $('#js-time-in').removeClass('exists null bad good questionable');
                $('#js-time-out').removeClass('exists null bad good questionable');
                liveEntry.lastEffortRequest = {};
                $('#js-time-in').val('');
                $('#js-time-out').val('');
                $('#js-live-bib').val('');
                $('#js-bib-number').val('');
                $('#js-lap-number').val('');
                $('#js-pacer-in').prop('checked', false);
                $('#js-pacer-out').prop('checked', false);
                $('#js-dropped').prop('checked', false).change();
                liveEntry.liveEntryForm.fetchEffortData();
            },

            /**
             * Validates the time fields
             *
             * @param string time time format from the input mask
             */
            validateTimeFields: function (time) {
                time = time.replace(/\D/g, '');
                if (time.length == 0) return time;
                if (time.length < 2) return false;
                while (time.length < 6) {
                    time = time.concat('0');
                }
                return time;
            },
            /**
             * Returns the current time in the standard format
             */
            currentTime: function() {
                var now = new Date();
                return ("0" + now.getHours()).slice(-2) + ("0" + now.getMinutes()).slice(-2) + ("0" + now.getSeconds()).slice(-2);
            },
            /**
             * Prefills the time fields with the current time
             */
            prefillCurrentTime: function() {
                if ($('#js-bib-number').val() == '') {
                    $('.rapid-mode #js-time-in').val('');
                    $('.rapid-mode #js-time-out').val('');
                } else if ($('#js-bib-number').val() != liveEntry.liveEntryForm.lastBib) {
                    $('.rapid-mode #js-time-in:not(:disabled)').val(liveEntry.liveEntryForm.currentTime());
                    $('.rapid-mode #js-time-out:not(:disabled)').val(liveEntry.liveEntryForm.currentTime());
                }
            }
        }, // END liveEntryForm form

        /**
         * Contains functionality for times data cache table
         *
         * timeRows need to send back the following fields:
         *      - effortId
         *      - splitId
         *      - timeIn (military)
         *      - timeOut (military)
         *      - PacerIn: (bool)
         *      - PacerOut: (bool)
         */
        timeRowsTable: {

            /**
             * Stores the object from DataTable
             *
             * @type object
             */
            $dataTable: null,
            busy: false,

            /**
             * Inits the provisional data table
             *
             */
            init: function () {

                // Initiate DataTable Plugin
                liveEntry.timeRowsTable.$dataTable = $('#js-provisional-data-table').DataTable({
                    oLanguage: {
                        'sSearch': 'Filter:&nbsp;'
                    }
                });
                liveEntry.timeRowsTable.$dataTable.clear().draw();
                liveEntry.timeRowsTable.populateTableFromCache();
                liveEntry.timeRowsTable.timeRowControls();

                $('[data-toggle="popover"]').popover();
                liveEntry.timeRowsTable.$dataTable.on( 'mouseover', '[data-toggle="tooltip"]', function() {
                    $(this).tooltip('show');
                });

                // Attach add listener
                $('#js-add-to-cache').on('click', function (event) {
                    event.preventDefault();
                    liveEntry.liveEntryForm.prefillCurrentTime();
                    liveEntry.timeRowsTable.addTimeRowFromForm();
                    return false;
                });

                // Wrap search field with clear button
                $('#js-provisional-data-table_filter input')
                    .wrap('<div class="form-group form-group-sm has-feedback"></div>')
                    .on('change keyup', function() {
                        var value = $(this).val() || '';
                        if (value.length > 0) {
                            $('#js-filter-clear').show();
                        } else {
                            $('#js-filter-clear').hide();
                        }
                    });
                $('#js-provisional-data-table_filter .form-group').append(
                    '<span id="js-filter-clear" class="glyphicon glyphicon-remove dataTables_filter-clear form-control-feedback" aria-hidden="true"></span>'
                );
                $('#js-filter-clear').on('click', function() {
                    liveEntry.timeRowsTable.$dataTable.search('').draw();
                    $(this).hide();
                });
            },

            populateTableFromCache: function () {
                var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                $.each(storedTimeRows, function (index) {
                    liveEntry.timeRowsTable.addTimeRowToTable(this, false);
                });
                liveEntry.timeRowsTable.$dataTable.draw();
            },

            addTimeRowFromForm: function () {
                // Retrieve form data
                liveEntry.liveEntryForm.fetchEffortData().always(function() {
                    var thisTimeRow = liveEntry.liveEntryForm.getTimeRow();
                    if (thisTimeRow == null) {
                        return;
                    }
                    thisTimeRow.uniqueId = liveEntry.timeRowsCache.getUniqueId();

                    var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                    if (!liveEntry.timeRowsCache.isMatchedTimeRow(thisTimeRow)) {
                        storedTimeRows.push(thisTimeRow);
                        liveEntry.timeRowsCache.setStoredTimeRows(storedTimeRows);
                        liveEntry.timeRowsTable.addTimeRowToTable(thisTimeRow);
                    }

                    // Clear data and put focus on bibNumber field once we've collected all the data
                    liveEntry.liveEntryForm.clearSplitsData();
                    $('#js-bib-number').focus();
                });
            },

            /**
             * Add a new row to the table (with js dataTables enabled)
             *
             * @param object timeRow Pass in the object of the timeRow to add
             * @param boolean highlight If true, the new row will flash when it is added.
             */
            addTimeRowToTable: function (timeRow, highlight) {
                highlight = (typeof highlight == 'undefined') || highlight;
                liveEntry.timeRowsTable.$dataTable.search('');
                $('#js-filter-clear').hide();
                var icons = {
                    'exists' : '&nbsp;<span class="glyphicon glyphicon-exclamation-sign" data-toggle="tooltip" title="Data Already Exists"></span>',
                    'good' : '&nbsp;<span class="glyphicon glyphicon-ok-sign text-success" data-toggle="tooltip" title="Time Appears Good"></span>',
                    'questionable' : '&nbsp;<span class="glyphicon glyphicon-question-sign text-warning" data-toggle="tooltip" title="Time Appears Questionable"></span>',
                    'bad' : '&nbsp;<span class="glyphicon glyphicon-remove-sign text-danger" data-toggle="tooltip" title="Time Appears Bad"></span>'
                };
                var timeInIcon = icons[timeRow.timeInStatus] || '';
                timeInIcon += ( timeRow.timeInExists && timeRow.timeIn ) ? icons['exists'] : '';
                var timeOutIcon = icons[timeRow.timeOutStatus] || '';
                timeOutIcon += ( timeRow.timeOutExists && timeRow.timeOut ) ? icons['exists'] : '';

                // Base64 encode the stringifyed timeRow to add to the timeRow
                // This is ie9 incompatible
                var base64encodedTimeRow = btoa(JSON.stringify(timeRow));
                var trHtml = '\
                    <tr class="effort-station-row js-effort-station-row" data-unique-id="' + timeRow.uniqueId + '" data-encoded-effort="' + base64encodedTimeRow + '"\
                        data-live-time-id-in="' + timeRow.liveTimeIdIn +'"\
                        data-live-time-id-out="' + timeRow.liveTimeIdOut +'"\
                        data-event-id="'+ timeRow.eventId +'"\>\
                        <td class="split-name js-split-name" data-order="' + timeRow.splitDistance + '">' + timeRow.splitName + '</td>\
                        <td class="bib-number js-bib-number">' + timeRow.bibNumber + '</td>\
                        <td class="lap-number js-lap-number lap-only">' + timeRow.lap + '</td>\
                        <td class="time-in js-time-in text-nowrap ' + timeRow.timeInStatus + '">' + ( timeRow.timeIn || '' ) + timeInIcon + '</td>\
                        <td class="time-out js-time-out text-nowrap ' + timeRow.timeOutStatus + '">' + ( timeRow.timeOut || '' ) + timeOutIcon + '</td>\
                        <td class="pacer-inout js-pacer-inout">' + (timeRow.pacerIn ? 'Yes' : 'No') + ' / ' + (timeRow.pacerOut ? 'Yes' : 'No') + '</td>\
                        <td class="dropped-here js-dropped-here">' + (timeRow.droppedHere ? '<span class="btn btn-warning btn-xs disabled">Dropped Here</span>' : '') + '</td>\
                        <td class="effort-name js-effort-name text-nowrap">' + timeRow.effortName + '</td>\
                        <td class="row-edit-btns">\
                            <button class="effort-row-btn fa fa-pencil edit-effort js-edit-effort btn btn-primary"></button>\
                            <button class="effort-row-btn fa fa-close delete-effort js-delete-effort btn btn-danger"></button>\
                            <button class="effort-row-btn fa fa-check submit-effort js-submit-effort btn btn-success"></button>\
                        </td>\
                    </tr>';
                var node = liveEntry.timeRowsTable.$dataTable.row.add($(trHtml)).draw('full-hold');
                if (highlight) {
                    // Find page that the row was added to
                    var pageInfo = liveEntry.timeRowsTable.$dataTable.page.info();
                    var index = liveEntry.timeRowsTable.$dataTable.rows().indexes().indexOf(node.index());
                    var pageIndex = Math.floor(index / pageInfo.length);
                    liveEntry.timeRowsTable.$dataTable.page(pageIndex).draw('full-hold');
                    $(node.node()).effect('highlight', 2000);
                }
            },

            removeTimeRows: function(timeRows) {
                $.each(timeRows, function(index) {
                    var $row = $(this).closest('tr');
                    var timeRow = JSON.parse(atob($row.attr('data-encoded-effort')));

                    // remove timeRow from cache
                    liveEntry.timeRowsCache.deleteStoredTimeRow(timeRow);

                    // remove table row
                    $row.fadeOut('fast', function () {
                        liveEntry.timeRowsTable.$dataTable.row($row).remove().draw('full-hold');
                    });
                });
            },

            submitTimeRows: function(tableNodes) {
                if ( liveEntry.timeRowsTable.busy ) return;
                liveEntry.timeRowsTable.busy = true;

                let timeRows = [];

                $.each(tableNodes, function() {
                    let $row = $(this).closest('tr');
                    let timeRow = JSON.parse(atob($row.attr('data-encoded-effort')));
                    timeRows.push(timeRow);
                });

                let eventsObj = {};

                for(let row of timeRows){
                    let eventId = row.eventId;
                    if(eventsObj[eventId]) {
                        eventsObj[eventId].push(row);
                    } else {
                        eventsObj[eventId] = [row];
                    }
                }

                for(let eventId in eventsObj) {
                    let data = {timeRows: eventsObj[eventId]};
                    $.post('/api/v1/events/' + eventId + '/set_times_data', data, function (response) {
                        liveEntry.timeRowsTable.removeTimeRows(timeRows);
                        liveEntry.timeRowsTable.$dataTable.rows().nodes().to$().stop(true, true);
                        for (var i = 0; i < response.returnedRows.length; i++) {
                            var timeRow = response.returnedRows[i];
                            timeRow.uniqueId = liveEntry.timeRowsCache.getUniqueId();

                            var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                            if (!liveEntry.timeRowsCache.isMatchedTimeRow(timeRow)) {
                                storedTimeRows.push(timeRow);
                                liveEntry.timeRowsCache.setStoredTimeRows(storedTimeRows);
                                liveEntry.timeRowsTable.addTimeRowToTable(timeRow);
                            }
                        }
                    }).always( function() {
                        liveEntry.timeRowsTable.busy = false;
                    });
                }
            },

            /**
             * Toggles the current state of the discard all button
             * @param  boolean forceClose The button is forced to close without discarding.
             */
            toggleDiscardAll: (function() {
                var $deleteWarning = null;
                var callback = function() {
                    liveEntry.timeRowsTable.toggleDiscardAll(false);
                };
                document.addEventListener("turbolinks:load", function() {
                    $deleteWarning = $('#js-group-delete-all-warning').hide().detach();
                });
                return function (canDelete) {
                    var nodes = liveEntry.timeRowsTable.$dataTable.rows().nodes();
                    var $deleteButton = $('#js-group-delete-all-efforts');
                    $deleteButton.prop('disabled', true);
                    $(document).off('click', callback);
                    $deleteWarning.insertAfter($deleteButton).animate({
                        width: 'toggle',
                        paddingLeft: 'toggle',
                        paddingRight: 'toggle'
                    }, {
                        duration: 350,
                        done: function() {
                            $deleteButton.prop('disabled', false);
                            if ($deleteButton.hasClass('confirm')) {
                                if (canDelete) {
                                    liveEntry.timeRowsTable.removeTimeRows(nodes);
                                    $( '#split-select' ).focus();
                                }
                                $deleteButton.removeClass('confirm');
                                $deleteWarning = $('#js-group-delete-all-warning').hide().detach();
                            } else {
                                $deleteButton.addClass('confirm');
                                $(document).one('click', callback);
                            }
                        }
                    });
                }
            })(),

            /**
             * Move a "cached" table row to "top form" section for editing.
             *
             */
            timeRowControls: function () {

                $(document).on('click', '.js-edit-effort', function (event) {
                    liveEntry.PopulatingFromRow = true;
                    event.preventDefault();
                    liveEntry.timeRowsTable.addTimeRowFromForm();
                    var $row = $(this).closest('tr');
                    var clickedTimeRow = JSON.parse(atob($row.attr('data-encoded-effort')));

                    liveEntry.timeRowsTable.removeTimeRows( $(this) );

                    liveEntry.liveEntryForm.loadTimeRow(clickedTimeRow);
                    liveEntry.PopulatingFromRow = false;
                    liveEntry.liveEntryForm.fetchEffortData();
                });

                $(document).on('click', '.js-delete-effort', function () {
                    liveEntry.timeRowsTable.removeTimeRows( $(this) );
                });

                $(document).on('click', '.js-submit-effort', function () {
                    liveEntry.timeRowsTable.submitTimeRows( [$(this).closest('tr')] );
                });


                $('#js-group-delete-all-efforts').on('click', function (event) {
                    event.preventDefault();
                    liveEntry.timeRowsTable.toggleDiscardAll(true);
                    return false;
                });

                $('#js-submit-all-efforts').on('click', function (event) {
                    event.preventDefault();
                    var nodes = liveEntry.timeRowsTable.$dataTable.rows().nodes();
                    liveEntry.timeRowsTable.submitTimeRows(nodes);
                    return false;
                });

                $('#js-file-upload').fileupload({
                    dataType: 'json',
                    url: '/api/v1/events/' + liveEntry.currentEventGroupId + '/post_file_effort_data',
                    submit: function (e, data) {
                        data.formData = {splitId: liveEntry.currentStationIndex};
                        liveEntry.timeRowsTable.busy = true;
                    },
                    done: function (e, data) {
                        liveEntry.populateRows(data.result);
                    },
                    fail: function (e, data) {
                        $('#debug').empty().append( data.response().jqXHR.responseText );
                    },
                    always: function () {
                        liveEntry.timeRowsTable.busy = false;
                    }
                });
                $('#js-import-live-times').on('click', function (event) {
                    event.preventDefault();
                    if (liveEntry.importAsyncBusy) {
                        return;
                    }
                    liveEntry.importAsyncBusy = true;
                    $.ajax('/api/v1/events/' + liveEntry.currentEventGroupId + '/pull_live_time_rows', {
                       error: function(obj, error) {
                            liveEntry.importAsyncBusy = false;
                            liveEntry.timeRowsTable.importLiveError(obj, error);
                       },
                       dataType: 'json',
                       success: function(data) {
                            if (data.returnedRows.length === 0) {
                                liveEntry.displayAndHideMessage(
                                    liveEntry.importLiveWarning,
                                    '#js-import-live-warning');
                                return;
                            }
                            liveEntry.populateRows(data);
                            liveEntry.importAsyncBusy = false;
                       },
                       type: 'PATCH'
                    });
                    return false;
                });
            },
            importLiveError: function(obj, error) {
                liveEntry.displayAndHideMessage(liveEntry.importLiveError, '#js-import-live-error');
            }
        }, // END timeRowsTable

        displayAndHideMessage: function(msgElement, selector) {
            // Fade in and fade out Bootstrap Alert
            // @param msgElement object jQuery element containing the alert
            // @param selector string jQuery selector to access the alert element
            $('#js-live-messages').append(msgElement);
            msgElement.fadeTo(500, 1);
            window.setTimeout(function() {
            msgElement.fadeTo(500, 0).slideUp(500, function(){
                    msgElement = $(selector).hide().detach();
                    liveEntry.importAsyncBusy = false;
                });
            }, 4000);
            return;
        },
        createTimeFields: function(){

            // Generate time fields
            var entries = liveEntry.splitsAttributes()[liveEntry.currentStationIndex].entries;
            for (var i = 0; i < entries.length; i++) {
                var field = $('.js-time-field-template').clone();
                field.find('.js-time-label').innerText = liveEntry.splitsAttributes()[liveEntry.currentStationIndex].entries[i].label;
                field.removeClass('js-time-field-template');
                $('#js-time-fields').append(field);
            }
            
        },
        splitSlider: {

            /**
             * Init splits slider
             *
             */
            init: function () {
                liveEntry.splitSlider.buildSplitSlider();
                liveEntry.splitSlider.changeSplitSlider(liveEntry.currentStationIndex);
            },

            /**
             * Builds the splits slider based on the splits data
             *
             */
            buildSplitSlider: function () {
                // Inject initial html
                var splitSliderItems = '';
                for (var i = 0; i < liveEntry.splitsAttributes().length; i++) {

                    splitSliderItems += '<div class="split-slider-item js-split-slider-item" data-index="' + i + '" data-split-id="' + i + '" ><span class="split-slider-item-dot"></span><span class="split-slider-item-name">' + liveEntry.splitsAttributes()[i].title + '</span></div>';
                    // <span class="split-slider-item-distance">' + liveEntry.eventLiveEntryData.splits[i].distance_from_start + '</span></div>';
                }
                $('#js-split-slider').html(splitSliderItems);

                // Set default states
                $('.js-split-slider-item').eq(0).addClass('active middle');
                $('.js-split-slider-item').eq(1).addClass('active end');
                $('#js-split-slider').addClass('begin');
                $('#split-select').on('change', function () {
                    var targetId = $( this ).val();
                    liveEntry.currentStationIndex = targetId;
                    liveEntry.splitSlider.changeSplitSlider(targetId);
                    liveEntry.createTimeFields();
                });
            },

            /**
             * Switches the Split Slider to the specified Aid Station
             *
             * @param  integer splitIndex The station id to switch to
             */
            changeSplitSlider: function (splitId) {
                // Update form state
                $('#split-select').val( splitId );
                var $selectOption = $('#split-select option:selected');
                $('#js-time-in').prop('disabled', !$selectOption.data('sub-split-in'));
                $('#js-pacer-in').prop('disabled', !$selectOption.data('sub-split-in'));
                $('#js-time-out').prop('disabled', !$selectOption.data('sub-split-out'));
                $('#js-pacer-out').prop('disabled', !$selectOption.data('sub-split-out'));
                $('#js-file-split').text( $selectOption.text() );
                // Get slider indexes
                var currentItemId = $('.js-split-slider-item.active.middle').attr('data-index');
                var selectedItemId = $('.js-split-slider-item[data-split-id="' + splitId + '"]').attr('data-index');
                if (selectedItemId == currentItemId) {
                    liveEntry.liveEntryForm.fetchEffortData();
                    return;
                }
                if (currentItemId - selectedItemId > 1) {
                    liveEntry.splitSlider.setSplitSlider(selectedItemId - 0 + 1);
                } else if (selectedItemId - currentItemId > 1) {
                    liveEntry.splitSlider.setSplitSlider(selectedItemId - 1);
                }
                setTimeout(function () {
                    $('#js-split-slider').addClass('animate');
                    liveEntry.splitSlider.setSplitSlider(selectedItemId);
                    // liveEntry.currentStationIndex = splitId;
                    liveEntry.liveEntryForm.fetchEffortData();
                    var timeout = $('#js-split-slider').data( 'timeout' );
                    if ( timeout !== null ) {
                        clearTimeout(timeout);
                    }
                    timeout = setTimeout(function () {
                        $('#js-split-slider').removeClass('animate');
                        $('#js-split-slider').data( 'timeout', null );
                    }, 600);
                    $('#js-split-slider').data( 'timeout', timeout );
                }, 1);
            },
            /**
             * Sets the Split Slider to the specified Split index
             *
             * @param  integer splitIndex The split index to switch to
             */
            setSplitSlider: function (splitIndex) {

                // remove all positioning classes
                $('#js-split-slider').removeClass('begin end');
                $('.js-split-slider-item').removeClass('active inactive middle begin end');
                var $selectedSliderItem = $('.js-split-slider-item[data-index="' + splitIndex + '"]');

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
        }, // END splitSlider
        populateRows: function(response) {
            for (var i = 0; i < response.returnedRows.length; i++) {
                var timeRow = response.returnedRows[i];
                timeRow.uniqueId = liveEntry.timeRowsCache.getUniqueId();

                var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                if (!liveEntry.timeRowsCache.isMatchedTimeRow(timeRow)) {
                    storedTimeRows.push(timeRow);
                    liveEntry.timeRowsCache.setStoredTimeRows(storedTimeRows);
                    liveEntry.timeRowsTable.addTimeRowToTable(timeRow);
                }
            }
        } // END populateRows
    }; // END liveEntry

    document.addEventListener("turbolinks:load", function () {
        if (Rails.$('.event_groups.live_entry')[0] === document.body) {
            liveEntry.init();
        }
    });

})(jQuery);

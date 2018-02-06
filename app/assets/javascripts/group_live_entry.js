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
        serverURI: null,
        currentEffortData: {},
        lastEffortRequest: {},
        eventLiveEntryData: null,
        lastReportedSplitId: null,
        lastReportedBitkey: null,
        currentStationIndex: null,

        getEventLiveEntryData: function () {
            return $.get('/api/v1/event_groups/' + liveEntry.currentEventGroupId + '?include=events.efforts&fields[efforts]=bibNumber,eventId')
                .then(function (response) {
                    liveEntry.dataSetup.init(response);
                    liveEntry.timeRowsCache.init();
                    liveEntry.header.init();
                    liveEntry.liveEntryForm.init();
                    liveEntry.timeRowsTable.init();
                    liveEntry.splitSlider.init();
                    liveEntry.pusher.init();
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
            var id = String(eventId);
            return liveEntry.splitsAttributes()[splitIndex].entries[0].eventSplitIds[id]
        },

        bibStatus: function (rowObject) {
            var bibSubmitted = rowObject.bibNumber;
            var bibFound = rowObject.effortId;
            var splitFound = rowObject.splitId;

            if (!bibSubmitted) {
                return null
            } else if (!bibFound) {
                return 'bad'
            } else if (!splitFound) {
                return 'questionable'
            } else {
                return 'good'
            }
        },

        includedResources: function(resourceType) {
            return liveEntry.eventLiveEntryData.included
                .filter(function(current) {
                    return current.type === resourceType;
                })
        },

    /**
         * This kicks off the full UI
         *
         */
        init: function() {
            // Sets the currentEventGroupId once
            var $div = $('#js-event-group-id');
            liveEntry.currentEventGroupId = $div.data('event-group-id');
            liveEntry.serverURI = $div.data('server-uri');
            liveEntry.getEventLiveEntryData();
            liveEntry.importLiveWarning = $('#js-group-import-live-warning').hide().detach();
            liveEntry.importLiveError = $('#js-group-import-live-error').hide().detach();
            liveEntry.newTimesAlert = $('#js-group-new-times-alert').hide();
            liveEntry.PopulatingFromRow = false;
        },

        pusher: {
            init: function() {
                if (!liveEntry.currentEventGroupId) {
                    // Just for safety, abort this init if there is no event data
                    // and avoid breaking execution
                    return;
                }
                // Listen to push notifications

                var liveTimesPusherKey = $('#js-group-live-times-pusher').data('key');
                var pusher = new Pusher(liveTimesPusherKey);
                var channel = pusher.subscribe('live-times-available.event_group.' + liveEntry.currentEventGroupId);

                channel.bind('pusher:subscription_succeeded', function() {
                    // Force the server to trigger a push for initial display
                    liveEntry.triggerLiveTimesPush();
                });

                channel.bind('update', function (data) {
                    // New value pushed from the server
                    // Display updated number of new live times on Pull Times button
                    var new_count = (typeof data.count === 'number') ? data.count : 0;
                    liveEntry.pusher.displayNewCount(new_count);
                });
            },

            displayNewCount: function(count) {
                var text = '';
                if (count > 0) {
                    $('#js-group-new-times-alert').fadeTo(500, 1);
                    text = count;
                } else {
                    $('#js-group-new-times-alert').fadeTo(500, 0, function() {$('#js-group-new-times-alert').hide()});
                }
                $('#js-group-pull-times-count').text(text);
            }
        },

        triggerLiveTimesPush: function() {
            var endpoint = '/api/v1/event_groups/' + liveEntry.currentEventGroupId + '/trigger_live_times_push';
            $.ajax({
                url: endpoint,
                cache: false
            });
        },

        /**
         * Sets up eventLiveEntryData and other convenience data structures
         *
         */
        dataSetup: {
            init: function(response) {
                liveEntry.eventLiveEntryData = response;
                liveEntry.defaultEventId = liveEntry.eventLiveEntryData.data.relationships.events.data[0].id;
                this.buildBibEventMap();
                this.buildEventIdNameMap();
                this.buildSplitIdIndexMap();
                this.buildStationIndexMap();
            },

            buildBibEventMap: function () {
                liveEntry.bibEventMap = {};
                liveEntry.includedResources('efforts').forEach(function(effort) {
                    liveEntry.bibEventMap[effort.attributes.bibNumber] = effort.attributes.eventId;
                });
            },

            buildEventIdNameMap: function () {
                liveEntry.eventIdNameMap = {};
                liveEntry.includedResources('events').forEach(function(event) {
                    liveEntry.eventIdNameMap[event.id] = event.attributes.shortName || event.attributes.name;
                });
            },

            buildSplitIdIndexMap: function () {
                liveEntry.splitIdIndexMap = {};
                liveEntry.splitsAttributes().forEach(function(splitsAttribute, i) {
                    splitsAttribute.entries.forEach(function(entry) {
                        var entrySplitIds = Object.keys(entry.eventSplitIds).map(function(k) {
                            return entry.eventSplitIds[k]
                        });
                        entrySplitIds.forEach(function(splitId) {
                            liveEntry.splitIdIndexMap[splitId] = i;
                        })
                    })
                });
            },

            buildStationIndexMap: function () {
                liveEntry.stationIndexMap = {};
                liveEntry.splitsAttributes().forEach(function(splitsAttribute, i) {
                    var stationData = {};
                    stationData.title = splitsAttribute.title;
                    stationData.labels = splitsAttribute.entries.map(function(entry) { return entry.label });
                    stationData.subSplitIn = splitsAttribute.entries.reduce(function(p, c) { return p || c.subSplitKind === 'in' }, false);
                    stationData.subSplitOut = splitsAttribute.entries.reduce(function(p, c) { return p || c.subSplitKind === 'out' }, false);
                    liveEntry.stationIndexMap[i] = stationData
                })
            }
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
                this.storageId = 'timeRowsCache/' + liveEntry.serverURI + '/eventGroup/' + liveEntry.currentEventGroupId;
                var timeRowsCache = localStorage.getItem(this.storageId);
                if (timeRowsCache === null || timeRowsCache.length == 0) {
                    localStorage.setItem(this.storageId, JSON.stringify([]));
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
                return JSON.parse(localStorage.getItem(this.storageId))
            },

            /**
             * Stringify then Save/Push all timeRows to local object
             *
             * @param object timeRowsObject Pass in the object of the updated object with all added or removed objects.
             * @return null
             */
            setStoredTimeRows: function (timeRowsObject) {
                localStorage.setItem(this.storageId, JSON.stringify(timeRowsObject));
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
                localStorage.setItem(this.storageId, JSON.stringify(storedTimeRows));
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
                liveEntry.header.buildStationSelect();
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
            buildStationSelect: function () {
                var $select = $('#js-group-station-select');
                // Populate select list with eventGroup station attributes
                // Sub_split_in and sub_split_out are boolean fields indicating the existence of in and out time fields respectively.
                var stationItems = '';
                for(var i in liveEntry.stationIndexMap) {
                    var attributes = liveEntry.stationIndexMap[i];
                    stationItems += '<option data-sub-split-in="'+ attributes.subSplitIn +'" data-sub-split-out="'+ attributes.subSplitOut +'" value="' + i + '">';
                    stationItems += attributes.title + '</option>';
                }
                $select.html(stationItems);
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
            lastStationIndex: null,
            init: function () {
                // Apply input masks on time in / out
                var maskOptions = {
                    placeholder: "hh:mm:ss",
                    insertMode: false,
                    showMaskOnHover: false,
                };

                $('#js-group-add-effort-form [data-toggle="tooltip"]').tooltip({container: 'body'});

                $('#js-group-time-in').inputmask("hh:mm:ss", maskOptions);
                $('#js-group-time-out').inputmask("hh:mm:ss", maskOptions);
                $('#js-group-bib-number').inputmask("Regex", {regex: "[0-9|*]{0,6}"});
                $('#js-group-lap-number').inputmask("integer", { min: 1, max: liveEntry.eventLiveEntryData.maximumLaps || undefined });

                // Enable / Disable lap- and group-specific fields
                var multiLap = liveEntry.includedResources('events')
                    .map(function(event) { return event.attributes.multiLap })
                    .reduce(function(p, c) { return p || c }, false);
                multiLap && $('.lap-disabled').removeClass('lap-disabled');

                var multiGroup = liveEntry.eventLiveEntryData.data.relationships.events.data.length > 1;
                multiGroup && $('.group-disabled').removeClass('group-disabled');

                // Styles the Dropped Here button
                $('#js-group-dropped').on('change', function (event) {
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
                $('#js-group-discard-entry-form').on('click', function (event) {
                    event.preventDefault();
                    liveEntry.liveEntryForm.clearSplitsData();
                    $('#js-group-bib-number').focus();
                    return false;
                });

                // Listen for keydown on bibNumber
                $('#js-group-bib-number').on('blur', function (event) {
                    liveEntry.liveEntryForm.fetchEffortData();
                });

                $('#js-group-time-in').on('blur', function (event) {
                    var timeIn = $(this).val();
                    timeIn = liveEntry.liveEntryForm.validateTimeFields(timeIn);
                    if (timeIn === false) {
                        $(this).val('');
                    } else {
                        $(this).val(timeIn);
                        liveEntry.liveEntryForm.fetchEffortData();
                    }
                });

                $('#js-group-time-out').on('blur', function (event) {
                    var timeIn = $(this).val();
                    timeIn = liveEntry.liveEntryForm.validateTimeFields(timeIn);
                    if (timeIn === false) {
                        $(this).val('');
                    } else {
                        $(this).val(timeIn);
                        liveEntry.liveEntryForm.fetchEffortData();
                    }
                });

                $('#js-group-rapid-time-in,#js-group-rapid-time-out').on('click', function (event) {
                    if ( $( this ).siblings( 'input:disabled' ).length ) return;
                    var rapid = $(this).closest('.form-group').toggleClass( 'has-highlight' ).hasClass( 'has-highlight' );
                    $(this).closest('.form-group').toggleClass( 'rapid-mode', rapid );
                });

                // Enable / Disable Rapid Entry Mode
                $('#js-rapid-mode').on('change', function (event) {
                    liveEntry.liveEntryForm.rapidEntry = $(this).prop('checked');
                    $('#js-group-time-in, #js-group-time-out').closest('.form-group').toggleClass('has-success', $(this).prop('checked'));
                }).change();

                // Listen for keydown in pacer-in and pacer-out.
                // Enter checks the box, tab moves to next field.

                $('#js-group-dropped-button').on('click', function (event) {
                    event.preventDefault();
                    $('#js-group-dropped').prop('checked', !$('#js-group-dropped').prop('checked')).change();
                    return false;
                });

                $('#js-group-html-modal').on('show.bs.modal', function(e) {
                    $(this).find('modal-body').html('');
                    var $source = $(e.relatedTarget);
                    var $body = $(this).find('.js-modal-content');
                    if ($source.attr('data-effort-id')) {
                        var eventId = $source.attr('data-event-id');
                        var data = {
                            'effortId': $source.attr('data-effort-id')
                        };
                        $.get('/live/events/' + eventId + '/effort_table', data)
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
                var timeData;
                if (liveEntry.PopulatingFromRow) {
                    // Do nothing.
                    // This fn is being called from several places based on different actions.
                    // None of them are needed if the form is being populated by the system from a
                    // local row's data (i.e., if a user clicks on Edit icon in a Local Data Workspace row).
                    // PopulatingFromRow will be on while the form is populated by that action
                    // and turned off when that's done.
                    return $.Deferred().resolve();
                }
                liveEntry.liveEntryForm.prefillCurrentTime();
                var bibNumber = $('#js-group-bib-number').val();
                var bibChanged = ( bibNumber != liveEntry.liveEntryForm.lastBib );
                var splitChanged = ( liveEntry.currentStationIndex != liveEntry.liveEntryForm.lastStationIndex );
                liveEntry.liveEntryForm.lastBib = bibNumber;
                liveEntry.liveEntryForm.lastStationIndex = liveEntry.currentStationIndex;

                var eventId = liveEntry.eventIdFromBib(bibNumber) || liveEntry.defaultEventId;

                // This is the splitEntry data corresponding to the selected AidStation
                // Looks like: {"title": "Molas Pass (Aid1)",
                //              "entries": [{"eventSplitIds": {"56": 206, "57": 218}, "subSplitKind": "in","label": "Molas Pass (Aid1) In"},
                //                          {"eventSplitIds": {"56": 206, "57": 218}, "subSplitKind": "out", "label": "Molas Pass (Aid1) Out"}]}
                var splitEntries = liveEntry.splitsAttributes()[liveEntry.currentStationIndex].entries;

                // Each subsplit populates one item in the timeData array to be sent to the server
                // timeData: [{splitId: x, time: '12:34', subSplitKind: 'in', lap: 1}, {splitId: x, time: '12:34', subSplitKind: 'out', lap: 1}]
                timeData = splitEntries.map(function(entry) {
                    var newObj = {};
                    newObj.subSplitKind = entry.subSplitKind;
                    newObj.lap = $('#js-group-lap-number').val();
                    // splitId will be null if the eventId is not represented at this entry
                    newObj.splitId = entry.eventSplitIds[eventId];
                    return newObj;
                });
                timeData.forEach(function(el, index) {

                    // Use time IN for the first subsplit and time OUT for the second one, if there is one
                    // This should be updated when Group Live Entry supports variable time fields
                    timeData[index]['time'] = index === 1 ? $('#js-group-time-out').val() : $('#js-group-time-in').val();
                    timeData[index]['lap'] = $('#js-group-lap-number').val();
                });
                var data = {
                    timeData: timeData,
                    bibNumber: bibNumber,
                };

                if ( JSON.stringify(data) == JSON.stringify(liveEntry.lastEffortRequest) ) {
                    return $.Deferred().resolve(); // We already have the information for this data.
                }

                return $.get('/api/v1/events/' + eventId + '/live_effort_data', data, function (response) {
                    $('#js-group-live-bib').val('true');
                    $('#js-group-effort-name').html( response.effortName ).attr('data-effort-id', response.effortId );
                    $('#js-group-effort-name').html( response.effortName ).attr('data-event-id', eventId );
                    $('#js-group-effort-event-name').html( response.effortId ? liveEntry.eventIdNameMap[eventId] : 'n/a' );
                    $('#js-group-effort-last-reported').html( response.reportText );
                    $('#js-group-prior-valid-reported').html( response.priorValidReportText );
                    $('#js-group-time-prior-valid-reported').html( response.timeFromPriorValid );
                    $('#js-group-time-spent').html( response.timeInAid );
                    if ( !$('#js-group-lap-number').val() || bibChanged || splitChanged ) {
                        $('#js-group-lap-number').val( response.expectedLap );
                        $('#js-group-lap-number:focus').select();
                    }

                    $('#js-group-bib-number')
                        .removeClass('null bad questionable good')
                        .addClass(liveEntry.bibStatus(response));
                    $('#js-group-time-in')
                        .removeClass('exists null bad good questionable')
                        .addClass(response.timeInExists ? 'exists' : '')
                        .addClass(response.timeInStatus);
                    $('#js-group-time-out')
                        .removeClass('exists null bad good questionable')
                        .addClass(response.timeOutExists ? 'exists' : '')
                        .addClass(response.timeOutStatus);

                    liveEntry.currentEffortData = response;
                    liveEntry.lastEffortRequest = data;
                })
            },

    /**
             * Retrieves the entire form formatted as a timerow
             * @return {[type]} [description]
             */
            getTimeRow: function () {
                if ($('#js-group-bib-number').val() == '' &&
                    $('#js-group-time-in').val() == '' &&
                    $('#js-group-time-out').val() == '') {
                    return null;
                }

                var thisTimeRow = {};
                thisTimeRow.stationIndex = liveEntry.currentStationIndex;
                thisTimeRow.liveBib = $('#js-group-live-bib').val();
                thisTimeRow.lap = $('#js-group-lap-number').val();
                thisTimeRow.bibNumber = $('#js-group-bib-number').val();
                thisTimeRow.eventId = liveEntry.eventIdFromBib(thisTimeRow.bibNumber);
                thisTimeRow.splitId = liveEntry.getSplitId(thisTimeRow.eventId, liveEntry.currentStationIndex);
                thisTimeRow.effortId = liveEntry.currentEffortData.effortId;
                thisTimeRow.effortName = $('#js-group-effort-name').html();
                thisTimeRow.eventName = $('#js-group-effort-event-name').html();
                thisTimeRow.timeIn = $('#js-group-time-in:not(:disabled)').val() || '';
                thisTimeRow.timeOut = $('#js-group-time-out:not(:disabled)').val() || '';
                thisTimeRow.pacerIn = $('#js-group-pacer-in:not(:disabled)').prop('checked') || false;
                thisTimeRow.pacerOut = $('#js-group-pacer-out:not(:disabled)').prop('checked') || false;
                thisTimeRow.droppedHere = $('#js-group-dropped').prop('checked');
                thisTimeRow.timeInStatus = liveEntry.currentEffortData.timeInStatus;
                thisTimeRow.timeOutStatus = liveEntry.currentEffortData.timeOutStatus;
                thisTimeRow.timeInExists = liveEntry.currentEffortData.timeInExists;
                thisTimeRow.timeOutExists = liveEntry.currentEffortData.timeOutExists;
                thisTimeRow.liveTimeIdIn = $('#js-group-live-time-id-in').val() || '';
                thisTimeRow.liveTimeIdOut = $('#js-group-live-time-id-out').val() || '';
                return thisTimeRow;
            },

            loadTimeRow: function (timeRow) {
                liveEntry.lastEffortRequest = {};
                liveEntry.currentEffortData = timeRow;
                $('#js-group-bib-number').val(timeRow.bibNumber).focus();
                $('#js-group-lap-number').val(timeRow.lap);
                $('#js-group-time-in').val(timeRow.timeIn);
                $('#js-group-time-out').val(timeRow.timeOut);
                $('#js-group-pacer-in').prop('checked', timeRow.pacerIn);
                $('#js-group-pacer-out').prop('checked', timeRow.pacerOut);
                $('#js-group-dropped').prop('checked', timeRow.droppedHere).change();
                $('#js-group-live-time-id-in').val(timeRow.liveTimeIdIn);
                $('#js-group-live-time-id-out').val(timeRow.liveTimeIdOut);
                liveEntry.splitSlider.changeSplitSlider(timeRow.stationIndex);
            },

            /**
             * Clears out the splits slider data fields
             * @param  {Boolean} clearForm Determines if the form is cleared as well.
             */
            clearSplitsData: function () {
                $('#js-group-effort-name').html('n/a').removeAttr('href');
                $('#js-group-effort-event-name').html('n/a');
                $('#js-group-effort-last-reported').html('n/a');
                $('#js-group-prior-valid-reported').html('n/a');
                $('#js-group-time-prior-valid-reported').html('n/a');
                $('#js-effort-split-from').html('--:--');
                $('#js-group-time-spent').html('-- minutes');
                $('#js-group-time-in').removeClass('exists null bad good questionable');
                $('#js-group-time-out').removeClass('exists null bad good questionable');
                liveEntry.lastEffortRequest = {};
                $('#js-group-time-in').val('');
                $('#js-group-time-out').val('');
                $('#js-group-live-bib').val('');
                $('#js-group-bib-number').val('');
                $('#js-group-lap-number').val('');
                $('#js-group-pacer-in').prop('checked', false);
                $('#js-group-pacer-out').prop('checked', false);
                $('#js-group-dropped').prop('checked', false).change();
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
                if ($('#js-group-bib-number').val() == '') {
                    $('.rapid-mode #js-group-time-in').val('');
                    $('.rapid-mode #js-group-time-out').val('');
                } else if ($('#js-group-bib-number').val() != liveEntry.liveEntryForm.lastBib) {
                    $('.rapid-mode #js-group-time-in:not(:disabled)').val(liveEntry.liveEntryForm.currentTime());
                    $('.rapid-mode #js-group-time-out:not(:disabled)').val(liveEntry.liveEntryForm.currentTime());
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
                liveEntry.timeRowsTable.$dataTable = $('#js-group-local-workspace-table').DataTable({
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
                $('#js-group-add-to-cache').on('click', function (event) {
                    event.preventDefault();
                    liveEntry.liveEntryForm.prefillCurrentTime();
                    liveEntry.timeRowsTable.addTimeRowFromForm();
                    return false;
                });

                // Wrap search field with clear button
                $('#js-group-local-workspace-table_filter input')
                    .wrap('<div class="form-group form-group-sm has-feedback"></div>')
                    .on('change keyup', function() {
                        var value = $(this).val() || '';
                        if (value.length > 0) {
                            $('#js-filter-clear').show();
                        } else {
                            $('#js-filter-clear').hide();
                        }
                    });
                $('#js-group-local-workspace-table_filter .form-group').append(
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
                    $('#js-group-bib-number').focus();
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
                var bib_icons = {
                    'good' : '&nbsp;<span class="glyphicon glyphicon-ok-sign text-success" data-toggle="tooltip" title="Bib Found"></span>',
                    'questionable' : '&nbsp;<span class="glyphicon glyphicon-question-sign text-warning" data-toggle="tooltip" title="Bib In Wrong Event"></span>',
                    'bad' : '&nbsp;<span class="glyphicon glyphicon-remove-sign text-danger" data-toggle="tooltip" title="Bib Not Found"></span>'
                };
                var time_icons = {
                    'exists' : '&nbsp;<span class="glyphicon glyphicon-exclamation-sign" data-toggle="tooltip" title="Data Already Exists"></span>',
                    'good' : '&nbsp;<span class="glyphicon glyphicon-ok-sign text-success" data-toggle="tooltip" title="Time Appears Good"></span>',
                    'questionable' : '&nbsp;<span class="glyphicon glyphicon-question-sign text-warning" data-toggle="tooltip" title="Time Appears Questionable"></span>',
                    'bad' : '&nbsp;<span class="glyphicon glyphicon-remove-sign text-danger" data-toggle="tooltip" title="Time Appears Bad"></span>'
                };
                var bibNumberIcon = bib_icons[liveEntry.bibStatus(timeRow)] || '';
                var timeInIcon = time_icons[timeRow.timeInStatus] || '';
                timeInIcon += ( timeRow.timeInExists && timeRow.timeIn ) ? time_icons['exists'] : '';
                var timeOutIcon = time_icons[timeRow.timeOutStatus] || '';
                timeOutIcon += ( timeRow.timeOutExists && timeRow.timeOut ) ? time_icons['exists'] : '';

                // Base64 encode the stringifyed timeRow to add to the timeRow
                var base64encodedTimeRow = btoa(JSON.stringify(timeRow));
                var trHtml = '\
                    <tr class="effort-station-row js-effort-station-row" data-unique-id="' + timeRow.uniqueId + '" data-encoded-effort="' + base64encodedTimeRow + '"\
                        data-live-time-id-in="' + timeRow.liveTimeIdIn +'"\
                        data-live-time-id-out="' + timeRow.liveTimeIdOut +'"\
                        data-event-id="'+ timeRow.eventId +'"\>\
                        <td class="station-title js-station-title" data-order="' + timeRow.stationIndex + '">' + (liveEntry.stationIndexMap[timeRow.stationIndex] || {title: 'Unknown'}).title + '</td>\
                        <td class="lap-number js-group-lap-number group-only">' + liveEntry.eventIdNameMap[timeRow.eventId] + '</td>\
                        <td class="bib-number js-group-bib-number ' + liveEntry.bibStatus(timeRow) + '">' + (timeRow.bibNumber || '') + bibNumberIcon + '</td>\
                        <td class="lap-number js-group-lap-number lap-only">' + timeRow.lap + '</td>\
                        <td class="time-in js-group-time-in text-nowrap ' + timeRow.timeInStatus + '">' + ( timeRow.timeIn || '' ) + timeInIcon + '</td>\
                        <td class="time-out js-group-time-out text-nowrap ' + timeRow.timeOutStatus + '">' + ( timeRow.timeOut || '' ) + timeOutIcon + '</td>\
                        <td class="pacer-inout js-pacer-inout">' + (timeRow.pacerIn ? 'Yes' : 'No') + ' / ' + (timeRow.pacerOut ? 'Yes' : 'No') + '</td>\
                        <td class="dropped-here js-group-dropped-here">' + (timeRow.droppedHere ? '<span class="btn btn-warning btn-xs disabled">Dropped Here</span>' : '') + '</td>\
                        <td class="effort-name js-group-effort-name text-nowrap">' + timeRow.effortName + '</td>\
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

            submitTimeRows: function(tableNodes, forceSubmit) {
                if ( liveEntry.timeRowsTable.busy ) return;
                liveEntry.timeRowsTable.busy = true;

                var timeRows = [];

                $.each(tableNodes, function() {
                    var $row = $(this).closest('tr');
                    var timeRow = JSON.parse(atob($row.attr('data-encoded-effort')));
                    timeRows.push(timeRow);
                });

                var eventsObj = {};

                timeRows.forEach(function(row) {
                    var eventId = row.eventId;
                    if(eventsObj[eventId]) {
                        eventsObj[eventId].push(row);
                    } else {
                        eventsObj[eventId] = [row];
                    }
                });

                for(var eventId in eventsObj) {
                    var data = {timeRows: eventsObj[eventId], forceSubmit: forceSubmit};
                    $.post('/api/v1/events/' + eventId + '/set_times_data', data, function (response) {
                        liveEntry.timeRowsTable.removeTimeRows(tableNodes);
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
                                    $( '#js-group-station-select' ).focus();
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
                    liveEntry.timeRowsTable.submitTimeRows( [$(this).closest('tr')], true );
                });


                $('#js-group-delete-all-efforts').on('click', function (event) {
                    event.preventDefault();
                    liveEntry.timeRowsTable.toggleDiscardAll(true);
                    return false;
                });

                $('#js-group-submit-all-efforts').on('click', function (event) {
                    event.preventDefault();
                    var nodes = liveEntry.timeRowsTable.$dataTable.rows().nodes();
                    liveEntry.timeRowsTable.submitTimeRows(nodes, false);
                    return false;
                });

                $('#js-group-file-upload').fileupload({
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
                $('#js-group-import-live-times').on('click', function (event) {
                    event.preventDefault();
                    if (liveEntry.importAsyncBusy) {
                        return;
                    }
                    liveEntry.importAsyncBusy = true;
                    $.ajax('/api/v1/event_groups/' + liveEntry.currentEventGroupId + '/pull_live_time_rows', {
                       error: function(obj, error) {
                            liveEntry.importAsyncBusy = false;
                            liveEntry.timeRowsTable.importLiveError(obj, error);
                       },
                       dataType: 'json',
                       success: function(data) {
                            if (data.returnedRows.length === 0) {
                                liveEntry.displayAndHideMessage(
                                    liveEntry.importLiveWarning,
                                    '#js-group-import-live-warning');
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
                liveEntry.displayAndHideMessage(liveEntry.importLiveError, '#js-group-import-live-error');
            }
        }, // END timeRowsTable

        displayAndHideMessage: function(msgElement, selector) {
            // Fade in and fade out Bootstrap Alert
            // @param msgElement object jQuery element containing the alert
            // @param selector string jQuery selector to access the alert element
            $('#js-group-live-messages').append(msgElement);
            msgElement.fadeTo(500, 1);
            window.setTimeout(function() {
            msgElement.fadeTo(500, 0).slideUp(500, function(){
                    msgElement = $(selector).hide().detach();
                    liveEntry.importAsyncBusy = false;
                });
            }, 4000);
            return;
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

                    splitSliderItems += '<div class="split-slider-item js-group-station-slider-item" data-index="' + i + '" data-split-id="' + i + '" ><span class="split-slider-item-dot"></span><span class="split-slider-item-name">' + liveEntry.splitsAttributes()[i].title + '</span></div>';
                    // <span class="split-slider-item-distance">' + liveEntry.eventLiveEntryData.splits[i].distance_from_start + '</span></div>';
                }
                $('#js-group-station-slider').html(splitSliderItems);

                // Set default states
                $('.js-group-station-slider-item').eq(0).addClass('active middle');
                $('.js-group-station-slider-item').eq(1).addClass('active end');
                $('#js-group-station-slider').addClass('begin');
                $('#js-group-station-select').on('change', function () {
                    var targetIndex = $( this ).val();
                    liveEntry.splitSlider.changeSplitSlider(targetIndex);
                });
            },

            /**
             * Switches the Split Slider to the specified Aid Station
             *
             * @param  integer stationIndex The station id to switch to
             */
            changeSplitSlider: function (stationIndex) {
                // Update form state
                liveEntry.currentStationIndex = stationIndex;
                $('#js-group-station-select').val(stationIndex);
                var $selectOption = $('#js-group-station-select option:selected');
                $('#js-group-time-in').prop('disabled', !$selectOption.data('sub-split-in'));
                $('#js-group-pacer-in').prop('disabled', !$selectOption.data('sub-split-in'));
                $('#js-group-time-out').prop('disabled', !$selectOption.data('sub-split-out'));
                $('#js-group-pacer-out').prop('disabled', !$selectOption.data('sub-split-out'));
                $('#js-group-file-split').text( $selectOption.text() );
                // Get slider indexes
                var currentItemIndex = $('.js-group-station-slider-item.active.middle').attr('data-index');
                var selectedItemIndex = $('.js-group-station-slider-item[data-split-id="' + stationIndex + '"]').attr('data-index');
                if (selectedItemIndex == currentItemIndex) {
                    liveEntry.liveEntryForm.fetchEffortData();
                    return;
                }
                if (currentItemIndex - selectedItemIndex > 1) {
                    liveEntry.splitSlider.setSplitSlider(selectedItemIndex - 0 + 1);
                } else if (selectedItemIndex - currentItemIndex > 1) {
                    liveEntry.splitSlider.setSplitSlider(selectedItemIndex - 1);
                }
                setTimeout(function () {
                    $('#js-group-station-slider').addClass('animate');
                    liveEntry.splitSlider.setSplitSlider(selectedItemIndex);
                    liveEntry.liveEntryForm.fetchEffortData();
                    var timeout = $('#js-group-station-slider').data( 'timeout' );
                    if ( timeout !== null ) {
                        clearTimeout(timeout);
                    }
                    timeout = setTimeout(function () {
                        $('#js-group-station-slider').removeClass('animate');
                        $('#js-group-station-slider').data( 'timeout', null );
                    }, 600);
                    $('#js-group-station-slider').data( 'timeout', timeout );
                }, 1);
            },
            /**
             * Sets the Split Slider to the specified Split index
             *
             * @param  integer splitIndex The split index to switch to
             */
            setSplitSlider: function (splitIndex) {

                // remove all positioning classes
                $('#js-group-station-slider').removeClass('begin end');
                $('.js-group-station-slider-item').removeClass('active inactive middle begin end');
                var $selectedSliderItem = $('.js-group-station-slider-item[data-index="' + splitIndex + '"]');

                // Add position classes to the current selected slider item
                $selectedSliderItem.addClass('active middle');
                $selectedSliderItem
                    .next('.js-group-station-slider-item').addClass('active end')
                    .next('.js-group-station-slider-item').addClass('inactive end');
                $selectedSliderItem
                    .prev('.js-group-station-slider-item').addClass('active begin')
                    .prev('.js-group-station-slider-item').addClass('inactive begin');
                ;

                // Check if the slider is at the beginning
                if ($selectedSliderItem.prev('.js-group-station-slider-item').length === 0) {

                    // Add appropriate positioning classes
                    $('#js-group-station-slider').addClass('begin');
                }

                // Check if the slider is at the end
                if ($selectedSliderItem.next('.js-group-station-slider-item').length === 0) {
                    $('#js-group-station-slider').addClass('end');
                }
            }
        }, // END splitSlider
        populateRows: function(response) {
            response.returnedRows.forEach(function(timeRow) {
                timeRow.uniqueId = liveEntry.timeRowsCache.getUniqueId();

                // Rows coming in from an imported file or from pull_live_times have no stationIndex
                timeRow.stationIndex = timeRow.stationIndex || liveEntry.splitIdIndexMap[timeRow.splitId];

                var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                if (!liveEntry.timeRowsCache.isMatchedTimeRow(timeRow)) {
                    storedTimeRows.push(timeRow);
                    liveEntry.timeRowsCache.setStoredTimeRows(storedTimeRows);
                    liveEntry.timeRowsTable.addTimeRowToTable(timeRow);
                }
            })
        } // END populateRows
    }; // END liveEntry

    document.addEventListener("turbolinks:load", function () {
        if (Rails.$('.event_groups.live_entry')[0] === document.body) {
            liveEntry.init();
        }
    });

})(jQuery);

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
        eventGroupResponse: null,
        lastReportedSplitId: null,
        lastReportedBitkey: null,
        currentStationIndex: null,
        currentFormResponse: {},
        emptyRawTimeRow: {rawTimes: []},
        lastFormRequest: {},

        getEventLiveEntryData: function () {
            return $.get('/api/v1/event_groups/' + liveEntry.currentEventGroupId + '?include=events.efforts&fields[efforts]=bibNumber,eventId,fullName')
                .then(function (response) {
                    liveEntry.dataSetup.init(response);
                    liveEntry.timeRowsCache.init();
                    liveEntry.header.init();
                    liveEntry.liveEntryForm.init();
                    liveEntry.timeRowsTable.init();
                    liveEntry.pusher.init();
                });
        },

        splitsAttributes: function () {
            return liveEntry.eventGroupAttributes.dataEntryGroups
        },

        // Remove
        getSplitId: function (eventId, splitIndex) {
            var id = String(eventId);
            return liveEntry.splitsAttributes()[splitIndex].entries[0].eventSplitIds[id]
        },

        bibStatus: function (bibNumber, splitName) {
            var bibNotSubmitted = bibNumber.length === 0;
            var bibNotFound = typeof liveEntry.bibEffortMap[bibNumber] === 'undefined';
            var event = liveEntry.events[liveEntry.bibEventIdMap[bibNumber]];
            var splitNames = (event && event.splitNames) || [];
            var splitNotFound = !splitNames.includes(splitName);

            if (bibNotSubmitted) {
                return null
            } else if (bibNotFound) {
                return 'bad'
            } else if (splitNotFound) {
                return 'questionable'
            } else {
                return 'good'
            }
        },

        currentStation: function () {
            return liveEntry.stationIndexMap[liveEntry.currentStationIndex]
        },

        includedResources: function (resourceType) {
            return liveEntry.eventGroupResponse.included
                .filter(function (current) {
                    return current.type === resourceType;
                })
        },

        containsSubSplitKind: function (entries, subSplitKind) {
            return entries.reduce(function (p, c) {
                return p || c.subSplitKind === subSplitKind
            }, false)
        },

        currentRawTime: function (kind) {
            if (typeof liveEntry.currentFormResponse.data === 'undefined') return {};
            return liveEntry.rawTimeFromRow(liveEntry.currentFormResponse.data.rawTimeRow, kind)
        },

        rawTimeFromRow: function (timeRow, kind) {
            var rawTimes = timeRow.rawTimes;
            if (kind === 'in') {
                return rawTimes.find(function (rawTime) {
                    return rawTime.subSplitKind.toLowerCase() === 'in'
                }) || {}
            } else if (kind === 'out') {
                return rawTimes.find(function (rawTime) {
                    return rawTime.subSplitKind.toLowerCase() === 'out'
                }) || {}
            } else {
                return rawTimes[0] || {}
            }
        },

        /**
         * This kicks off the full UI
         *
         */
        init: function () {
            // Sets the currentEventGroupId once
            var $div = $('#js-event-group-id');
            liveEntry.currentEventGroupId = $div.data('event-group-id');
            liveEntry.serverURI = $div.data('server-uri');
            liveEntry.getEventLiveEntryData();
            liveEntry.importLiveWarning = $('#js-import-live-warning').hide().detach();
            liveEntry.importLiveError = $('#js-import-live-error').hide().detach();
            liveEntry.newTimesAlert = $('#js-new-times-alert').hide();
            liveEntry.PopulatingFromRow = false;
        },

        pusher: {
            init: function () {
                if (!liveEntry.currentEventGroupId) {
                    // Just for safety, abort this init if there is no event data
                    // and avoid breaking execution
                    return;
                }
                // Listen to push notifications

                var liveTimesPusherKey = $('#js-live-times-pusher').data('key');
                var pusher = new Pusher(liveTimesPusherKey);
                var channel = pusher.subscribe('raw-times-available.event_group.' + liveEntry.currentEventGroupId);

                channel.bind('pusher:subscription_succeeded', function () {
                    // Force the server to trigger a push for initial display
                    liveEntry.triggerRawTimesPush();
                });

                channel.bind('update', function (data) {
                    // New value pushed from the server
                    // Display updated number of new live times on Pull Times button
                    var unconsideredCount = (typeof data.unconsidered === 'number') ? data.unconsidered : 0;
                    var unmatchedCount = (typeof data.unmatched === 'number') ? data.unmatched : 0;
                    liveEntry.pusher.displayNewCount(unconsideredCount, unmatchedCount);
                });
            },

            displayNewCount: function (unconsideredCount, unmatchedCount) {
                var unconsideredText = (unconsideredCount > 0) ? unconsideredCount : '';
                var unmatchedText = (unmatchedCount > 0) ? unmatchedCount : '';
                $('#js-pull-times-count').text(unconsideredText);
                $('#js-force-pull-times-count').text(unmatchedText);

                if (unconsideredCount > 0) {
                    $('#js-new-times-alert').fadeTo(500, 1);
                } else if ($('#js-new-times-alert').is(":visible")) {
                    $('#js-new-times-alert').fadeTo(500, 0, function () {
                        $('#js-new-times-alert').hide()
                    });
                }
            }
        },

        triggerRawTimesPush: function () {
            var endpoint = '/api/v1/event_groups/' + liveEntry.currentEventGroupId + '/trigger_raw_times_push';
            $.ajax({
                url: endpoint,
                cache: false
            });
        },

        /**
         * Sets up eventGroupResponse and other convenience data structures
         *
         */
        dataSetup: {
            init: function (response) {
                liveEntry.eventGroupResponse = response;
                liveEntry.eventGroupAttributes = liveEntry.eventGroupResponse.data.attributes;
                liveEntry.defaultEventId = liveEntry.eventGroupResponse.data.relationships.events.data[0].id; // Remove
                this.buildBibEventIdMap();
                this.buildEvents();
                this.buildBibEffortMap();
                this.buildStationIndexMap();
                liveEntry.lastFormRequest = liveEntry.emptyRawTimeRow;
            },

            buildBibEventIdMap: function () {
                liveEntry.bibEventIdMap = {};
                liveEntry.includedResources('efforts').forEach(function (effort) {
                    liveEntry.bibEventIdMap[effort.attributes.bibNumber] = effort.attributes.eventId;
                });
            },

            buildEvents: function () {
                liveEntry.events = {};
                liveEntry.includedResources('events').forEach(function (event) {
                    liveEntry.events[event.id] = {
                        name: event.attributes.shortName || event.attributes.name,
                        splitNames: event.attributes.splitNames
                    }
                });
            },

            buildBibEffortMap: function () {
                liveEntry.bibEffortMap = {};
                liveEntry.includedResources('efforts').forEach(function (effort) {
                    liveEntry.bibEffortMap[effort.attributes.bibNumber] = effort;
                });
            },

            buildStationIndexMap: function () {
                liveEntry.stationIndexMap = {};
                liveEntry.indexStationMap = {};
                liveEntry.subSplitKinds = [];
                liveEntry.splitsAttributes().forEach(function (splitsAttribute, i) {
                    var stationData = {};
                    stationData.subSplitKinds = [];
                    stationData.title = splitsAttribute.title;
                    stationData.splitName = splitsAttribute.entries[0].splitName;
                    stationData.labelIn = splitsAttribute.entries[0] && splitsAttribute.entries[0].label || '';
                    stationData.labelOut = splitsAttribute.entries[1] && splitsAttribute.entries[1].label || '';
                    stationData.subSplitIn = liveEntry.containsSubSplitKind(splitsAttribute.entries, 'in');
                    stationData.subSplitOut = liveEntry.containsSubSplitKind(splitsAttribute.entries, 'out');
                    if (stationData.subSplitIn) {
                        stationData.subSplitKinds.push('in');
                        if (!liveEntry.subSplitKinds.includes('in')) liveEntry.subSplitKinds.push('in')
                    }
                    if (stationData.subSplitOut) {
                        stationData.subSplitKinds.push('out');
                        if (!liveEntry.subSplitKinds.includes('out')) liveEntry.subSplitKinds.push('out')
                    }
                    liveEntry.stationIndexMap[i] = stationData;
                    liveEntry.indexStationMap[stationData.splitName] = i
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
                this.storageId = 'OST/rawTimeRowsCache/' + liveEntry.serverURI + '/eventGroup/' + liveEntry.currentEventGroupId;
                var timeRowsCache = localStorage.getItem(this.storageId);
                if (timeRowsCache === null || timeRowsCache.length === 0) {
                    localStorage.setItem(this.storageId, JSON.stringify([]));
                }
            },

            /**
             * Check table stored timeRows for highest unique ID, then return a new one.
             * @return number Unique Time Row Id
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
                    if (this.uniqueId === timeRow.uniqueId) {
                        storedTimeRows.splice(index, 1);
                        return false;
                    }
                });
                localStorage.setItem(this.storageId, JSON.stringify(storedTimeRows));
                return null;
            },

            /**
             * Update or insert the rawTimeRow, as appropriate
             *
             * @param rawTimeRow    Pass in the rawTimeRow we want to upsert.
             * @return null
             */
            upsertTimeRow: function (rawTimeRow) {
                var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                var newRow = true;

                $.each(storedTimeRows, function (index) {
                    if (this.uniqueId === rawTimeRow.uniqueId) {
                        storedTimeRows[index] = rawTimeRow;
                        liveEntry.timeRowsTable.updateTimeRowInTable(rawTimeRow);
                        newRow = false;
                        return false
                    }
                });

                if (newRow) {
                    if (!liveEntry.timeRowsCache.isMatchedTimeRow(rawTimeRow)) {
                        storedTimeRows.push(rawTimeRow);
                        liveEntry.timeRowsTable.addTimeRowToTable(rawTimeRow);
                    }
                }

                liveEntry.timeRowsCache.setStoredTimeRows(storedTimeRows);
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

                return flag !== false;
            },
        },
        /**
         * Functionality to build header lives here
         *
         */
        header: {
            init: function () {
                liveEntry.header.updateEventGroupName();
                liveEntry.header.buildStationSelect();
            },

            /**
             * Populate the h2 with the eventGroup name
             *
             */
            updateEventGroupName: function () {
                $('.page-title h2').text(liveEntry.eventGroupAttributes.name);
            },

            /**
             * Add the Splits data to the select drop down table on the page
             *
             */
            buildStationSelect: function () {
                var $select = $('#js-station-select');
                var stationItems = '';
                for (var i in liveEntry.stationIndexMap) {
                    stationItems += '<option value="' + i + '">' + liveEntry.stationIndexMap[i].title + '</option>';
                }
                $select.html(stationItems);
                // Synchronize Select with currentStationIndex
                $select.children().first().prop('selected', true);
                liveEntry.currentStationIndex = $select.val();
                this.changeStationSelect(liveEntry.currentStationIndex);

                $select.on('change', function () {
                    var targetIndex = $(this).val();
                    liveEntry.header.changeStationSelect(targetIndex);
                });
            },

            /**
             * Switches the current station to the specified Aid Station
             *
             * @param stationIndex (integer) The station index to switch to
             */
            changeStationSelect: function (stationIndex) {
                $('#js-station-select').val(stationIndex);

                var station = liveEntry.stationIndexMap[stationIndex];
                $('#js-time-in-label').html(station.labelIn);
                $('#js-time-out-label').html(station.labelOut);
                $('#js-time-in').prop('disabled', !station.subSplitIn);
                $('#js-pacer-in').prop('disabled', !station.subSplitIn);
                $('#js-time-out').prop('disabled', !station.subSplitOut);
                $('#js-pacer-out').prop('disabled', !station.subSplitOut);
                $('#js-file-split').text(station.title);

                if (liveEntry.currentStationIndex !== stationIndex) {
                    liveEntry.currentStationIndex = stationIndex;
                    liveEntry.liveEntryForm.updateEffortInfo();
                    liveEntry.liveEntryForm.enrichTimeData();
                }
            }
        },

        /**
         * Contains functionality for the timeRow form
         *
         */
        liveEntryForm: {
            lastEnrichTimeBib: null,
            lastEffortInfoBib: null,
            lastStationIndex: null,
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
                $('#js-lap-number').inputmask("integer", {
                    min: 1,
                    max: liveEntry.eventGroupAttributes.maximumLaps || undefined
                });

                // Enable / Disable conditional fields
                var multiLap = liveEntry.eventGroupAttributes.multiLap;
                var multiGroup = liveEntry.eventGroupResponse.data.relationships.events.data.length > 1;
                var pacers = liveEntry.eventGroupAttributes.monitorPacers;
                var anySubSplitIn = liveEntry.subSplitKinds.includes('in');
                var anySubSplitOut = liveEntry.subSplitKinds.includes('out');

                if (multiLap) $('.lap-disabled').removeClass('lap-disabled');
                if (multiGroup) $('.group-disabled').removeClass('group-disabled');
                if (pacers) $('.pacer-disabled').removeClass('pacer-disabled');
                if (anySubSplitIn) $('.time-in-disabled').removeClass('time-in-disabled');
                if (anySubSplitOut) $('.time-out-disabled').removeClass('time-out-disabled');

                // Styles the Dropped Here button
                $('#js-dropped').on('change', function (event) {
                    var $root = $(this).parent();
                    if ($(this).prop('checked')) {
                        $root.addClass('btn-warning').removeClass('btn-default');
                        $('.glyphicon', $root).addClass('glyphicon-check').removeClass('glyphicon-unchecked');
                    } else {
                        $root.addClass('btn-default').removeClass('btn-warning');
                        $('.glyphicon', $root).addClass('glyphicon-unchecked').removeClass('glyphicon-check');
                    }
                });

                // Clears the live entry form when the clear button is clicked
                $('#js-discard-entry-form').on('click', function (event) {
                    event.preventDefault();
                    liveEntry.liveEntryForm.clear();
                    $('#js-bib-number').focus();
                    return false;
                });

                $('#js-bib-number').on('blur', function () {
                    liveEntry.liveEntryForm.updateEffortInfo();
                    liveEntry.liveEntryForm.enrichTimeData();
                });

                $('#js-lap-number').on('blur', function () {
                    liveEntry.liveEntryForm.enrichTimeData();
                });

                $('#js-time-in').on('blur', function () {
                    var timeIn = $(this).val();
                    timeIn = liveEntry.liveEntryForm.validateTimeFields(timeIn);
                    if (timeIn === false) {
                        $(this).val('');
                    } else {
                        $(this).val(timeIn);
                    }
                    liveEntry.liveEntryForm.enrichTimeData();
                });

                $('#js-time-out').on('blur', function () {
                    var timeIn = $(this).val();
                    timeIn = liveEntry.liveEntryForm.validateTimeFields(timeIn);
                    if (timeIn === false) {
                        $(this).val('');
                    } else {
                        $(this).val(timeIn);
                    }
                    liveEntry.liveEntryForm.enrichTimeData();
                });

                $('#js-rapid-time-in,#js-rapid-time-out').on('click', function () {
                    if ($(this).siblings('input:disabled').length) return;
                    var rapid = $(this).closest('.form-group').toggleClass('has-highlight').hasClass('has-highlight');
                    $(this).closest('.form-group').toggleClass('rapid-mode', rapid);
                });

                // Enable / Disable Rapid Entry Mode
                $('#js-rapid-mode').on('change', function () {
                    liveEntry.liveEntryForm.rapidEntry = $(this).prop('checked');
                    $('#js-time-in, #js-time-out').closest('.form-group').toggleClass('has-success', $(this).prop('checked'));
                }).change();

                var $droppedHereButton = $('#js-dropped-button');
                $droppedHereButton.on('click', function (event) {
                    event.preventDefault();
                    $('#js-dropped').prop('checked', !$('#js-dropped').prop('checked')).change();
                    return false;
                });
                $droppedHereButton.keypress(function (event) {
                    if (event.which === 13) {
                        event.preventDefault();
                        $('#js-add-to-cache').click()
                    }
                    return false;
                });

                $('#js-html-modal').on('show.bs.modal', function (e) {
                    $(this).find('modal-body').html('');
                    var $source = $(e.relatedTarget);
                    var $body = $(this).find('.js-modal-content');
                    if ($source.attr('data-effort-id')) {
                        var eventId = $source.attr('data-event-id');
                        var data = {
                            'effortId': $source.attr('data-effort-id')
                        };
                        $.get('/live/events/' + eventId + '/effort_table', data)
                            .done(function (a, b, c) {
                                $body.html(a);
                            });
                    } else {
                        e.preventDefault();
                    }
                });
            },

            /**
             * Updates local effort data from memory and, if bib has changed, makes a request to the server.
             */

            updateEffortInfo: function () {
                var fullName = '';
                var effortId = '';
                var eventId = '';
                var eventName = '';
                var url = '#';
                var splitName = liveEntry.currentStation().splitName;
                var bibNumber = $('#js-bib-number').val();
                var bibChanged = (bibNumber !== liveEntry.liveEntryForm.lastEffortInfoBib);
                var effort = liveEntry.bibEffortMap[bibNumber];

                if (bibNumber.length > 0) {
                    if (effort !== null && typeof effort === 'object') {
                        fullName = effort.attributes.fullName;
                        effortId = effort.id;
                        eventId = effort.attributes.eventId;
                        eventName = liveEntry.events[eventId].name;
                        // url = effort.links.self;
                    } else {
                        fullName = '[Bib not found]';
                        eventName = '--'
                    }
                }

                $('#js-effort-name').html(fullName).attr('data-effort-id', effortId).attr('data-event-id', eventId);
                // $('#js-effort-name').attr("href", url);
                $('#js-effort-event-name').html(eventName);
                var bibStatus = liveEntry.bibStatus(bibNumber, splitName);
                $('#js-bib-number')
                    .removeClass('null bad questionable good')
                    .addClass(bibStatus)
                    .attr('data-bib-status', bibStatus);

                if (bibChanged) {
                    if (effort !== null && typeof effort === 'object') {
                        return $.get('/api/v1/efforts/' + effort.id + '/with_times_row', function (response) {
                            liveEntry.liveEntryForm.lastEffortInfoBib = bibNumber;
                            $('#js-effort-table').html(response.data.id)
                            // Use response to update effort detail
                        })
                    } else {
                        liveEntry.liveEntryForm.lastEffortInfoBib = null;
                        $('#js-effort-table').html('[Blurred dummy data here]')
                        // Clear effort detail
                    }
                }
            },

            /**
             * Adds dataStatus and splitTimeExists to rawTimes in the form.
             */
            enrichTimeData: function () {
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
                var bibNumber = $('#js-bib-number').val();
                var bibChanged = (bibNumber !== liveEntry.liveEntryForm.lastEnrichTimeBib);
                var splitChanged = (liveEntry.currentStationIndex !== liveEntry.liveEntryForm.lastStationIndex);
                liveEntry.liveEntryForm.lastEnrichTimeBib = bibNumber;
                liveEntry.liveEntryForm.lastStationIndex = liveEntry.currentStationIndex;

                var currentFormComp = liveEntry.rawTimeRow.compData(liveEntry.liveEntryForm.getTimeRow());
                var lastRequestComp = liveEntry.rawTimeRow.compData(liveEntry.lastFormRequest);

                if (JSON.stringify(currentFormComp) === JSON.stringify(lastRequestComp)) {
                    return $.Deferred().resolve(); // We already have the information for this data.
                }

                // Clear out dataStatus and splitTimeExists from the last request
                liveEntry.liveEntryForm.updateTimeField($('#js-time-in'), {dataStatus: null, splitTimeExists: null});
                liveEntry.liveEntryForm.updateTimeField($('#js-time-out'), {dataStatus: null, splitTimeExists: null});

                var requestData = {
                    data: {
                        rawTimeRow: liveEntry.liveEntryForm.getTimeRow()
                    }
                };

                return $.get('/api/v1/event_groups/' + liveEntry.currentEventGroupId + '/enrich_raw_time_row', requestData, function (response) {
                    liveEntry.currentFormResponse = response;
                    liveEntry.lastFormRequest = requestData.data.rawTimeRow;

                    var rawTime = liveEntry.currentRawTime();
                    var inRawTime = liveEntry.currentRawTime('in');
                    var outRawTime = liveEntry.currentRawTime('out');

                    if (!$('#js-lap-number').val() || bibChanged || splitChanged) {
                        $('#js-lap-number').val(rawTime.lap);
                        $('#js-lap-number:focus').select();
                    }

                    liveEntry.liveEntryForm.updateTimeField($('#js-time-in'), inRawTime);
                    liveEntry.liveEntryForm.updateTimeField($('#js-time-out'), outRawTime);
                })
            },

            /**
             * Retrieves the entire form formatted as a rawTimeRow
             * @return object a single rawTimeRow
             */
            getTimeRow: function () {
                var subSplitKinds = liveEntry.currentStation().subSplitKinds;
                var uniqueId = parseInt($('#js-unique-id').val());
                if (isNaN(uniqueId)) uniqueId = null;

                return {
                    uniqueId: uniqueId,
                    rawTimes: subSplitKinds.map(function (kind) {
                            var $timeField = $('#js-time-' + kind);
                            return {
                                id: $('#js-raw-time-id-' + kind).val() || '',
                                eventGroupId: liveEntry.currentEventGroupId,
                                bibNumber: $('#js-bib-number').val(),
                                enteredTime: $timeField.val(),
                                lap: $('#js-lap-number').val(),
                                splitName: liveEntry.currentStation().title,
                                subSplitKind: kind,
                                stoppedHere: $('#js-dropped').prop('checked'),
                                withPacer: $('#js-pacer-' + kind).prop('checked'),
                                dataStatus: $timeField.attr('data-time-status'),
                                splitTimeExists: ($timeField.attr('data-split-time-exists') === 'true')
                            }
                        }
                    )
                }
            },

            loadTimeRow: function (rawTimeRow) {
                liveEntry.lastFormRequest = liveEntry.emptyRawTimeRow;
                liveEntry.currentFormResponse = rawTimeRow;

                var rawTime = liveEntry.rawTimeFromRow(rawTimeRow);
                var inRawTime = liveEntry.rawTimeFromRow(rawTimeRow, 'in');
                var outRawTime = liveEntry.rawTimeFromRow(rawTimeRow, 'out');
                var stationIndex = liveEntry.indexStationMap[rawTime.splitName];
                var $inTimeField = $('#js-time-in');
                var $outTimeField = $('#js-time-out');

                $('#js-unique-id').val(rawTimeRow.uniqueId);
                $('#js-raw-time-id-in').val(inRawTime.id);
                $('#js-raw-time-id-out').val(outRawTime.id);
                $('#js-bib-number').val(rawTime.bibNumber).focus();
                $('#js-lap-number').val(rawTime.lap);
                $inTimeField.val(inRawTime.enteredTime);
                $outTimeField.val(outRawTime.enteredTime);
                $('#js-pacer-in').prop('checked', inRawTime.withPacer);
                $('#js-pacer-out').prop('checked', outRawTime.withPacer);
                $('#js-dropped').prop('checked', inRawTime.stoppedHere || outRawTime.stoppedHere).change();
                liveEntry.liveEntryForm.updateTimeField($inTimeField, inRawTime);
                liveEntry.liveEntryForm.updateTimeField($outTimeField, outRawTime);
                liveEntry.header.changeStationSelect(stationIndex);
            },

            /**
             * Clears out the entry form and effort detail data fields
             * @param  {Boolean} clearForm Determines if the form is cleared as well.
             */
            clear: function () {
                liveEntry.lastFormRequest = liveEntry.emptyRawTimeRow;
                var $uniqueId = $('#js-unique-id');
                if ($uniqueId.val() !== '') {
                    var $row = $('#workspace-' + $uniqueId.val());
                    $row.removeClass('highlight');
                    $uniqueId.val('');
                }
                $('#js-raw-time-id-in').val('');
                $('#js-raw-time-id-out').val('');
                $('#js-effort-name').html('').removeAttr('href');
                $('#js-effort-event-name').html('');
                $('#js-time-in').removeClass('exists null bad good questionable');
                $('#js-time-out').removeClass('exists null bad good questionable');
                $('#js-time-in').val('');
                $('#js-time-out').val('');
                $('#js-bib-number').val('');
                $('#js-lap-number').val('');
                $('#js-pacer-in').prop('checked', false);
                $('#js-pacer-out').prop('checked', false);
                $('#js-dropped').prop('checked', false).change();
                liveEntry.liveEntryForm.updateEffortInfo();
                liveEntry.liveEntryForm.enrichTimeData();
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
            currentTime: function () {
                var now = new Date();
                return ("0" + now.getHours()).slice(-2) + ("0" + now.getMinutes()).slice(-2) + ("0" + now.getSeconds()).slice(-2);
            },
            /**
             * Prefills the time fields with the current time
             */
            prefillCurrentTime: function () {
                if ($('#js-bib-number').val() === '') {
                    $('.rapid-mode #js-time-in').val('');
                    $('.rapid-mode #js-time-out').val('');
                } else if ($('#js-bib-number').val() !== liveEntry.liveEntryForm.lastEnrichTimeBib) {
                    $('.rapid-mode #js-time-in:not(:disabled)').val(liveEntry.liveEntryForm.currentTime());
                    $('.rapid-mode #js-time-out:not(:disabled)').val(liveEntry.liveEntryForm.currentTime());
                }
            },

            updateTimeField: function ($field, rawTime) {
                $field.removeClass('exists null bad good questionable')
                    .addClass(rawTime.splitTimeExists ? 'exists' : '')
                    .addClass(rawTime.dataStatus)
                    .attr('data-time-status', rawTime.dataStatus)
                    .attr('data-split-time-exists', rawTime.splitTimeExists)
            }
        }, // END liveEntryForm form

        /**
         * Contains functionality for times data cache table
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
                liveEntry.timeRowsTable.$dataTable = $('#js-local-workspace-table').DataTable({
                    pageLength: 50,
                    oLanguage: {
                        'sSearch': 'Filter:&nbsp;'
                    }
                });
                liveEntry.timeRowsTable.$dataTable.clear().draw();
                liveEntry.timeRowsTable.populateTableFromCache();
                liveEntry.timeRowsTable.timeRowControls();

                $('[data-toggle="popover"]').popover();
                liveEntry.timeRowsTable.$dataTable.on('mouseover', '[data-toggle="tooltip"]', function () {
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
                $('#js-local-workspace-table_filter input')
                    .wrap('<div class="form-group form-group-sm has-feedback"></div>')
                    .on('change keyup', function () {
                        var value = $(this).val() || '';
                        if (value.length > 0) {
                            $('#js-filter-clear').show();
                        } else {
                            $('#js-filter-clear').hide();
                        }
                    });
                $('#js-local-workspace-table_filter .form-group').append(
                    '<span id="js-filter-clear" class="glyphicon glyphicon-remove dataTables_filter-clear form-control-feedback" aria-hidden="true"></span>'
                );
                $('#js-filter-clear').on('click', function () {
                    liveEntry.timeRowsTable.$dataTable.search('').draw();
                    $(this).hide();
                });
            },

            populateTableFromCache: function () {
                var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                $.each(storedTimeRows, function () {
                    liveEntry.timeRowsTable.addTimeRowToTable(this, false);
                });
                liveEntry.timeRowsTable.$dataTable.draw();
            },

            addTimeRowFromForm: function () {
                // Retrieve form data
                liveEntry.liveEntryForm.enrichTimeData().always(function () {
                    var rawTimeRow = liveEntry.liveEntryForm.getTimeRow();

                    if (rawTimeRow === liveEntry.emptyRawTimeRow) return;
                    if (rawTimeRow.uniqueId === null) rawTimeRow.uniqueId = liveEntry.timeRowsCache.getUniqueId();

                    liveEntry.timeRowsCache.upsertTimeRow(rawTimeRow);

                    // Clear data and put focus on bibNumber field once we've collected all the data
                    liveEntry.liveEntryForm.clear();
                    $('#js-bib-number').focus();
                });
            },

            /**
             * Add a new row to the table (with js dataTables enabled)
             *
             * @param object timeRow Pass in the object of the timeRow to add
             * @param boolean highlight If true, the new row will flash when it is added.
             */
            addTimeRowToTable: function (rawTimeRow, highlight) {
                highlight = (typeof highlight == 'undefined') || highlight;
                liveEntry.timeRowsTable.$dataTable.search('');
                $('#js-filter-clear').hide();

                var trHtml = liveEntry.timeRowsTable.buildTrHtml(rawTimeRow);

                var node = liveEntry.timeRowsTable.$dataTable.row.add($(trHtml)).draw('full-hold');
                if (highlight) {
                    // Find page that the row was added to
                    var pageInfo = liveEntry.timeRowsTable.$dataTable.page.info();
                    var index = liveEntry.timeRowsTable.$dataTable.rows().indexes().indexOf(node.index());
                    var pageIndex = Math.floor(index / pageInfo.length);
                    liveEntry.timeRowsTable.$dataTable.page(pageIndex).draw('full-hold');
                    $(node.node()).effect('highlight', 1000);
                }
            },

            updateTimeRowInTable: function (rawTimeRow) {
                liveEntry.timeRowsTable.$dataTable.search('');
                $('#js-filter-clear').hide();

                var trHtml = liveEntry.timeRowsTable.buildTrHtml(rawTimeRow);
                var rowData = liveEntry.timeRowsTable.trToData(trHtml);
                var $row = $('#workspace-' + rawTimeRow.uniqueId);
                $row.removeClass('highlight');
                liveEntry.timeRowsTable.$dataTable.row($row).data(rowData).draw
                $row.attr('data-encoded-raw-time-row', btoa(JSON.stringify(rawTimeRow)))
            },

            removeTimeRows: function (timeRows) {
                $.each(timeRows, function () {
                    var $row = $(this).closest('tr');
                    var timeRow = JSON.parse(atob($row.attr('data-encoded-raw-time-row')));

                    // remove timeRow from cache
                    liveEntry.timeRowsCache.deleteStoredTimeRow(timeRow);

                    // remove table row
                    $row.fadeOut('fast', function () {
                        liveEntry.timeRowsTable.$dataTable.row($row).remove().draw('full-hold');
                    });
                });
            },

            submitTimeRows: function (tableNodes, forceSubmit) {
                if (liveEntry.timeRowsTable.busy) return;
                liveEntry.timeRowsTable.busy = true;

                var timeRows = [];

                $.each(tableNodes, function () {
                    var $row = $(this).closest('tr');
                    var timeRow = JSON.parse(atob($row.attr('data-encoded-raw-time-row')));
                    timeRows.push({rawTimeRow: timeRow});
                });

                var data = {data: timeRows, forceSubmit: forceSubmit};
                $.post('/api/v1/event_groups/' + liveEntry.currentEventGroupId + '/submit_raw_time_rows', data, function (response) {
                    liveEntry.timeRowsTable.removeTimeRows(tableNodes);
                    liveEntry.timeRowsTable.$dataTable.rows().nodes().to$().stop(true, true);
                    var returnedRows = response.data.rawTimeRows;
                    for (var i = 0; i < returnedRows.length; i++) {
                        var timeRow = returnedRows[i];
                        timeRow.uniqueId = liveEntry.timeRowsCache.getUniqueId();

                        var storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
                        if (!liveEntry.timeRowsCache.isMatchedTimeRow(timeRow)) {
                            storedTimeRows.push(timeRow);
                            liveEntry.timeRowsCache.setStoredTimeRows(storedTimeRows);
                            liveEntry.timeRowsTable.addTimeRowToTable(timeRow);
                        }
                    }
                }).always(function () {
                    liveEntry.timeRowsTable.busy = false;
                });
            },

            buildTrHtml: function (rawTimeRow) {
                var bibIcons = {
                    'good': '&nbsp;<span class="glyphicon glyphicon-ok-sign text-success" data-toggle="tooltip" title="Bib Found"></span>',
                    'questionable': '&nbsp;<span class="glyphicon glyphicon-question-sign text-warning" data-toggle="tooltip" title="Bib In Wrong Event"></span>',
                    'bad': '&nbsp;<span class="glyphicon glyphicon-remove-sign text-danger" data-toggle="tooltip" title="Bib Not Found"></span>'
                };
                var timeIcons = {
                    'exists': '&nbsp;<span class="glyphicon glyphicon-exclamation-sign" data-toggle="tooltip" title="Data Already Exists"></span>',
                    'good': '&nbsp;<span class="glyphicon glyphicon-ok-sign text-success" data-toggle="tooltip" title="Time Appears Good"></span>',
                    'questionable': '&nbsp;<span class="glyphicon glyphicon-question-sign text-warning" data-toggle="tooltip" title="Time Appears Questionable"></span>',
                    'bad': '&nbsp;<span class="glyphicon glyphicon-remove-sign text-danger" data-toggle="tooltip" title="Time Appears Bad"></span>'
                };
                var inRawTime = liveEntry.rawTimeFromRow(rawTimeRow, 'in');
                var outRawTime = liveEntry.rawTimeFromRow(rawTimeRow, 'out');
                var rawTime = liveEntry.rawTimeFromRow(rawTimeRow);

                var bibStatus = liveEntry.bibStatus(rawTime.bibNumber, rawTime.splitName);
                var bibIcon = bibIcons[bibStatus];
                var timeInIcon = timeIcons[inRawTime.dataStatus] || '';
                timeInIcon += (inRawTime.splitTimeExists ? timeIcons['exists'] : '');
                var timeOutIcon = timeIcons[outRawTime.dataStatus] || '';
                timeOutIcon += (outRawTime.splitTimeExists ? timeIcons['exists'] : '');

                // Base64 encode the stringified timeRow to add to the timeRow
                var base64encodedTimeRow = btoa(JSON.stringify(rawTimeRow));
                var event = liveEntry.events[liveEntry.bibEventIdMap[rawTime.bibNumber]] || {name: '--'};
                var effort = liveEntry.bibEffortMap[rawTime.bibNumber];
                var trHtml = '\
                    <tr id="workspace-' + rawTimeRow.uniqueId + '" class="effort-station-row js-effort-station-row" data-encoded-raw-time-row="' + base64encodedTimeRow + '">\
                        <td class="station-title js-station-title" data-order="' + rawTime.splitName + '">' + rawTime.splitName + '</td>\
                        <td class="event-name js-event-name group-only">' + event.name + '</td>\
                        <td class="bib-number js-bib-number ' + bibStatus + '">' + (rawTime.bibNumber || '') + bibIcon + '</td>\
                        <td class="effort-name js-effort-name text-nowrap">' + (effort ? '<a href="/efforts/' + effort.id + '">' + effort.attributes.fullName + '</a>' : '[Bib not found]') + '</td>\
                        <td class="lap-number js-lap-number lap-only">' + rawTime.lap + '</td>\
                        <td class="time-in js-time-in text-nowrap time-in-only ' + inRawTime.dataStatus + '">' + (inRawTime.enteredTime || '') + timeInIcon + '</td>\
                        <td class="time-out js-time-out text-nowrap time-out-only ' + outRawTime.dataStatus + '">' + (outRawTime.enteredTime || '') + timeOutIcon + '</td>\
                        <td class="pacer-inout js-pacer-inout pacer-only">' + (inRawTime.withPacer ? 'Yes' : 'No') + ' / ' + (outRawTime.withPacer ? 'Yes' : 'No') + '</td>\
                        <td class="dropped-here js-dropped-here">' + (inRawTime.stoppedHere || outRawTime.stoppedHere ? '<span class="btn btn-warning btn-xs disabled">Done</span>' : '') + '</td>\
                        <td class="row-edit-btns">\
                            <button class="effort-row-btn fa fa-pencil edit-effort js-edit-effort btn btn-primary"></button>\
                            <button class="effort-row-btn fa fa-close delete-effort js-delete-effort btn btn-danger"></button>\
                            <button class="effort-row-btn fa fa-check submit-effort js-submit-effort btn btn-success"></button>\
                        </td>\
                    </tr>';
                return trHtml
            },

            trToData: function (row) {
                var rowData = {};
                $(row).find('td').each(function (i, el) {
                    if (i === 0) {
                        rowData[i] = {
                            display: el.innerHTML,
                            '@data-order': el.innerHTML
                        }
                    } else {
                        rowData[i] = el.innerHTML
                    }
                });
                return rowData
            },

            /**
             * Toggles the current state of the discard all button
             * @param  boolean forceClose The button is forced to close without discarding.
             */
            toggleDiscardAll: (function () {
                var $deleteWarning = null;
                var callback = function () {
                    liveEntry.timeRowsTable.toggleDiscardAll(false);
                };
                document.addEventListener("turbolinks:load", function () {
                    $deleteWarning = $('#js-delete-all-warning').hide().detach();
                });
                return function (canDelete) {
                    var nodes = liveEntry.timeRowsTable.$dataTable.rows().nodes();
                    var $deleteButton = $('#js-delete-all-time-rows');
                    $deleteButton.prop('disabled', true);
                    $(document).off('click', callback);
                    $deleteWarning.insertAfter($deleteButton).animate({
                        width: 'toggle',
                        paddingLeft: 'toggle',
                        paddingRight: 'toggle'
                    }, {
                        duration: 350,
                        done: function () {
                            $deleteButton.prop('disabled', false);
                            if ($deleteButton.hasClass('confirm')) {
                                if (canDelete) {
                                    liveEntry.timeRowsTable.removeTimeRows(nodes);
                                    $('#js-station-select').focus();
                                }
                                $deleteButton.removeClass('confirm');
                                $deleteWarning = $('#js-delete-all-warning').hide().detach();
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
                    var $row = $(this).closest('tr');
                    var clickedTimeRow = JSON.parse(atob($row.attr('data-encoded-raw-time-row')));

                    $row.addClass('highlight');
                    liveEntry.liveEntryForm.loadTimeRow(clickedTimeRow);
                    liveEntry.PopulatingFromRow = false;
                    liveEntry.liveEntryForm.enrichTimeData();
                });

                $(document).on('click', '.js-delete-effort', function () {
                    liveEntry.timeRowsTable.removeTimeRows($(this));
                });

                $(document).on('click', '.js-submit-effort', function () {
                    liveEntry.timeRowsTable.submitTimeRows([$(this).closest('tr')], true);
                });


                $('#js-delete-all-time-rows').on('click', function (event) {
                    event.preventDefault();
                    liveEntry.timeRowsTable.toggleDiscardAll(true);
                    return false;
                });

                $('#js-submit-all-time-rows').on('click', function (event) {
                    event.preventDefault();
                    var nodes = liveEntry.timeRowsTable.$dataTable.rows().nodes();
                    liveEntry.timeRowsTable.submitTimeRows(nodes, false);
                    return false;
                });

                $('#js-file-upload').fileupload({
                    dataType: 'json',
                    url: '/api/v1/events/' + liveEntry.defaultEventId + '/post_file_effort_data',
                    submit: function (e, data) {
                        data.formData = {splitId: liveEntry.getSplitId(liveEntry.defaultEventId, liveEntry.currentStationIndex)};
                        liveEntry.timeRowsTable.busy = true;
                    },
                    done: function (e, data) {
                        liveEntry.populateRows(data.result);
                    },
                    fail: function (e, data) {
                        $('#debug').empty().append(data.response().jqXHR.responseText);
                    },
                    always: function () {
                        liveEntry.timeRowsTable.busy = false;
                    }
                });

                $(document).on('keydown', function (event) {
                    if (event.keyCode === 16) {
                        $('#js-pull-times').hide();
                        $('#js-force-pull-times').show()
                    }
                });
                $(document).on('keyup', function (event) {
                    if (event.keyCode === 16) {
                        $('#js-force-pull-times').hide();
                        $('#js-pull-times').show()
                    }
                });
                $('#js-pull-times, #js-force-pull-times').on('click', function (event) {
                    event.preventDefault();
                    if (liveEntry.importAsyncBusy) {
                        return;
                    }
                    liveEntry.importAsyncBusy = true;
                    var forceParam = (this.id === 'js-force-pull-times') ? '?forcePull=true' : '';
                    $.ajax('/api/v1/event_groups/' + liveEntry.currentEventGroupId + '/pull_raw_times' + forceParam, {
                        error: function (obj, error) {
                            liveEntry.importAsyncBusy = false;
                            liveEntry.timeRowsTable.importLiveError(obj, error);
                        },
                        dataType: 'json',
                        success: function (response) {
                            var rawTimeRows = response.data.rawTimeRows;
                            if (rawTimeRows.length === 0) {
                                liveEntry.displayAndHideMessage(
                                    liveEntry.importLiveWarning,
                                    '#js-import-live-warning');
                                return;
                            }
                            liveEntry.populateRows(rawTimeRows);
                            liveEntry.importAsyncBusy = false;
                        },
                        type: 'PATCH'
                    });
                    return false;
                });
            },
            importLiveError: function (obj, error) {
                liveEntry.displayAndHideMessage(liveEntry.importLiveError, '#js-import-live-error');
            }
        }, // END timeRowsTable

        rawTimeRow: {
            compData: function (row) {
                return {
                    rawTimes: row['rawTimes'].map(function (rawTime) {
                        return {
                            bibNumber: rawTime.bibNumber,
                            enteredTime: rawTime.enteredTime,
                            lap: rawTime.lap,
                            splitName: rawTime.splitName,
                            subSplitKind: rawTime.subSplitKind,
                            stoppedHere: rawTime.stoppedHere
                        }
                    })
                }
            }
        }, // END rawTimeRow

        displayAndHideMessage: function (msgElement, selector) {
            // Fade in and fade out Bootstrap Alert
            // @param msgElement object jQuery element containing the alert
            // @param selector string jQuery selector to access the alert element
            $('#js-live-messages').append(msgElement);
            msgElement.fadeTo(500, 1);
            window.setTimeout(function () {
                msgElement.fadeTo(500, 0).slideUp(500, function () {
                    msgElement = $(selector).hide().detach();
                    liveEntry.importAsyncBusy = false;
                });
            }, 4000);
            return;
        },

        populateRows: function (rawTimeRows) {
            rawTimeRows.forEach(function (timeRow) {
                timeRow.uniqueId = liveEntry.timeRowsCache.getUniqueId();

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

})
(jQuery);

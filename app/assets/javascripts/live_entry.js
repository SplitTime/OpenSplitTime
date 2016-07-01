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

        currentEffortData: {},

        lastEffortRequest: {},

        eventLiveEntryData: null,

        lastReportedSplitId: null,

        lastReportedBitkey: null,

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
            liveEntry.currentEventId = $('#js-event-id').data('event-id');
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
                $('.page-title h2').text(liveEntry.eventLiveEntryData.eventName.concat(': Live Data Entry'));
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
                for (var i = 1; i < liveEntry.eventLiveEntryData.splits.length; i++) {
                    splitItems += '<option value="' + liveEntry.eventLiveEntryData.splits[i].id + '" data-index="' + i + '" data-sub-split-in="' + liveEntry.eventLiveEntryData.splits[i].sub_split_in + '" data-sub-split-out="' + liveEntry.eventLiveEntryData.splits[i].sub_split_out + '" >' + liveEntry.eventLiveEntryData.splits[i].base_name + '</option>';
                }
                $select.html(splitItems);
                // Syncronize Select with splitId
                $select.children().first().prop('selected', true);
                liveEntry.currentSplitId = $select.val();
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

                $('#js-add-effort-form [data-toggle="tooltip"]').tooltip({container: 'body'});

                $('#js-time-in').inputmask("hh:mm:ss", maskOptions);
                $('#js-time-out').inputmask("hh:mm:ss", maskOptions);
                $('#js-bib-number').inputmask("9999999999999999999", {placeholder: ""});

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
                    var $body = $(this).find('.modal-body');
                    if ($source.attr('data-effort-id')) {
                        var data = {
                            'effortId': $source.attr('data-effort-id')
                        }
                        $.get('/live/events/' + liveEntry.currentEventId + '/get_effort_table', data)
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

                var bibNumber = $('#js-bib-number').val();

                var data = {
                    splitId: liveEntry.currentSplitId,
                    bibNumber: bibNumber,
                    timeIn: $('#js-time-in').val(),
                    timeOut: $('#js-time-out').val()
                };

                if ( JSON.stringify(data) == JSON.stringify(liveEntry.lastEffortRequest) ) {
                    return $.Deferred().resolve(); // We already have the information for this data.
                }

                return $.get('/live/events/' + liveEntry.currentEventId + '/get_live_effort_data', data, function (response) {
                    $('#js-live-bib').val('true');
                    $('#js-effort-name').html( response.name ).attr('data-effort-id', response.effortId );
                    $('#js-effort-last-reported').html( response.reportText );
                    $('#js-prior-valid-reported').html( response.priorValidReportText );
                    $('#js-time-prior-valid-reported').html( response.timeFromPriorValid );
                    $('#js-time-spent').html( response.timeInAid );

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

                // Build up the timeRow
                var thisTimeRow = {};
                thisTimeRow.liveBib = $('#js-live-bib').val();
                thisTimeRow.eventId = liveEntry.currentEventId;
                thisTimeRow.splitId = $('#split-select').val();
                thisTimeRow.splitName = $('#split-select option:selected').html();
                thisTimeRow.effortName = $('#js-effort-name').html();
                thisTimeRow.bibNumber = $('#js-bib-number').val();
                thisTimeRow.timeIn = $('#js-time-in').val();
                thisTimeRow.timeOut = $('#js-time-out').val();
                thisTimeRow.pacerIn = $('#js-pacer-in').prop('checked');
                thisTimeRow.pacerOut = $('#js-pacer-out').prop('checked');
                thisTimeRow.droppedHere = $('#js-dropped').prop('checked');
                thisTimeRow.splitDistance = liveEntry.currentEffortData.splitDistance;
                thisTimeRow.timeInStatus = liveEntry.currentEffortData.timeInStatus;
                thisTimeRow.timeOutStatus = liveEntry.currentEffortData.timeOutStatus;
                thisTimeRow.timeInExists = liveEntry.currentEffortData.timeInExists;
                thisTimeRow.timeOutExists = liveEntry.currentEffortData.timeOutExists;
                return thisTimeRow;
            },

            loadTimeRow: function (timeRow) {
                liveEntry.lastEffortRequest = {};
                liveEntry.currentEffortData = timeRow;
                $('#js-bib-number').val(timeRow.bibNumber).focus();
                $('#js-time-in').val(timeRow.timeIn);
                $('#js-time-out').val(timeRow.timeOut);
                $('#js-pacer-in').prop('checked', timeRow.pacerIn);
                $('#js-pacer-out').prop('checked', timeRow.pacerOut);
                $('#js-dropped').prop('checked', timeRow.droppedHere).change();
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
                $('#js-pacer-in').prop('checked', false);
                $('#js-pacer-out').prop('checked', false);
                $('#js-dropped').prop('checked', false).change();
                liveEntry.liveEntryForm.fetchEffortData();
            },

            /**
             * Valiates the time fields
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
                timeInIcon += timeRow.timeInExists ? icons['exists'] : '';
                var timeOutIcon = icons[timeRow.timeOutStatus] || '';
                timeOutIcon += timeRow.timeOutExists ? icons['exists'] : '';

                // Base64 encode the stringifyed timeRow to add to the timeRow
                // This is ie9 incompatible
                var base64encodedTimeRow = btoa(JSON.stringify(timeRow));
                var trHtml = '\
                    <tr class="effort-station-row js-effort-station-row" data-unique-id="' + timeRow.uniqueId + '" data-encoded-effort="' + base64encodedTimeRow + '" >\
                        <td class="split-name js-split-name" data-order="' + timeRow.splitDistance + '">' + timeRow.splitName + '</td>\
                        <td class="bib-number js-bib-number">' + timeRow.bibNumber + '</td>\
                        <td class="time-in js-time-in text-nowrap ' + timeRow.timeInStatus + '">' + timeRow.timeIn + timeInIcon + '</td>\
                        <td class="time-out js-time-out text-nowrap ' + timeRow.timeOutStatus + '">' + timeRow.timeOut + timeOutIcon + '</td>\
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

            submitTimeRows: function(timeRows) {
                var data = {timeRows:[]}
                $.each(timeRows, function(index) {
                    var $row = $(this).closest('tr');
                    var timeRow = JSON.parse(atob($row.attr('data-encoded-effort')));
                    data.timeRows.push(timeRow);
                });
                $.post('/live/events/' + liveEntry.currentEventId + '/set_times_data', data, function (response) {
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
                });
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
                $(document).ready( function() {
                    $deleteWarning = $('#js-delete-all-warning').hide().detach();
                });
                return function (canDelete) {
                    var nodes = liveEntry.timeRowsTable.$dataTable.rows().nodes();
                    var $deleteButton = $('#js-delete-all-efforts');
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
                    event.preventDefault();
                    liveEntry.timeRowsTable.addTimeRowFromForm();
                    var $row = $(this).closest('tr');
                    var clickedTimeRow = JSON.parse(atob($row.attr('data-encoded-effort')));

                    liveEntry.timeRowsTable.removeTimeRows( $(this) );

                    liveEntry.liveEntryForm.loadTimeRow(clickedTimeRow);
                });

                $(document).on('click', '.js-delete-effort', function () {
                    liveEntry.timeRowsTable.removeTimeRows( $(this) );
                });

                $(document).on('click', '.js-submit-effort', function () {
                    liveEntry.timeRowsTable.submitTimeRows( $(this) );
                });

                
                $('#js-delete-all-efforts').on('click', function (event) {
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
                    url: '/live/events/' + liveEntry.currentEventId + '/post_file_effort_data',
                    submit: function (e, data) {
                        data.formData = {splitId: liveEntry.currentSplitId};
                    },
                    done: function (e, data) {
                        var response = data.result;
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
                    },
                    fail: function (e, data) {
                        $('#debug').empty().append( data.response().jqXHR.responseText );
                    }
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
                liveEntry.splitSlider.changeSplitSlider(liveEntry.currentSplitId);
            },

            /**
             * Builds the splits slider based on the splits data
             *
             */
            buildSplitSlider: function () {

                // Inject initial html
                var splitSliderItems = '';
                for (var i = 0; i < liveEntry.eventLiveEntryData.splits.length; i++) {
                    splitSliderItems += '<div class="split-slider-item js-split-slider-item" data-index="' + i + '" data-split-id="' + liveEntry.eventLiveEntryData.splits[i].id + '" ><span class="split-slider-item-dot"></span><span class="split-slider-item-name">' + liveEntry.eventLiveEntryData.splits[i].base_name + '</span><span class="split-slider-item-distance">' + liveEntry.eventLiveEntryData.splits[i].distance_from_start + '</span></div>';
                }
                $('#js-split-slider').html(splitSliderItems);

                // Set default states
                $('.js-split-slider-item').eq(0).addClass('active middle');
                $('.js-split-slider-item').eq(1).addClass('active end');
                $('#js-split-slider').addClass('begin');
                $('#split-select').on('change', function () {
                    var targetId = $( this ).val();
                    liveEntry.splitSlider.changeSplitSlider(targetId);
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
                $('#js-time-out').prop('disabled', !$selectOption.data('sub-split-out'));
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
                    liveEntry.currentSplitId = splitId;
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
        } // END splitSlider
    }; // END liveEntry

    $('.events.live_entry').ready(function () {
        liveEntry.init();
    });
})(jQuery);
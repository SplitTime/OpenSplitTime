import { Controller } from "@hotwired/stimulus"
import { get, post } from "@rails/request.js"

export default class extends Controller {

  static values = {
    currentUserId: Number,
    eventGroupId: Number,
    serverUri: String,
  }

  connect() {
    this.liveEntryApp(this)
  }

  liveEntryApp(controller) {

    const statusIcons = {
      'exists': '&nbsp;<span class="fas fa-exclamation-circle" data-controller="tooltip" title="Data Already Exists"></span>',
      'good': '&nbsp;<span class="fas fa-check-circle text-success" data-controller="tooltip" title="Time Appears Good"></span>',
      'questionable': '&nbsp;<span class="fas fa-question-circle text-warning" data-controller="tooltip" title="Time Appears Questionable"></span>',
      'bad': '&nbsp;<span class="fas fa-times-circle text-danger" data-controller="tooltip" title="Time Appears Bad"></span>'
    };

    let liveEntry = {

      eventGroupResponse: null,
      // lastReportedSplitId: null,
      // lastReportedBitkey: null,
      currentStationIndex: null,
      currentFormResponse: {},
      emptyRawTimeRow: {rawTimes: []},
      lastFormRequest: {},
      currentUser: controller.currentUserIdValue,

      init: function (controller) {
        liveEntry.currentEventGroupId = controller.eventGroupIdValue;
        liveEntry.serverURI = controller.serverUriValue;
        liveEntry.getEventGroupData().then((json) => {
          liveEntry.dataSetup.init(json).then((response) => {
            if (response) {
              liveEntry.timeRowsCache.init();
              liveEntry.header.init();
              liveEntry.liveEntryForm.init();
              liveEntry.timeRowsTable.init();
            }
          }).catch((error) => {
            console.error(error)
          })
        }).catch((error) => {
          console.error(error)
        })
      },

      getEventGroupData: async function () {
        const url = `/api/v1/event_groups/${liveEntry.currentEventGroupId}?include=events.efforts&fields[efforts]=bibNumber,eventId,fullName`
        const options = {
          responseKind: "json"
        }

        const response = await get(url, options)
        if (response.ok) {
          return await response.json
        } else {
          console.error("Could not load event group data:", response)
        }
      },

      bibStatus: function (bibNumber, splitName) {
        const bibNotSubmitted = bibNumber.length === 0;
        const bibNotFound = typeof liveEntry.bibEffortMap[bibNumber] === 'undefined';
        const event = liveEntry.events[liveEntry.bibEventIdMap[bibNumber]];
        const splitNames = (event && event.splitNames) || [];
        const splitNotFound = !splitNames.includes(splitName);

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

      containsSubSplitKind: function (entries, subSplitKind) {
        return entries.reduce(function (p, c) {
          return p || c.subSplitKind === subSplitKind
        }, false)
      },

      currentRawTime: function (kind) {
        if (!liveEntry.currentFormResponse.data) return {};
        return liveEntry.rawTimeFromRow(liveEntry.currentFormResponse.data.rawTimeRow, kind)
      },

      currentStation: function () {
        return liveEntry.stationIndexMap[liveEntry.currentStationIndex]
      },

      includedResources: function (resourceType) {
        return liveEntry.eventGroupResponse.included
          .filter(function (resource) {
            return resource.type === resourceType;
          })
      },

      rawTimeFromRow: function (timeRow, kind) {
        const rawTimes = timeRow.rawTimes;
        if (kind === 'in') {
          return rawTimes.find(rawTime => {
            return rawTime.subSplitKind.toLowerCase() === 'in'
          }) || {}
        } else if (kind === 'out') {
          return rawTimes.find(rawTime => {
            return rawTime.subSplitKind.toLowerCase() === 'out'
          }) || {}
        } else {
          return rawTimes[0] || {}
        }
      },

      splitsAttributes: function () {
        return liveEntry.eventGroupAttributes.unpairedDataEntryGroups
      },

      /**
       * Sets up eventGroupResponse and other convenience data structures
       *
       */
      dataSetup: {

        init: async function (eventGroupResponse) {
          liveEntry.eventGroupResponse = eventGroupResponse
          liveEntry.eventGroupAttributes = liveEntry.eventGroupResponse.data.attributes
          liveEntry.dataSetup.buildBibEventIdMap();
          liveEntry.dataSetup.buildEvents();
          liveEntry.dataSetup.buildBibEffortMap();
          liveEntry.dataSetup.buildStationIndexMap();
          liveEntry.lastFormRequest = liveEntry.emptyRawTimeRow;
          return true
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
            const stationData = {};
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

      }, // end dataSetup

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
          this.storageId = `OST/rawTimeRowsCache/${liveEntry.serverURI}/eventGroup/${liveEntry.currentEventGroupId}`;
          const timeRowsCache = localStorage.getItem(this.storageId);
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
          const storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
          let highestUniqueId = 0;
          storedTimeRows.forEach(timeRow => {
            if (timeRow.uniqueId > highestUniqueId) {
              highestUniqueId = timeRow.uniqueId
            }
          });
          return highestUniqueId + 1;
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
         * @param object    subjectTimeRow    Pass in the object/timeRow we want to delete.
         * @return null
         */
        deleteStoredTimeRow: function (subjectTimeRow) {
          const storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
          storedTimeRows.forEach(function (timeRow, index) {
            if (timeRow.uniqueId === subjectTimeRow.uniqueId) {
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
         * @param subjectTimeRow    Pass in the rawTimeRow we want to upsert.
         * @return null
         */
        upsertTimeRow: function (subjectTimeRow) {
          const storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
          let newRow = true;

          storedTimeRows.forEach(function (storedTimeRow, index) {
            if (storedTimeRow.uniqueId === subjectTimeRow.uniqueId) {
              storedTimeRows[index] = subjectTimeRow;
              liveEntry.timeRowsTable.updateTimeRowInTable(subjectTimeRow);
              newRow = false;
              return false
            }
          });

          if (newRow) {
            if (!liveEntry.timeRowsCache.isMatchedTimeRow(subjectTimeRow)) {
              storedTimeRows.push(subjectTimeRow);
              liveEntry.timeRowsTable.addTimeRowToTable(subjectTimeRow);
            }
          }

          liveEntry.timeRowsCache.setStoredTimeRows(storedTimeRows);
        },

        /**
         * Compare timeRow to all timeRows in local storage. Add if it doesn't already exist, or throw an error message.
         *
         * @param  object subjectTimeRow Pass in Object of the timeRow to check it against the stored objects         *
         * @return boolean    True if match found, False if no match found
         */
        isMatchedTimeRow: function (subjectTimeRow) {
          const storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
          const tempTimeRow = JSON.stringify(subjectTimeRow);
          let flag = false;

          storedTimeRows.forEach(storedTimeRow => {
            const loopedTimeRow = JSON.stringify(storedTimeRow);
            if (loopedTimeRow === tempTimeRow) {
              flag = true
            }
          });

          return flag
        },

      }, // end timeRowsCache

      /**
       * Functionality to build header lives here
       *
       */
      header: {
        init: function () {
          liveEntry.header.buildStationSelect();
        },

        /**
         * Add the Splits data to the select drop down table on the page
         *
         */
        buildStationSelect: function () {
          const select = document.getElementById('js-station-select');

          Object.entries(liveEntry.stationIndexMap).forEach(entry => {
            const [index, station] = entry;
            const newOption = new Option(station.title, index);
            select.add(newOption, undefined)
          })

          // Synchronize Select with currentStationIndex
          select.selectedIndex = 0
          liveEntry.currentStationIndex = select.value
          this.changeStationSelect(liveEntry.currentStationIndex);

          select.addEventListener('change', function () {
            const targetIndex = this.value
            liveEntry.header.changeStationSelect(targetIndex);
          });
        },

        /**
         * Switches the current station to the specified Aid Station
         *
         * @param stationIndex (integer) The station index to switch to
         */
        changeStationSelect: function (stationIndex) {
          const select = document.getElementById('js-station-select')
          select.value = stationIndex
          const station = liveEntry.stationIndexMap[stationIndex];
          document.getElementById('js-time-in-label').innerHTML = station.labelIn
          document.getElementById('js-time-out-label').innerHTML = station.labelOut
          document.getElementById('js-time-in').disabled = !station.subSplitIn
          document.getElementById('js-pacer-in').disabled = !station.subSplitIn
          document.getElementById('js-time-out').disabled = !station.subSplitOut
          document.getElementById('js-pacer-out').disabled = !station.subSplitOut

          if (liveEntry.currentStationIndex !== stationIndex) {
            liveEntry.currentStationIndex = stationIndex;
            liveEntry.liveEntryForm.updateEffortInfo();
            liveEntry.liveEntryForm.enrichTimeData();
            liveEntry.liveEntryForm.highlightEffortTableRow();
          }
        }

      },  // end header

      /**
       * Contains functionality for the timeRow form
       *
       */
      liveEntryForm: {

        lastEnrichTimeBib: null,
        lastEffortInfoBib: null,
        lastStationIndex: null,

        init: function () {

          // Enable / Disable conditional fields
          const multiLap = liveEntry.eventGroupAttributes.multiLap;
          const multiGroup = liveEntry.eventGroupResponse.data.relationships.events.data.length > 1;
          const pacers = liveEntry.eventGroupAttributes.monitorPacers;
          const anySubSplitIn = liveEntry.subSplitKinds.includes('in');
          const anySubSplitOut = liveEntry.subSplitKinds.includes('out');

          if (multiLap) document.querySelectorAll('.lap-disabled').forEach(el => el.classList.remove('lap-disabled'));
          if (multiGroup) document.querySelectorAll('.group-disabled').forEach(el => el.classList.remove('group-disabled'));
          if (pacers) document.querySelectorAll('.pacer-disabled').forEach(el => el.classList.remove('pacer-disabled'));
          if (anySubSplitIn) document.querySelectorAll('.time-in-disabled').forEach(el => el.classList.remove('time-in-disabled'));
          if (anySubSplitOut) document.querySelectorAll('.time-out-disabled').forEach(el => el.classList.remove('time-out-disabled'));

          liveEntry.liveEntryForm.clear()

          // Clears the live entry form when the clear button is clicked
          document.getElementById('js-discard-entry-form').addEventListener('click', function (event) {
            event.preventDefault();
            liveEntry.liveEntryForm.clear();
            document.getElementById('js-bib-number').focus();
            return false;
          });

          document.getElementById('js-bib-number').addEventListener('blur', function () {
            liveEntry.liveEntryForm.stripBibLeadingZeros();
            liveEntry.liveEntryForm.updateEffortInfo();
            liveEntry.liveEntryForm.enrichTimeData();
          });

          document.getElementById('js-lap-number').addEventListener('blur', function () {
            liveEntry.liveEntryForm.enrichTimeData();
            liveEntry.liveEntryForm.highlightEffortTableRow();
          });

          document.getElementById('js-time-in').addEventListener('blur', function () {
            liveEntry.liveEntryForm.enrichTimeData();
          });

          document.getElementById('js-time-out').addEventListener('blur', function () {
            liveEntry.liveEntryForm.enrichTimeData();
          });

          controller.element.addEventListener('live-entry--effort-table:loaded', function () {
            liveEntry.liveEntryForm.highlightEffortTableRow();
          });

          const droppedHereButton = document.getElementById('js-dropped-button');
          droppedHereButton.addEventListener('click', function (event) {
            event.preventDefault();

            // Toggle the checkbox
            const input = document.getElementById('js-dropped');
            input.checked = !input.checked;
            liveEntry.liveEntryForm.setDroppedButtonStyling();
            return false;
          });

          droppedHereButton.addEventListener('keydown', function (event) {
            if (event.key === 'Enter') {
              event.preventDefault();
              document.getElementById('js-add-to-cache').click()
            }
            return false;
          });
        }, // end init

        setDroppedButtonStyling: function () {
          const button = document.getElementById('js-dropped-button');
          const input = document.getElementById('js-dropped');
          const icon = button.querySelector('.far');

          if (input.checked) {
            button.classList.remove('btn-outline-secondary')
            button.classList.add('btn-warning');
            icon.classList.remove('fa-square')
            icon.classList.add('fa-check-square');
          } else {
            button.classList.add('btn-outline-secondary')
            button.classList.remove('btn-warning');
            icon.classList.add('fa-square')
            icon.classList.remove('fa-check-square');
          }
        },

        /**
         * Updates local effort data from memory and, if bib has changed, makes a request to the server.
         */
        updateEffortInfo: function () {
          let fullName = '';
          let effortId = '';
          let eventId = '';
          let eventName = '';
          let url = '#';
          const splitName = liveEntry.currentStation().splitName;
          const bibNumber = document.getElementById('js-bib-number').value;
          const bibChanged = (bibNumber !== liveEntry.liveEntryForm.lastEffortInfoBib);
          const effort = liveEntry.bibEffortMap[bibNumber];

          if (bibNumber) {
            if (effort) {
              fullName = effort.attributes.fullName;
              effortId = effort.id;
              eventId = effort.attributes.eventId;
              eventName = liveEntry.events[eventId].name;
              url = '/efforts/' + effort.id;
            } else {
              fullName = '[Bib not found]';
              eventName = '--'
            }
          }

          const effortNameElement = document.getElementById('js-effort-name');
          const eventNameElement = document.getElementById('js-effort-event-name');
          const bibNumberElement = document.getElementById('js-bib-number');
          const bibStatus = liveEntry.bibStatus(bibNumber, splitName);

          effortNameElement.innerHTML = fullName;
          effortNameElement.setAttribute('data-effort-id', effortId);
          effortNameElement.setAttribute('data-event-id', eventId);
          effortNameElement.href = url;
          eventNameElement.innerHTML = eventName;
          bibNumberElement.classList.remove('null', 'bad', 'questionable', 'good');
          bibNumberElement.classList.add(bibStatus)
          bibNumberElement.setAttribute('data-bib-status', bibStatus);

          if (bibChanged) {
            if (effort) {
              // Populate effort table
              liveEntry.liveEntryForm.lastEffortInfoBib = bibNumber;
              const table_url = `/efforts/${effortId}/live_entry_table`;
              const options = {responseKind: "turbo-stream"}
              get(table_url, options)
            } else {
              // Clear effort table
              liveEntry.liveEntryForm.lastEffortInfoBib = null;
              document.getElementById('lap_split_rows_for_live_entry').innerHTML = '';
            }
          }
        },

        /**
         * Highlights the row in the effort table that corresponds to the current station and lap number.
         */
        highlightEffortTableRow: function () {
          const splitName = liveEntry.currentStation().splitName;
          let lapNumber = document.getElementById('js-lap-number').value;
          lapNumber = parseInt(lapNumber) || 1;

          const rows = [...document.querySelectorAll('#lap_split_rows_for_live_entry tr')]
          rows.forEach(row => row.classList.remove('table-primary'))

          const currentRow = rows.find(row => {
            return row.dataset.splitName === splitName && parseInt(row.dataset.lapNumber) === lapNumber
          })

          if (currentRow) {
            currentRow.classList.add('table-primary')
            currentRow.scrollIntoView(false);
          }
        },

        stripBibLeadingZeros: function () {
          let element = document.getElementById('js-bib-number');
          let str = element.value;

          if (str !== '0') {
            element.value = str.replace(/^0+/, '');
          }
        },

        /**
         * Adds dataStatus and splitTimeExists to rawTimes in the form.
         */
        enrichTimeData: function () {
          const bibNumber = document.getElementById('js-bib-number').value;
          const bibChanged = (bibNumber !== liveEntry.liveEntryForm.lastEnrichTimeBib);
          const splitChanged = (liveEntry.currentStationIndex !== liveEntry.liveEntryForm.lastStationIndex);
          liveEntry.liveEntryForm.lastEnrichTimeBib = bibNumber;
          liveEntry.liveEntryForm.lastStationIndex = liveEntry.currentStationIndex;

          const currentFormComp = liveEntry.rawTimeRow.compData(liveEntry.liveEntryForm.getTimeRow());
          const lastRequestComp = liveEntry.rawTimeRow.compData(liveEntry.lastFormRequest);

          if (JSON.stringify(currentFormComp) === JSON.stringify(lastRequestComp)) {
            return Promise.resolve(); // We already have the information for this data.
          }

          // Clear out dataStatus and splitTimeExists from the last request
          liveEntry.liveEntryForm.updateTimeField(document.getElementById('js-time-in'), {dataStatus: null, splitTimeExists: null});
          liveEntry.liveEntryForm.updateTimeField(document.getElementById('js-time-out'), {dataStatus: null, splitTimeExists: null});

          const requestData = {
            data: {
              rawTimeRow: liveEntry.liveEntryForm.getTimeRow()
            }
          };

          return post('/api/v1/event_groups/' + liveEntry.currentEventGroupId + '/enrich_raw_time_row', {
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestData)
          }).then(function (response) {
            if (response.ok) {
              return response.json
            } else {
              console.error('time row enrichment failed', response)
            }
          }).then(function (json) {
            liveEntry.currentFormResponse = json;
            liveEntry.lastFormRequest = requestData.data.rawTimeRow;

            const rawTime = liveEntry.currentRawTime();
            const inRawTime = liveEntry.currentRawTime('in');
            const outRawTime = liveEntry.currentRawTime('out');

            const lapNumberInput = document.getElementById('js-lap-number');
            if (!lapNumberInput.value || bibChanged || splitChanged) {
              if (rawTime.enteredLap) lapNumberInput.value = rawTime.enteredLap;
              document.querySelector('#js-lap-number:focus')?.select();
            }

            liveEntry.liveEntryForm.updateTimeField(document.getElementById('js-time-in'), inRawTime);
            liveEntry.liveEntryForm.updateTimeField(document.getElementById('js-time-out'), outRawTime);
          });
        },

        /**
         * Retrieves the entire form formatted as a rawTimeRow
         * @return object a single rawTimeRow
         */
        getTimeRow: function () {
          const subSplitKinds = liveEntry.currentStation().subSplitKinds;
          let uniqueId = parseInt(document.getElementById('js-unique-id').value)
          if (isNaN(uniqueId)) uniqueId = null;

          return {
            uniqueId: uniqueId,
            rawTimes: subSplitKinds.map(function (kind) {
                const timeField = document.getElementById(`js-time-${kind}`);
                const dataStatus = timeField.dataset.dataStatus === 'null' ? null : timeField.dataset.dataStatus;
                return {
                  eventGroupId: liveEntry.currentEventGroupId,
                  bibNumber: document.getElementById('js-bib-number').value,
                  enteredTime: timeField.value,
                  militaryTime: timeField.value,
                  enteredLap: document.getElementById('js-lap-number').value,
                  splitName: liveEntry.currentStation().title,
                  subSplitKind: kind,
                  stoppedHere: document.getElementById('js-dropped').checked,
                  withPacer: document.getElementById(`js-pacer-${kind}`).checked,
                  dataStatus: dataStatus,
                  splitTimeExists: (timeField.dataset.splitTimeExists === 'true'),
                  source: `Live Entry (${liveEntry.currentUser})`
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
          $('#js-bib-number').val(rawTime.bibNumber).focus();
          $('#js-lap-number').val(rawTime.enteredLap);
          $inTimeField.val(inRawTime.militaryTime);
          $outTimeField.val(outRawTime.militaryTime);
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
          const uniqueIdElement = document.getElementById('js-unique-id')
          if (uniqueIdElement.value !== '') {
            const row = document.getElementById(`workspace-${uniqueIdElement.value}`);
            row.classList.remove('bg-highlight');
            uniqueIdElement.value = '';
          }
          document.getElementById('js-effort-name').innerHTML = ''
          document.getElementById('js-effort-name').removeAttribute('href')
          document.getElementById('js-effort-event-name').innerHTML = ''
          document.getElementById('js-time-in').classList.remove('exists', 'null', 'bad', 'good', 'questionable');
          document.getElementById('js-time-out').classList.remove('exists', 'null', 'bad', 'good', 'questionable');
          document.getElementById('js-time-in').value = ''
          document.getElementById('js-time-out').value = ''
          document.getElementById('js-bib-number').value = ''
          document.getElementById('js-lap-number').value = '1'
          document.getElementById('js-pacer-in').checked = false
          document.getElementById('js-pacer-out').checked = false
          document.getElementById('js-dropped').checked = false
          liveEntry.liveEntryForm.buttonAddMode();
          liveEntry.liveEntryForm.updateEffortInfo();
          liveEntry.liveEntryForm.enrichTimeData();
          liveEntry.liveEntryForm.setDroppedButtonStyling();
        },

        buttonAddMode: function () {
          document.getElementById('js-add-to-cache').innerHTML = 'Add'
          document.getElementById('js-discard-entry-form').innerHTML = 'Discard'
        },

        buttonUpdateMode: function () {
          document.getElementById('js-add-to-cache').innerHTML = 'Update'
          document.getElementById('js-discard-entry-form').innerHTML = 'Cancel'
        },

        updateTimeField: function (field, rawTime) {
          field.classList.remove('exists', 'null', 'bad', 'good', 'questionable');
          if (rawTime.splitTimeExists) field.classList.add('exists')
          field.classList.add(rawTime.dataStatus)
          field.setAttribute('data-time-status', rawTime.dataStatus);
          field.setAttribute('data-split-time-exists', rawTime.splitTimeExists)
        }
      }, // END liveEntryForm

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

          const deleteWarning = document.getElementById('js-delete-all-warning');
          deleteWarning.style.display = 'none';
          deleteWarning.parentNode.removeChild(deleteWarning);

          // Attach add listener
          document.getElementById('js-add-to-cache').addEventListener('click', function (event) {
            event.preventDefault();
            liveEntry.liveEntryForm.buttonAddMode();
            liveEntry.timeRowsTable.addTimeRowFromForm();
            return false;
          });

          // Wrap search field with clear button
          $('#js-local-workspace-table_filter input')
            .wrap('<div class="mb-3 has-feedback"></div>')
            .on('change keyup', function () {
              var value = $(this).val() || '';
              if (value.length > 0) {
                $('#js-filter-clear').show();
              } else {
                $('#js-filter-clear').hide();
              }
            });
          $('#js-local-workspace-table_filter .input-group').append(
            '<span id="js-filter-clear" class="fas fa-times-circle dataTables_filter-clear form-control-feedback" aria-hidden="true"></span>'
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
          liveEntry.liveEntryForm.enrichTimeData().then(function () {
            const rawTimeRow = liveEntry.liveEntryForm.getTimeRow();

            if (liveEntry.rawTimeRow.empty(rawTimeRow)) return;
            if (rawTimeRow.uniqueId === null) rawTimeRow.uniqueId = liveEntry.timeRowsCache.getUniqueId();

            liveEntry.timeRowsCache.upsertTimeRow(rawTimeRow);

            // Clear data and put focus on bibNumber field once we've collected all the data
            liveEntry.liveEntryForm.clear();
            document.getElementById('js-bib-number').focus();
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
            node.node().classList.add("bg-highlight")

            setTimeout(function () {
              node.node().classList.remove("bg-highlight");
              node.node().classList.add("bg-highlight-faded-fast");
            }, 200);
          }
        },

        updateTimeRowInTable: function (rawTimeRow) {
          liveEntry.timeRowsTable.$dataTable.search('');
          $('#js-filter-clear').hide();

          var trHtml = liveEntry.timeRowsTable.buildTrHtml(rawTimeRow);
          var rowData = liveEntry.timeRowsTable.trToData(trHtml);
          var $row = $('#workspace-' + rawTimeRow.uniqueId);
          $row.removeClass('bg-highlight');
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

          var data = JSON.stringify({data: timeRows, forceSubmit: forceSubmit});
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
            // If any time rows were bounced back...
            if (returnedRows.length >= 1) {
              // If submitting one node...
              if (tableNodes.length <= 1) {
                liveEntry.sendNotice({
                  title: 'Failed to submit time row',
                  body: returnedRows[0].errors.join(', ')
                }, {
                  type: 'danger'
                });
                // If submitting multiple nodes...
              } else {
                liveEntry.sendNotice({
                  title: 'Failed to submit ' + returnedRows.length +
                    ' of ' + tableNodes.length + ' time rows',
                  body: ''
                }, {
                  type: 'danger'
                });
              }
            }
          }).always(function () {
            liveEntry.timeRowsTable.busy = false;
          });
        },

        buildTrHtml: function (rawTimeRow) {
          var bibIcons = {
            'good': '&nbsp;<span class="fas fa-check-circle text-success" data-controller="tooltip" title="Bib Found"></span>',
            'questionable': '&nbsp;<span class="fas fa-question-circle text-warning" data-controller="tooltip" title="Bib In Wrong Event"></span>',
            'bad': '&nbsp;<span class="fas fa-times-circle text-danger" data-controller="tooltip" title="Bib Not Found"></span>'
          };
          var inRawTime = liveEntry.rawTimeFromRow(rawTimeRow, 'in');
          var outRawTime = liveEntry.rawTimeFromRow(rawTimeRow, 'out');
          var rawTime = liveEntry.rawTimeFromRow(rawTimeRow);

          var bibStatus = liveEntry.bibStatus(rawTime.bibNumber, rawTime.splitName);
          var bibIcon = bibIcons[bibStatus];
          var timeInIcon = statusIcons[inRawTime.dataStatus] || '';
          timeInIcon += (inRawTime.splitTimeExists ? statusIcons['exists'] : '');
          var timeOutIcon = statusIcons[outRawTime.dataStatus] || '';
          timeOutIcon += (outRawTime.splitTimeExists ? statusIcons['exists'] : '');

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
                        <td class="lap-number js-lap-number lap-only">' + rawTime.enteredLap + '</td>\
                        <td class="time-in js-time-in text-nowrap time-in-only ' + inRawTime.dataStatus + '">' + (inRawTime.militaryTime || '') + timeInIcon + '</td>\
                        <td class="time-out js-time-out text-nowrap time-out-only ' + outRawTime.dataStatus + '">' + (outRawTime.militaryTime || '') + timeOutIcon + '</td>\
                        <td class="pacer-inout js-pacer-inout pacer-only">' + (inRawTime.withPacer ? 'Yes' : 'No') + ' / ' + (outRawTime.withPacer ? 'Yes' : 'No') + '</td>\
                        <td class="dropped-here js-dropped-here">' + (inRawTime.stoppedHere || outRawTime.stoppedHere ? '<span class="btn btn-warning btn-xs disabled">Done</span>' : '') + '</td>\
                        <td class="row-edit-btns">\
                            <button class="effort-row-btn edit-effort js-edit-effort btn btn-primary"><i class="fas fa-pencil-alt"></i></button>\
                            <button class="effort-row-btn delete-effort js-delete-effort btn btn-danger"><i class="fas fa-times"></i></button>\
                            <button class="effort-row-btn submit-effort js-submit-effort btn btn-success"><i class="fas fa-check"></i></button>\
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
         */
        toggleDiscardAll: (function () {
          const callback = function () {
            liveEntry.timeRowsTable.toggleDiscardAll(false);
          };

          const deleteWarning = document.getElementById('js-delete-all-warning');

          return function (canDelete) {
            const nodes = Array.from(liveEntry.timeRowsTable.$dataTable.rows().nodes());
            const deleteButton = document.getElementById('js-delete-all-time-rows');
            deleteButton.disabled = true;
            document.removeEventListener('click', callback);
            deleteButton.parentNode.insertBefore(deleteWarning, deleteButton.nextSibling);
            deleteWarning.style.display = 'block';
            const animationProps = {
              width: 'toggle',
              paddingLeft: 'toggle',
              paddingRight: 'toggle'
            };
            const animationOptions = {
              duration: 350,
              done: function () {
                deleteButton.disabled = false;
                if (deleteButton.classList.contains('confirm')) {
                  if (canDelete) {
                    liveEntry.timeRowsTable.removeTimeRows(nodes);
                    document.querySelector('#js-station-select').focus();
                  }
                  deleteButton.classList.remove('confirm');
                  deleteWarning.style.display = 'none';
                  deleteWarning.parentNode.removeChild(deleteWarning);
                } else {
                  deleteButton.classList.add('confirm');
                  document.addEventListener('click', callback);
                }
              }
            };
            this.animate(deleteWarning, animationProps, animationOptions);
          }
        })(),

        animate: (function (element, properties, options) {
          let start = null;
          const from = {};
          const to = {};
          for (let property in properties) {
            from[property] = parseInt(getComputedStyle(element)[property]);
            to[property] = parseInt(properties[property]);
          }

          function step(timestamp) {
            if (!start) start = timestamp;
            const progress = timestamp - start;
            for (let property in properties) {
              const value = from[property] + (to[property] - from[property]) * (progress / options.duration);
              element.style[property] = value + 'px';
            }
            if (progress < options.duration) {
              window.requestAnimationFrame(step);
            } else {
              if (typeof options.done === 'function') {
                options.done();
              }
            }
          }

          window.requestAnimationFrame(step);
        }),

        /**
         * Move a "cached" table row to "top form" section for editing.
         *
         */
        timeRowControls: function () {

          $(document).on('click', '.js-edit-effort', function (event) {
            event.preventDefault();
            var $row = $(this).closest('tr');
            var clickedTimeRow = JSON.parse(atob($row.attr('data-encoded-raw-time-row')));

            $row.addClass('bg-highlight');
            liveEntry.liveEntryForm.buttonUpdateMode();
            liveEntry.liveEntryForm.loadTimeRow(clickedTimeRow);
            liveEntry.liveEntryForm.enrichTimeData();
            liveEntry.liveEntryForm.updateEffortInfo();
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
            rawTimes: row['rawTimes'].map(rawTime => {
              return {
                bibNumber: rawTime.bibNumber,
                enteredTime: rawTime.enteredTime,
                militaryTime: rawTime.militaryTime,
                lap: rawTime.enteredLap,
                splitName: rawTime.splitName,
                subSplitKind: rawTime.subSplitKind,
                stoppedHere: rawTime.stoppedHere
              }
            })
          }
        },

        empty: function (row) {
          const rawTimeIn = liveEntry.rawTimeFromRow(row, 'in');
          const rawTimeOut = liveEntry.rawTimeFromRow(row, 'out');

          const emptyIn = (rawTimeIn.bibNumber === undefined && rawTimeIn.enteredTime === undefined) ||
            (rawTimeIn.bibNumber === '' && rawTimeIn.enteredTime === '');
          const emptyOut = (rawTimeOut.bibNumber === undefined && rawTimeOut.enteredTime === undefined) ||
            (rawTimeOut.bibNumber === '' && rawTimeOut.enteredTime === '');

          return emptyIn && emptyOut
        }
      } // END rawTimeRow

    } // end liveEntry

    liveEntry.init(controller)
  } // end liveEntryApp()
}

import { Controller } from "@hotwired/stimulus"
import { get, patch, post } from "@rails/request.js"
import { DataTable } from "simple-datatables"

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
      'exists': '<span class="fas fa-exclamation-circle ms-1" data-controller="tooltip" title="Data Already Exists"></span>',
      'good': '<span class="fas fa-check-circle text-success ms-1" data-controller="tooltip" title="Time Appears Good"></span>',
      'questionable': '<span class="fas fa-question-circle text-warning ms-1" data-controller="tooltip" title="Time Appears Questionable"></span>',
      'bad': '<span class="fas fa-times-circle text-danger ms-1" data-controller="tooltip" title="Time Appears Bad"></span>'
    };

    const bibIcons = {
      'good': '<span class="fas fa-check-circle text-success ms-1" data-controller="tooltip" title="Bib Found"></span>',
      'questionable': '<span class="fas fa-question-circle text-warning ms-1" data-controller="tooltip" title="Bib In Wrong Event"></span>',
      'bad': '<span class="fas fa-times-circle text-danger ms-1" data-controller="tooltip" title="Bib Not Found"></span>'
    };

    const stoppedIcon = '<span class="fas fa-hand-paper text-danger ms-1" data-controller="tooltip" title="Stopped Here"></span>';

    let liveEntry = {

      eventGroupResponse: null,
      multiLap: null,
      multiEvent: null,
      monitorPacers: null,
      anySubSplitOut: null,
      currentStationIndex: null,
      currentFormResponse: {},
      emptyRawTimeRow: {rawTimes: []},
      lastFormRequest: {},
      container: controller.element,
      currentUserId: controller.currentUserIdValue,
      currentEventGroupId: controller.eventGroupIdValue,
      serverURI: controller.serverUriValue,

      init: function () {
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

      populateRows: function (rawTimeRows) {
        rawTimeRows.forEach(rawTimeRow => {
          rawTimeRow.uniqueId = liveEntry.timeRowsCache.getUniqueId();

          const storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
          if (!liveEntry.timeRowsCache.isMatchedTimeRow(rawTimeRow)) {
            storedTimeRows.push(rawTimeRow);
            liveEntry.timeRowsCache.setStoredTimeRows(storedTimeRows);
            liveEntry.timeRowsTable.addTimeRowToTable(rawTimeRow);
          }
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

      sendNotice: function (object) {
        const options = {
          detail: {
            title: object.title,
            body: object.body,
            type: object.type,
          },
          bubbles: true,
        }

        const showToastEvent = new CustomEvent("show-toast", options)
        liveEntry.container.dispatchEvent(showToastEvent)
      },

      setCurrentTimestamp: function (rawTimeRow) {
        rawTimeRow.timestamp = Math.round(Date.now() / 1000)
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
          liveEntry.multiLap = liveEntry.eventGroupAttributes.multiLap;
          liveEntry.multiEvent = liveEntry.eventGroupResponse.data.relationships.events.data.length > 1;
          liveEntry.monitorPacers = liveEntry.eventGroupAttributes.monitorPacers;

          liveEntry.dataSetup.buildBibEventIdMap();
          liveEntry.dataSetup.buildEvents();
          liveEntry.dataSetup.buildBibEffortMap();
          liveEntry.dataSetup.buildStationIndexMap();
          liveEntry.lastFormRequest = liveEntry.emptyRawTimeRow;
          liveEntry.anySubSplitOut = liveEntry.subSplitKinds.includes('out');
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
         * @return number Unique Time Row Id
         */
        getUniqueId: function () {
          return Math.floor(Math.random() * Date.now())
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
         * @return null
         * @param subjectTimeRow
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
         * @return boolean    True if match found, False if no match found
         * @param subjectTimeRow Pass in Object of the subjectTimeRow to check it against the stored objects         *
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
          if (liveEntry.multiLap) document.querySelectorAll('.lap-disabled').forEach(el => el.classList.remove('lap-disabled'));
          if (liveEntry.multiEvent) document.querySelectorAll('.group-disabled').forEach(el => el.classList.remove('group-disabled'));
          if (liveEntry.monitorPacers) document.querySelectorAll('.pacer-disabled').forEach(el => el.classList.remove('pacer-disabled'));
          if (liveEntry.anySubSplitOut) document.querySelectorAll('.time-out-disabled').forEach(el => el.classList.remove('time-out-disabled'));

          liveEntry.liveEntryForm.clear()

          // Clears the live entry form when the clear button is clicked
          document.getElementById('js-discard-entry-form').addEventListener('click', function (event) {
            event.preventDefault();
            liveEntry.liveEntryForm.clear();
            liveEntry.timeRowsTable.clearEditIndicator();
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

          const rows = Array.from(document.querySelectorAll('#lap_split_rows_for_live_entry tr'))
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

          return post(`/api/v1/event_groups/${liveEntry.currentEventGroupId}/enrich_raw_time_row`, {
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
          const subSplitKindForStop = document.getElementById('js-time-out').value ? 'out' : 'in';
          let uniqueId = parseInt(document.getElementById('js-unique-id').value)
          if (isNaN(uniqueId)) uniqueId = null;

          const rawTimeRow = {
            uniqueId: uniqueId,
            rawTimes: subSplitKinds.map(function (kind) {
                const timeField = document.getElementById(`js-time-${kind}`);
                const dataStatus = timeField.dataset.timeStatus === 'null' ? null : timeField.dataset.timeStatus;
                return {
                  eventGroupId: liveEntry.currentEventGroupId,
                  bibNumber: document.getElementById('js-bib-number').value,
                  enteredTime: timeField.value,
                  militaryTime: timeField.value,
                  enteredLap: document.getElementById('js-lap-number').value,
                  splitName: liveEntry.currentStation().title,
                  subSplitKind: kind,
                  stoppedHere: timeField.value && (kind === subSplitKindForStop) && document.getElementById('js-dropped').checked,
                  withPacer: document.getElementById(`js-pacer-${kind}`).checked,
                  dataStatus: dataStatus,
                  splitTimeExists: (timeField.dataset.splitTimeExists === 'true'),
                  source: `Live Entry (${liveEntry.currentUserId})`
                }
              }
            )
          }
          liveEntry.setCurrentTimestamp(rawTimeRow)
          return rawTimeRow
        },

        loadTimeRow: function (rawTimeRow) {
          liveEntry.lastFormRequest = liveEntry.emptyRawTimeRow;
          liveEntry.currentFormResponse = rawTimeRow;

          const rawTime = liveEntry.rawTimeFromRow(rawTimeRow);
          const inRawTime = liveEntry.rawTimeFromRow(rawTimeRow, 'in');
          const outRawTime = liveEntry.rawTimeFromRow(rawTimeRow, 'out');
          const stationIndex = liveEntry.indexStationMap[rawTime.splitName];

          const bibField = document.getElementById('js-bib-number');
          const inTimeField = document.getElementById('js-time-in');
          const outTimeField = document.getElementById('js-time-out');

          document.getElementById('js-unique-id').value = rawTimeRow.uniqueId;
          bibField.value = rawTime.bibNumber;
          document.getElementById('js-lap-number').value = rawTime.enteredLap;
          inTimeField.value = inRawTime.militaryTime;
          outTimeField.value = outRawTime.militaryTime;
          document.getElementById('js-pacer-in').checked = inRawTime.withPacer;
          document.getElementById('js-pacer-out').checked = outRawTime.withPacer;
          document.getElementById('js-dropped').checked = inRawTime.stoppedHere || outRawTime.stoppedHere;
          liveEntry.liveEntryForm.updateTimeField(inTimeField, inRawTime);
          liveEntry.liveEntryForm.updateTimeField(outTimeField, outRawTime);
          liveEntry.header.changeStationSelect(stationIndex);
          liveEntry.liveEntryForm.setDroppedButtonStyling();
          bibField.focus()
        },

        /**
         * Clears out the entry form and effort detail data fields
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
        dataTable: null,
        busy: false,
        editIndicatorClass: 'bg-light',
        editButton: '<button class="effort-row-btn edit-effort js-edit-effort btn btn-primary"><i class="fas fa-pencil-alt"></i></button>',
        deleteButton: '<button class="effort-row-btn delete-effort js-delete-effort btn btn-danger"><i class="fas fa-times"></i></button>',
        submitButton: '<button class="effort-row-btn submit-effort js-submit-effort btn btn-success"><i class="fas fa-check"></i></button>',

        /**
         * Inits the Local Workspace
         *
         */
        init: function () {

          // Initiate DataTable object
          this.dataTable = new DataTable('#js-local-workspace-table', {
            paging: false,
            classes: {
              top: "datatable-top mb-4",
              input: "form-control",
              table: "datatable-table table",
            },
            rowRender: (row, tr, _index) => {
              tr.attributes.id = `workspace-${row[9].text}`;
              tr.attributes['data-unique-id'] = row[9].text;
              tr.attributes['data-controller'] = 'highlight';
              tr.attributes['data-highlight-timestamp-value'] = row[11].text;
              tr.attributes['data-highlight-fast-value'] = true;
              tr.attributes.class = 'align-middle'
            },
            columns: [
              {
                select: 1,
                hidden: !liveEntry.multiEvent,
                searchable: liveEntry.multiEvent,
              },
              {
                select: 2,
                headerClass: 'text-center',
                render: (_data, cell, _row) => {
                  cell.attributes = {
                    class: 'text-center'
                  }
                }
              },
              {
                select: 4,
                hidden: !liveEntry.multiLap,
                searchable: false,
              },
              {
                select: 6,
                hidden: !liveEntry.anySubSplitOut,
              },
              {
                select: 7,
                sortable: false,
                searchable: false,
                hidden: !liveEntry.monitorPacers,
                headerClass: 'text-center',
                render: (_data, cell, _row) => {
                  cell.attributes = {
                    class: 'text-center'
                  }
                }
              },
              {
                select: 8,
                searchable: false,
                sortable: false,
                headerClass: 'text-end',
                render: (_data, cell, _row) => {
                  cell.attributes = {
                    class: 'row-edit-btns'
                  }
                }
              },
              {
                select: [9, 10, 11, 12],
                hidden: true,
                searchable: false,
              },
              {
                select: 11,
                sort: "desc",
              },
            ],
          })

          liveEntry.timeRowsTable.populateTableFromCache();
          liveEntry.timeRowsTable.addListenersToTableControls();

          // Set up the Delete All button
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
        },

        populateTableFromCache: function () {
          const storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
          Array.from(storedTimeRows).forEach(storedTimeRow => {
            liveEntry.timeRowsTable.addTimeRowToTable(storedTimeRow, false);
          });
          liveEntry.timeRowsTable.dataTable.refresh();
        },

        addTimeRowFromForm: function () {
          // Retrieve form data
          liveEntry.liveEntryForm.enrichTimeData().then(function () {
            const rawTimeRow = liveEntry.liveEntryForm.getTimeRow();

            if (liveEntry.rawTimeRow.empty(rawTimeRow)) return;
            if (!rawTimeRow.uniqueId) rawTimeRow.uniqueId = liveEntry.timeRowsCache.getUniqueId();

            liveEntry.timeRowsCache.upsertTimeRow(rawTimeRow);

            // Clear data and put focus on bibNumber field once we've collected all the data
            liveEntry.liveEntryForm.clear();
            document.getElementById('js-bib-number').focus();
          });
        },

        addTimeRowToTable: function (rawTimeRow) {
          this.dataTable.search('')

          const timeRowTableObject = this.buildRowObject(rawTimeRow);
          this.dataTable.insert([timeRowTableObject])
          this.dataTable.refresh()
          this.addListenersToRowControls(rawTimeRow.uniqueId)
        },

        updateTimeRowInTable: function (rawTimeRow) {
          liveEntry.timeRowsTable.dataTable.search('');
          liveEntry.setCurrentTimestamp(rawTimeRow)
          this.removeTimeRows([rawTimeRow.uniqueId])
          this.addTimeRowToTable(rawTimeRow)
        },

        pullTimeRows: function (force) {
          if (liveEntry.importAsyncBusy) return;
          liveEntry.importAsyncBusy = true;

          const url = `/api/v1/event_groups/${liveEntry.currentEventGroupId}/pull_raw_times`
          const options = {
            query: {
              forcePull: force,
            },
          }

          patch(url, options).then(function (response) {
            if (response.ok) {
              return response.json
            } else {
              console.error('time row enrichment failed', response)
            }
          }).then(function (json) {
            const rawTimeRows = json.data.rawTimeRows;
            if (rawTimeRows.length === 0) {
              liveEntry.sendNotice({
                title: "You are up to date",
                body: "There are no raw times available to pull",
                type: "success",
              })
              return;
            }
            liveEntry.populateRows(rawTimeRows);
          }).catch(function (error) {
            liveEntry.sendNotice({
              title: "Pull times failed",
              body: error,
              type: "alert",
            })
          }).finally(function () {
            liveEntry.importAsyncBusy = false;
          })
          return false;
        },

        removeTimeRows: function (uniqueIds) {
          uniqueIds.forEach(uniqueId => {
            const dataTableIndex = liveEntry.timeRowsTable.indexFromUniqueId(uniqueId);
            const rawTimeRow = liveEntry.timeRowsTable.rawTimeRowFromUniqueId(uniqueId);

            // remove timeRow from cache
            liveEntry.timeRowsCache.deleteStoredTimeRow(rawTimeRow);
            liveEntry.timeRowsTable.dataTable.rows.remove(dataTableIndex);
          })
        },

        submitTimeRows: function (uniqueIds, forceSubmit) {
          if (liveEntry.timeRowsTable.busy) return;
          liveEntry.timeRowsTable.busy = true;

          const rawTimeRows = [];

          uniqueIds.forEach(uniqueId => {
            const rawTimeRow = liveEntry.timeRowsTable.rawTimeRowFromUniqueId(uniqueId);
            rawTimeRows.push({rawTimeRow: rawTimeRow});
          });

          const url = `/api/v1/event_groups/${liveEntry.currentEventGroupId}/submit_raw_time_rows`
          const data = JSON.stringify({data: rawTimeRows, forceSubmit: forceSubmit});
          const options = {
            headers: {
              'Content-Type': 'application/json'
            },
            body: data,
          }
          post(url, options).then(function (response) {
            if (response.ok) {
              return response.json
            } else {
              console.error('time row submit failed', response)
            }
          }).then(function (json) {
            liveEntry.timeRowsTable.removeTimeRows(uniqueIds);
            const returnedTimeRows = json.data.rawTimeRows;
            returnedTimeRows.forEach(returnedTimeRow => {
              returnedTimeRow.uniqueId = liveEntry.timeRowsCache.getUniqueId();
              liveEntry.setCurrentTimestamp(returnedTimeRow)

              const storedTimeRows = liveEntry.timeRowsCache.getStoredTimeRows();
              if (!liveEntry.timeRowsCache.isMatchedTimeRow(returnedTimeRow)) {
                storedTimeRows.push(returnedTimeRow);
                liveEntry.timeRowsCache.setStoredTimeRows(storedTimeRows);
                liveEntry.timeRowsTable.addTimeRowToTable(returnedTimeRow);
              }
            })

            // If any time rows were bounced back...
            if (returnedTimeRows.length >= 1) {
              // If submitting one node...
              if (uniqueIds.length <= 1) {
                liveEntry.sendNotice({
                  title: 'Failed to submit time row',
                  body: returnedTimeRows[0].errors.join(', ')
                }, {
                  type: 'danger'
                });
                // If submitting multiple nodes...
              } else {
                liveEntry.sendNotice({
                  title: 'Failed to submit ' + returnedTimeRows.length +
                    ' of ' + uniqueIds.length + ' time rows',
                  body: ''
                }, {
                  type: 'danger'
                });
              }
            }
          }).catch(function (error) {
            console.error(error)
          }).finally(function () {
            liveEntry.timeRowsTable.busy = false;
          });
        },

        buildRowObject: function (rawTimeRow) {
          const inRawTime = liveEntry.rawTimeFromRow(rawTimeRow, 'in');
          const outRawTime = liveEntry.rawTimeFromRow(rawTimeRow, 'out');
          const rawTime = liveEntry.rawTimeFromRow(rawTimeRow);
          const event = liveEntry.events[liveEntry.bibEventIdMap[rawTime.bibNumber]] || {name: '--'};
          const effort = liveEntry.bibEffortMap[rawTime.bibNumber];
          const bibStatus = liveEntry.bibStatus(rawTime.bibNumber, rawTime.splitName);

          return {
            "Aid Station": rawTime.splitName,
            "Event": event.name,
            "Bib": rawTime.bibNumber + bibIcons[bibStatus],
            "Name": (effort ? `<a href="/efforts/${effort.id}">${effort.attributes.fullName}</a>` : '[Bib not found]'),
            "Lap": rawTime.enteredLap,
            "Time In": (inRawTime.militaryTime || '') +
              (inRawTime.splitTimeExists ? statusIcons['exists'] : '') +
              (statusIcons[inRawTime.dataStatus] || '') +
              (inRawTime.stoppedHere ? stoppedIcon : ''),
            "Time Out": (outRawTime.militaryTime || '') +
              (outRawTime.splitTimeExists ? statusIcons['exists'] : '') +
              (statusIcons[outRawTime.dataStatus] || '') +
              (outRawTime.stoppedHere ? stoppedIcon : ''),
            "Pacer": `${(inRawTime.withPacer ? 'Yes' : 'No')} / ${(outRawTime.withPacer ? 'Yes' : 'No')}`,
            "Actions": liveEntry.timeRowsTable.editButton + liveEntry.timeRowsTable.deleteButton + liveEntry.timeRowsTable.submitButton,
            "ID": rawTimeRow.uniqueId,
            "Encoded": btoa(JSON.stringify(rawTimeRow)),
            "Timestamp": rawTimeRow.timestamp,
          }
        },

        trFromUniqueId: function (uniqueId) {
          return document.getElementById('workspace-' + uniqueId);
        },

        indexFromUniqueId: function (uniqueId) {
          const trElement = this.trFromUniqueId(uniqueId);
          return parseInt(trElement.dataset.index);
        },

        rawTimeRowFromUniqueId: function (uniqueId) {
          const trElement = this.trFromUniqueId(uniqueId);
          const dataTableIndex = parseInt(trElement.dataset.index);
          const encodedData = this.dataTable.data.data[dataTableIndex][10].text
          return JSON.parse(atob(encodedData));
        },

        clearEditIndicator: function () {
          const trElements = this.dataTable.containerDOM.querySelectorAll(`tr.${this.editIndicatorClass}`);
          Array.from(trElements).forEach(trElement => {
            trElement.classList.remove(this.editIndicatorClass)
          })
        },

        getAllUniqueIds: function () {
          return liveEntry.timeRowsTable.dataTable.data.data.map(dataRow => {
            return dataRow[9].text
          })
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
            const allUniqueIds = liveEntry.timeRowsTable.getAllUniqueIds()
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
                    liveEntry.timeRowsTable.removeTimeRows(allUniqueIds);
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
         * Set event listeners on time row controls
         *
         */
        addListenersToTableControls: function () {
          document.getElementById('js-delete-all-time-rows').addEventListener('click', function (event) {
            event.preventDefault();
            liveEntry.timeRowsTable.toggleDiscardAll(true);
            return false;
          });

          document.getElementById('js-submit-all-time-rows').addEventListener('click', function (event) {
            event.preventDefault();
            const allUniqueIds = liveEntry.timeRowsTable.getAllUniqueIds()
            liveEntry.timeRowsTable.submitTimeRows(allUniqueIds, false);
            return false;
          });
        },

        addListenersToRowControls: function (uniqueId) {
          const element = this.trFromUniqueId(uniqueId)

          element.querySelector('.js-edit-effort').addEventListener('click', function () {
            const rawTimeRow = liveEntry.timeRowsTable.rawTimeRowFromUniqueId(uniqueId);

            element.classList.add(liveEntry.timeRowsTable.editIndicatorClass);
            liveEntry.liveEntryForm.buttonUpdateMode();
            liveEntry.liveEntryForm.loadTimeRow(rawTimeRow);
            liveEntry.liveEntryForm.enrichTimeData();
            liveEntry.liveEntryForm.updateEffortInfo();
          })

          element.querySelector('.js-delete-effort').addEventListener('click', function () {
            liveEntry.timeRowsTable.removeTimeRows([uniqueId]);
          })

          element.querySelector('.js-submit-effort').addEventListener('click', function () {
            liveEntry.timeRowsTable.submitTimeRows([uniqueId], true);
          })
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

    liveEntry.init()
  } // end liveEntryApp()
}

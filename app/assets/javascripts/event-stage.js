//= require jsonapi

(function ($) {

    function formatDate( date ) {
        return ( "0" + ( date.getMonth() + 1 ) ).slice( -2 ) + "/" + ( "0" + date.getDate() ).slice( -2 ) + "/" + date.getFullYear();
    }

    /**
     * This object stores the countries and regions array
     */
    var locales = {
        countries : [],
        countryNames : {},
        regions : {},
        timeZones : []
    }

    /**
     *  Units in terms of meters
     */
    var units = {
        table: {
            "kilometers": 0.001,
            "miles": 0.000621371,
            "feet": 3.28084,
            "meters": 1.0
        },
        distance: "kilometers",
        elevation: "meters",
        forDistance: function() {
            return this.table[ this.distance ] || 1.0;
        },
        forElevation: function() {
            return this.table[ this.elevation ] || 1.0;
        },
        import: function( type ) {
            return function( val ) {
                return val * units[type]();
            }
        },
        export: function( type ) {
            return function( val ) {
                return val / units[type]();
            }
        },
        round: function( value, places ) {
            var scalar = Math.pow( 10, places );
            return Math.round( value * scalar ) / scalar;
        }
    }

    /**
     * Ajax headers to be used for every transaction
     */
    var headers = {
        'X-Key-Inflection': 'camel',
        'Content-Type': 'application/json'
    }

    var api = JSONAPI( '/api/v1/' );
    api.define( 'splits', {
        attributes: {
            baseName: String,
            distanceFromStart: { type: Number, default: 0 },
            vertGainFromStart: { type: Number, default: 0 },
            vertLossFromStart: { type: Number, default: 0 },
            kind: { type: String, default: 'intermediate' },
            nameExtensions: Array,
            description: String,
            latitude: Number,
            longitude: Number,
            elevation: Number,
            editable: { type: Boolean, default: true },
            associated: {
                get: function() {
                    if ( !eventStage ) return false;
                    var aidStations = eventStage.data.eventModel.aidStations;
                    for ( var i = aidStations.length - 1; i >= 0; i-- ) {
                        if ( aidStations[i].splitId == this.id ) return true;
                    }
                    return false;
                }
            },
            // Course ID Polyfill
            course_id: { get: function() { return eventStage.data.eventModel.course ? eventStage.data.eventModel.course.id: null; } }
        },
        methods: {
            submit: function() {
                var self = this;
                if ( self.__new__ ) {
                    return self.post().then( function() {
                        return self.associate( true );
                    })
                } else {
                    return self.post();
                }
            },
            associate: function( associated ) {
                if ( this.associated !== associated ) {
                    if ( !eventStage.data.eventModel.__new__ ) {
                        if ( associated && !this.associated ) {
                            var station = api.create( 'aidStations', {
                                eventId: eventStage.data.eventModel.id,
                                splitId: this.id
                            } );
                            station.post().then( function() {
                                eventStage.data.eventModel.aidStations.push( station );
                            } );
                        } else if ( !associated && this.associated ) {
                            var aidStations = eventStage.data.eventModel.aidStations;
                            for ( var i = aidStations.length - 1; i >= 0; i-- ) {
                                if ( aidStations[i].splitId == this.id ) {
                                    aidStations[i].delete();
                                    aidStations.splice( i, 1 );
                                }
                            }
                        }
                    }
                }
            },
            validate: function() {
                if ( !this.baseName ) return false;
                if ( !this.nameExtensions ) return false;
                if ( !$.isNumeric( this.distanceFromStart ) ) return false;
                if ( !$.isNumeric( this.vertGainFromStart ) ) return false;
                if ( !$.isNumeric( this.vertLossFromStart ) ) return false;
                return true;
            }
        }
    } );
    api.define( 'efforts', {
        attributes: {
            firstName: String,
            lastName: String,
            personId: Number,
            bibNumber: String,
            fullName: String,
            gender: String,
            birthdate: String,
            phone: String,
            email: String,
            age: Number,
            city: String,
            stateCode: String,
            countryCode: String,
            beaconUrl: String,
            emergencyContact: String,
            emergencyPhone: String,
            concealed: { type: Boolean, default: true },
            startOffset: { type: Number, default: 0 },
            scheduledStartTime: {
                get: function() {
                    var virtualStartTime = eventStage.data.eventModel.virtualStartTime;
                    if ( virtualStartTime instanceof Date ) {
                        return moment( virtualStartTime ).add( (this.startOffset || 0), 'seconds' ).toDate();
                    } else {
                        return this.date;
                    }
                },
                set: function( value ) {
                    var virtualStartTime = eventStage.data.eventModel.virtualStartTime;
                    if ( virtualStartTime instanceof Date ) {
                        this.startOffset = moment( value ).diff( virtualStartTime, 'seconds' );
                    } else {
                        this.date = value;
                    }
                }
            },
            offsetTime: {
                get: function() {
                    if(this.startOffset === null) return '';

                    var sign = this.startOffset < 0 ? '-' : '+';
                    var hours = Math.floor( Math.abs( this.startOffset ) / 3600 );
                    var fill = hours < 10 ? '0' : '';
                    var hoursString = ( ( fill + hours ) );
                    var minutesString = ( ( "0" + Math.abs( this.startOffset / 60 % 60 ) ).slice( -2 ) );
                    return sign + hoursString + ":" + minutesString;
                },
                set: function( value ) {
                    var regex = /^([\-+]?)([0-9]*):([0-5]{0,2})$/;
                    var components = regex.exec(value) || [];
                    if(components.length < 1) {
                        this.startOffset = null;
                    } else {
                        var multiplier = components[1] === '-' ? -1 : 1;
                        var hoursComponent = components[2] || 0;
                        var minutesComponent = components[3] || 0;
                        this.startOffset = multiplier * ( hoursComponent * 3600 + minutesComponent * 60 );
                    }
                }
            },
            location: {
                get: function() {
                    var location = '';
                    if ( this.city ) {
                        location += this.city;
                    }
                    if ( this.stateCode ) {
                        location += ( location == '' ) ? '' : ', ';
                        location += ( ( locales.regions[ this.countryCode ] || {} )[ this.stateCode ] || this.stateCode );
                    }
                    if ( this.countryCode ) {
                        if ( location == '' || !this.stateCode ) {
                            location += ' ' + ( locales.countryNames[ this.countryCode ] || this.countryCode );
                        } else {
                            location += ' ' + this.countryCode;
                        }
                    }
                    return location;
                }
            },
            // Event ID Polyfill
            event_id: { get: function() { return eventStage.data.eventModel ? eventStage.data.eventModel.id: null; } }
        },
        methods: {
            afterCreate: function() { this.concealed = eventStage.data.eventModel.concealed; },
            validate: function() {
                if ( !this.firstName ) return false;
                if ( !this.lastName ) return false;
                if ( !this.gender ) return false;
                if ( !this.bibNumber ) return false;
                if ( !this.birthdate ) return false;
                return true;
            }
        }
    } );
    api.define( 'courses', {
        attributes: {
            name: String,
            description: String,
            editable: Boolean
        },
        relationships: {
            splits: ['splits']
        },
        methods: {
            normalize: function() {
                // Verify Existence of End Splits
                var start = this.endSplit( 'start' );
                if ( !( start instanceof api.Model ) ) {
                    var split = api.create( 'splits', { kind: 'start', baseName: 'Start', distanceFromStart: 0, vertGainFromStart: 0, vertLossFromStart: 0 } );
                    this.splits.push( split );
                }
                var finish = this.endSplit( 'finish' );
                if ( !( finish instanceof api.Model ) ) {
                    var split = api.create( 'splits', { kind: 'finish', baseName: 'Finish' } );
                    this.splits.push( split );
                }
                this.splits.sort( function( a, b ) {
                    return a.distanceFromStart - b.distanceFromStart;
                } );
            },
            afterCreate: function() { this.normalize(); },
            afterParse: function() { this.normalize(); },
            endSplit: function( kind ) {
                for ( var i = this.splits.length - 1; i >= 0; i-- ) {
                    if ( this.splits[i].kind === kind ) {
                        return this.splits[i];
                    }
                }
                return {};
            },
            validate: function() {
                return true;
            }
        },
        includes: [ 'splits' ],
    } );
    api.define( 'organizations', {
        attributes: {
            name: String,
            editable: { type: Boolean, default: true }
        },
        methods: {
            validate: function() {
                return true;
            }
        }
    } );
    api.define( 'events', {
        attributes: {
            name: { type: String, default: '' },
            shortName: { type: String, default: '' },
            concealed: { type: Boolean, default: true },
            laps: { type: Boolean, default: false },
            lapsRequired: { type: Number, default: 1 },
            virtualStartTime: { type: Date, default: null, local: true },
            startTimeInHomeZone: { 
                get: function() {
                    if (!(this.virtualStartTime instanceof Date)) return null;
                    var regex = new RegExp('Z$');
                    return moment(this.virtualStartTime).utcOffset(0, true).toISOString().replace(regex, '');
                },
                set: function(value) {
                    if (typeof value === 'string') {
                        var regex = new RegExp('[\\+\\- ][0-9][0-9]:[0-9][0-9]$');
                        this.virtualStartTime = moment(value.replace(regex,'')).toDate();
                    } else {
                        this.virtualStartTime = null;
                    }
                }
            },
            homeTimeZone: { type: String, default: 'Mountain Time (US & Canada)' },
            courseNew: Boolean
        },
        relationships: {
            efforts: ['efforts'],
            splits: ['splits'],
            aidStations: ['aidStations'],
            course: 'courses',
            eventGroup: 'eventGroups'
        },
        includes: [ 'course', 'course.splits', 'splits', 'efforts', 'aidStations', 'eventGroup', 'eventGroup.organization' ],
        methods: {
            afterCreate: function() {
                this.eventGroup = api.create('eventGroups');
            },
            normalize: function() {
                this.course.normalize();
                var newCourse = false || this.aidStations.length == 0;
                /* Remove Aid Stations for other Courses */
                for ( var i = this.aidStations.length - 1; i >= 0; i-- ) {
                    var splitId = this.aidStations[i].splitId;
                    if ( splitId === null ) break; // Unnecessary
                    for ( var j = this.course.splits.length - 1; j >= 0; j-- ) {
                        if ( this.course.splits[j].id == splitId ) break;
                    }
                    if ( j < 0 ) {
                        newCourse = true;
                        this.aidStations[i].delete();
                        this.aidStations.splice( i, 1 );
                    }
                }
                /* Attach Splits on a New Course*/
                if ( newCourse ) {
                    for ( var i = this.course.splits.length - 1; i >= 0; i-- ) {
                        var split = this.course.splits[i];
                        if ( split.__new__ ) {
                            split.post().then( function() { split.associate( true ); } );
                        } else if ( !split.associated ) {
                            split.associate( true );
                        }
                    }
                }
            },
            validate: function( context ) {
                var self = ( context ) ? context : this;
                if ( !self.name || self.name.length < 1 ) return false;
                if ( !self.eventGroup.organization || !self.eventGroup.organization.validate() ) return false;
                if ( !self.course || !self.course.validate() ) return false;

                if ( !self.virtualStartTime ) return false;
                return true;
            },
            jsonify: function () {
                var data = {
                    event: this.attributes(),
                    eventgroup: this.eventGroup.attributes(),
                    organization: this.eventGroup.organization.attributes(),
                    course: this.course.attributes(),
                    splits: [
                        this.course.endSplit( 'start' ),
                        this.course.endSplit( 'finish' ),
                    ]
                };
                data.course.splits_attributes = [
                    this.course.endSplit( 'start' ).attributes(),
                    this.course.endSplit( 'finish' ).attributes()
                ];
                return data;
            },
            post: function() {
                var self = this;
                var creating = this.__new__;
                return this.request( 'staging/' + (creating ? 'new' : this.id) + '/post_event_course_org', 'POST', 'application/json' )
                .then( function() {
                    if ( creating ) {
                        return self.visibility( false ).then( function() {
                            self.normalize();
                        });
                    } else {
                        self.normalize();
                    }
                });
            },
            visibility: function( visible ) {
                var self = this;
                return $.ajax( '/api/v1/staging/' + this.id + '/update_event_visibility', {
                    type: "PATCH",
                    data: { status: visible ? 'public' : 'private' },
                    dataType: "json"
                } ).then( function() {
                    return self.fetch();
                } ).fail( function( e ) {
                    if ( e.responseJSON && e.responseJSON.errors ) {
                        e.responseJSON.errors.forEach(error => {
                            $.notify({
                                title: error.title,
                                message: error.detail.messages.join(', ')
                            }, {
                                type: 'danger'
                            });
                        });
                    }
                } );
            }
        }
    } );
    api.define( 'users', {
        attributes: {
            email: String,
            firstName: String,
            lastName: String,
            prefDistanceUnit: { type: String, default: 'kilometers' },
            prefElevationUnit: { type: String, default: 'meters' }
        }
    } );
    api.define( 'aidStations', {
        url: 'aid_stations',
        attributes: {
            eventId: Number,
            splitId: Number,
            status: String
        }
    } );
    api.define( 'eventGroups', {
        url: 'event_groups',
        attributes: {
            name: String,
        },
        includes: [ 'events', 'events.efforts', 'events.splits' ],
        relationships: {
            events: ['events'],
            organization: 'organizations',
        }
    });

    /**
     * UI object for the live event view
     *
     */
    var eventStage = {

        router: null,
        app: null,
        data: {
            isDirty: false,
            isReady: false,
            isStaged: false,
            eventModel: api.create( 'events' )
        },

        /**
         * This method is used to populate the locale array
         */
        ajaxPopulateLocale: function() {
            $.when(
                $.get( '/api/v1/staging/get_countries', function( response ) {
                    for ( var i in response.countries ) {
                        locales.countries.push( { code: response.countries[i].code, name: response.countries[i].name } );
                        locales.countryNames[ response.countries[i].code ] = response.countries[i].name;
                        if ( $.isEmptyObject( response.countries[i].subregions ) ) continue;
                        locales.regions[ response.countries[i].code ] = response.countries[i].subregions;
                    }               
                } ),
                $.get( '/api/v1/staging/get_time_zones', function( response ) {
                    for ( var i in response.time_zones ) {
                        locales.timeZones.push( { name: response.time_zones[i][0], offset: response.time_zones[i][1]} );
                    }
                } )
            ).fail( function() {
                $.notify({
                    title: 'Failed to Load Locale Data:',
                    message: 'Please try reloading the app.'
                }, {
                    type: 'danger'
                });
            } );
        },

        ajaxPopulateUnits: function() {
            return api.find( 'users', 'current' ).always( function( model ) {
                units.distance = model.prefDistanceUnit;
                units.elevation = model.prefElevationUnit;
            } ).fail( function() {
                $.notify({
                    title: 'Failed to Load User Data:',
                    message: 'Please try reloading the app.'
                }, {
                    type: 'danger'
                });
            } );
        },

        isEventValid: function( eventData ) {
            if ( ! eventData.eventGroup.organization.name ) return false;
            if ( ! eventData.event.name ) return false;
            if ( ! eventData.course.name ) return false;
            return true;
        },

        onRouteChange: function( to, from, next ) {
            if ( to.name === 'publish' ) {
                if ( from.name !== 'confirm' ) {
                    next( false );
                } else {
                    eventStage.data.eventModel.visibility( true )
                        .done( function() {
                            next();
                        } ).fail( function() {
                            next( false );
                        } );
                }
            } else if ( from.name === 'home' ) {
                var creating = eventStage.data.eventModel.__new__;
                eventStage.data.eventModel.post().done( function() {
                    next();
                    if (creating) {
                        var id = eventStage.data.eventModel.id;
                        var url = window.location.pathname.replace(/\/new\//, '/' + id + '/') + window.location.hash;
                        window.location.href = window.location.origin + url;
                    }
                } ).fail( function( e ) {
                    next( '/' );
                } );
            } else {
                eventStage.data.eventModel.fetch().always( function() {
                    if ( !eventStage.data.eventModel.id && to.name !== 'home' ) {
                        next( '/' );
                    } else {
                        next();
                    }
                } );
            }
        },

        /**
         * This kicks off the full UI
         *
         */
        init: function () {

            // Initialize Custom Components
            this.googleMaps.init();
            this.dataTables.init();
            this.editModal.init();
            this.inputMask.init();
            this.datetime.init();
            this.prefill.init();
            this.confirm.init();
            this.promise.init();
            this.resourceSelect.init();
            this.ajaxImport.init();
            this.inputUnits.init();
            this.errorAlert.init();

            // Load Event ID
            var eventId = $( '#event-app' ).data( 'id' );
            this.data.eventModel.id = !eventId ? null : eventId;
            this.ajaxPopulateLocale();
            this.ajaxPopulateUnits();

            // Initialize Vue Router and Vue App
            const routes = [
                { 
                    path: '/',
                    name: 'home',
                    component: {
                        props: ['eventModel'],
                        methods: {
                            isEventValid: function() {
                                return this.eventModel.validate();
                            },
                            suggestedName: function() {
                                if (this.eventModel.eventGroup.organization && this.eventModel.virtualStartTime) {
                                    return this.eventModel.virtualStartTime.getFullYear() + ' ' + this.eventModel.eventGroup.organization.name;
                                }
                                return '';
                            },
                            newOrganization: function() {
                                return api.create( 'organizations' );
                            },
                            newCourse: function() {
                                return api.create( 'courses' );
                            }
                        },
                        data: function() { return { units: units, timeZones: locales.timeZones } },
                        template: '#event'
                    },
                    beforeEnter: this.onRouteChange
                },
                { 
                    path: '/splits', 
                    component: {
                        props: ['eventModel'],
                        methods: {
                            blank: function() {
                                return api.create( 'splits' );
                            }
                        },
                        data: function() { return { modalData: {}, filter: '', units: units, highlight: null } },
                        template: '#splits'
                    },
                    beforeEnter: this.onRouteChange
                },
                { 
                    path: '/entrants', 
                    component: { 
                        props: ['eventModel'], 
                        methods: {
                            blank: function() {
                                var effort = api.create( 'efforts' )
                                return effort;
                            },
                            saveEffort: function() {
                                if ( !this.modalData._dtid ) {
                                    this.eventModel.efforts.push( this.modalData );
                                }
                            }
                        },
                        data: function() { return { 
                            countries: locales.countries,
                            regions: locales.regions,
                            units: units,
                            modalData: {},
                            filter: ''
                        } }, 
                        template: '#entrants'
                    },
                    beforeEnter: this.onRouteChange
                },
                { 
                    path: '/confirmation', 
                    name: 'confirm',
                    component: {
                        props: ['eventModel'], 
                        data: function() { return { units: units } },
                        template: '#confirmation'
                    },
                    beforeEnter: this.onRouteChange
                },
                { 
                    path: '/published',
                    name: 'publish',
                    component: {
                        props: ['eventModel'], 
                        data: function() { return { units: units } },
                        template: '#published'
                    },
                    beforeEnter: this.onRouteChange
                }
            ];
            var router = new VueRouter( {
                routes: routes
            } );
            router.afterEach( function( to, from ) {
                eventStage.data.isReady = true;
            } );
            eventStage.router = router;
            eventStage.app = new Vue( {
                router: router,
                el: '#event-app',
                data: eventStage.data,
                watch: {
                    eventData: {
                        handler: function() {
                            var self = this;
                            if ( !this.isStaged ) return;
                            this.isDirty = true;
                            if ( this._autosave ) {
                                clearTimeout( this._autosave );
                            }                            
                            this._autosave = setTimeout( function() {                                
                                self._autosave = null;
                            }, 60000 );
                        },
                        deep: true
                    }
                }
            });
            router.afterEach( function( a, b, c ) {
                eventStage.app.$nextTick( function() {
                    $( eventStage.app.$el ).trigger( 'vue-ready' );
                } );
            } );
        },

        /**
         *  Vue.js Data Tables Integration
         *  
         *  A component to connect the mighty Vuejs to the strange and mysterious
         *  DataTables library. Instead of passing static rows, generated Vue elements
         *  are sent to DataTables which allows item specific update and rendering
         *  while still letting DataTables handle sorting and filtering.
         */
        dataTables: {
            uniqueId: 1,
            onDataChange: function() {
                if ( !this.rows || !$.isArray( this.rows ) ) return;                
                var self = this;
                this._cache = this._cache || [];
                var cache = [];
                this.rows.forEach( function( obj, index ) {
                    if ( !obj._dtid ) {
                        // New Data: Add Index and Add to Table
                        obj._dtid = eventStage.dataTables.uniqueId++;
                        var row = new self._row( { data: { row: obj } } ).$mount();
                        cache[ obj._dtid ] = row;
                        row.$on( 'remove', function() {
                            self._table.row( this.$el ).remove().draw();
                            this.$destroy( true );
                            for ( var i = self.rows.length - 1; i >= 0; i-- ) {
                                if ( self.rows[i]._dtid === obj._dtid ) {
                                    self.rows.splice( i, 1 );
                                    break;
                                }
                            }
                        } );
                        row.$on( 'edit', function() {
                            self.$emit( 'edit', this.row );
                        } );

                        self._table.row.add( row.$el )
                    }
                    // Remove row from old cache
                    delete self._cache[ obj._dtid ];
                } );
                // Remove Old and Unused Data
                this._cache.forEach( function( obj, index ) {
                    obj.$emit( 'remove' );
                } );
                this._cache = cache;
                this._table.draw();
            },
            onFilterChange: function() {
                this._table.search( this.filter ).draw();
            },
            onEntriesChange: function() {
                this._table.page.len( this.entries );
            },
            onDestroyed: function() {
                // Erase DataTable IDs
                if ( $.isArray( this.rows ) ) {
                    this.rows.forEach( function( obj, index ) {
                        obj._dtid = null;
                    } );
                }
            },
            onMounted: function() {
                this._queue = [];
                // Find Default Sort Settings
                var order = [];
                $( 'th:visible', this.$el ).each( function( i, el ) {
                    if ( $( el ).data( 'order' ) ) {
                        order.push( [ $( el ).index(), $( el ).data( 'order' ) ] );
                    }
                } );
                this._table = $( this.$el ).DataTable( {
                    pageLength: this.entries,
                    order: order,
                    dom:    "<'row'<'col-sm-12'tr>><'row'<'col-sm-5'i><'col-sm-7'p>>",
                    autoWidth: false
                } );
                // Create render Function for Table Rows
                var self = this;
                this._row = Vue.extend( {
                    parent: self,
                    render: function( createElement ) {
                        var vnode = self.$scopedSlots.row.call( this, this );
                        if ( vnode.length == 1 && vnode[0].tag === 'tr' ) {
                            return vnode[0];
                        } else {
                            return createElement( 'tr', {}, vnode );
                        }
                    },
                    watch: {
                        row: { 
                            handler: _.debounce( function() {                                
                                this.$nextTick( function() {
                                    self._table.row( this.$el ).invalidate( 'dom' ).draw();
                                } );
                            }, 1000 ),
                            deep: true
                        }
                    }
                } );
                eventStage.dataTables.onDataChange.call( this );
                $( this.$el ).on( 'mouseover', '[data-toggle="tooltip"]', function() {
                    $( this ).tooltip( 'show' );
                } );
            },
            init: function() {
                Vue.component( 'data-tables', {
                    template: '<table class="table table-striped" width="100%">\
                                    <thead><slot name="header"></slot></thead>\
                                    <tbody v-on:mouseleave="$emit(\'mouseleave\')"><slot></slot></tbody>\
                                </table>',
                    props: [ 'rows', 'entries', 'filter' ],
                    mounted: eventStage.dataTables.onMounted,
                    destroyed: eventStage.dataTables.onDestroyed,
                    data: function() { return { row: {} } },
                    watch: {
                        rows: eventStage.dataTables.onDataChange,
                        filter: eventStage.dataTables.onFilterChange
                    }
                } );
            }
        },

        /**
         *  Vue.js Google Maps Integration
         *  
         *  A component to manage a google map using the provided data models.
         *  Specifically, this component is designed to allow displaying, 
         *  selecting, and modifying markers for a continuous path.
         */

        googleMaps: ( function() {
            var uniqueId = 1;

            // Default Map Bounds
            var defaultBounds = null;
            document.addEventListener("turbolinks:load", function() {
                defaultBounds = new google.maps.LatLngBounds(
                    { lat: 24.846, lng: -126.826 },
                    { lat: 49.038, lng: -65.478 }
                );
            } );

            function onValueChange() {
                var self = this;
                if ( this.value ) {
                    var lastValue = this._lastValue || { lat: 0, lng: 0 };
                    var latlng = { lat: parseFloat( this.value.latitude ), lng: parseFloat( this.value.longitude ) };
                    if ( lastValue.lat != latlng.lat || lastValue.lng != latlng.lng ) {
                        this._lastValue = latlng;
                        if ( isNaN( latlng.lat ) || isNaN( latlng.lng ) ) {
                            this._location && this._location.setMap( null );
                        } else if ( !this._location ) {
                            // Make new location marker
                            this._location = new google.maps.Marker( {
                                position: latlng,
                                icon: {
                                    url: window._rails_assets.marker
                                },
                                map: this._map,
                                title: this.value.name,
                                draggable: true,
                                zIndex: google.maps.Marker.MAX_ZINDEX + 1
                            } );
                            var self = this;
                            this._location.addListener( 'dragend', function( e ) {
                                var latlng = self._location.getPosition();
                                updateValue.call( self, latlng.lat(), latlng.lng() );
                            } );
                        } else {
                            this._location.setMap( this._map );
                            this._location.setPosition( latlng );
                        }
                    }
                    if ( this.editable !== undefined ) {
                        onRouteChange.call( this );
                    }
                } else if ( this._location ) {
                    this._location.setMap( null );
                    this._lastValue = { lat: 0, lng: 0 };
                }
            }

            function onRouteChange() {
                if ( this.route ) {
                    this._route = this._route || {};
                    // Destroy existing polyline
                    if ( this._polyline ) {
                        this._polyline.setMap( null );
                    }
                    var value = this.value || {}; // Empty object allows following statement to fail safely.
                    if ( isNaN( parseFloat( value.latitude ) ) || isNaN( parseFloat( value.longitude ) ) ) {
                        value = null;
                    }
                    // Build new route
                    var path = [];
                    var gmids = [];
                    var bounds = new google.maps.LatLngBounds();
                    // Enforce a Sorted Array
                    e = this.route.slice(0).sort( function( a, b ) {
                        return a.distanceFromStart - b.distanceFromStart;
                    } );
                    for ( var i = 0; i < e.length; i++ ) {
                        if ( value ) {
                            if ( value._gmid == e[i]._gmid ) {
                                value = null;
                            } else if ( e[i].distanceFromStart > value.distanceFromStart ) {
                                // Inject Value into Polyline
                                path.push( { lat: parseFloat( value.latitude ) , lng: parseFloat( value.longitude ) } );
                                value = null;
                            }
                        }
                        if ( isNaN( parseFloat( e[i].latitude ) ) || isNaN( parseFloat( e[i].longitude ) ) ) continue;
                        var latlng = { lat: parseFloat( e[i].latitude ) , lng: parseFloat( e[i].longitude ) };
                        bounds.extend( latlng );
                        if ( e[i].associated ) path.push( latlng );
                        // Make Marker
                        var marker = null;
                        if ( !e[i]._gmid || !this._route[ e[i]._gmid ] ) {
                            if ( !e[i]._gmid ) {
                                e[i]._gmid = uniqueId++;
                            }
                            marker = new google.maps.Marker( {
                                map: this._map,
                                zIndex: google.maps.Marker.MAX_ZINDEX - 1
                            } );
                            marker._data = e[i];
                            this._route[ e[i]._gmid ] = marker;
                        } else {
                            marker = this._route[ e[i]._gmid ];
                        }
                        var icon;
                        switch( e[i].kind ) {
                            case 'start':
                                icon = window._rails_assets.dotGreen;
                                break;
                            case 'finish':
                                icon = window._rails_assets.dotCheckered;
                                break;
                            default:
                                icon = window._rails_assets.dotBlue;
                        }
                        // Update Marker
                        marker.setIcon( {
                            url: icon,
                            labelOrigin: new google.maps.Point( 12, 14 ),
                            anchor: new google.maps.Point( 16, 16 )
                        } );
                        marker.setPosition( latlng );
                        marker.setOpacity( e[i].associated ? 1.0 : 0.5 );
                        // Update Cache
                        gmids.push( e[i]._gmid );
                    }
                    // Append Value to Polyline
                    if ( value ) {
                        path.push( { lat: parseFloat( value.latitude ) , lng: parseFloat( value.longitude ) } );
                    }
                    // Remove Unused Markers
                    for ( var _gmid in this._route ) {
                        if ( gmids.indexOf( parseInt( _gmid ) ) === -1 ) {
                            this._route[ _gmid ].setMap( null );
                            delete this._route[ _gmid ];
                        } 
                    }
                    if ( path.length >= 1 ) {
                        // Append polyline to map
                        this._polyline = new google.maps.Polyline( {
                            path: path,
                            map: this._map,
                            geodesic: true,
                            strokeColor: '#2A9FD8',
                            strokeOpacity: 1.0,
                            strokeWeight: 4
                        } );
                        this._routeBounds = bounds;
                    } else {
                        this._routeBounds = null;
                    }
                    // Reset bounds when map is fitted
                    if ( this.fit !== undefined ) {
                        this._map.fitBounds( this._routeBounds || defaultBounds );
                    }
                }
            }

            function onBoundsChange() {
                var self = this;
                if ( this.searchUrl ) {
                    this._search = this._search || {};
                    var bounds = this._map.getBounds().toJSON();
                    $.ajax( this.searchUrl, {
                        dataType: 'json',
                        data: bounds
                    } ).done( function( result ) {
                        var splits = api.parse( result );
                        var ids = [];
                        for ( var i = splits.length - 1; i >= 0; i-- ) {
                            var latlng = {
                                lat: parseFloat( splits[i].latitude ),
                                lng: parseFloat( splits[i].longitude )
                            };
                            if ( isNaN( latlng.lat ) || isNaN( latlng.lng ) ) continue;
                            if ( !splits[i].id ) continue;
                            splits[i].id = parseInt( splits[i].id );
                            if ( self._search[ splits[i].id ] === undefined ) {
                                marker = new google.maps.Marker( {
                                    position: latlng,
                                    map: self._map,
                                    icon: {
                                        url: window._rails_assets.dotLBlue,
                                        labelOrigin: new google.maps.Point( 12, 14 ),
                                        anchor: new google.maps.Point( 16, 16 )
                                    },
                                    title: splits[i].name,
                                    zIndex: google.maps.Marker.MAX_ZINDEX - 10
                                } );
                                marker._data = splits[i];
                                marker.addListener( 'click', onMarkerClick.bind( self, marker ) );
                                self._search[ splits[i].id ] = marker;
                            }
                            ids.push( splits[i].id );
                        }
                        // Remove Unused Markers
                        for ( var id in self._search ) {
                            if ( ids.indexOf( parseInt( id ) ) === -1 ) {
                                self._search[ id ].setMap( null );
                                delete self._search[ id ];
                            }  
                        }
                    } ).fail( function() {
                        console.error( 'Google Maps', 'Failed to Search Bounds' );
                    } );
                }
            }

            function fetchElevation() {
                var self = this;
                if ( !this.value ) return;
                var latlng = { lat: parseFloat( this.value.latitude ), lng: parseFloat( this.value.longitude ) };
                this._elevator.getElevationForLocations( {
                    locations: [ latlng ]
                }, function( results, status ) {
                    if ( status === 'OK' && results[0] ) {
                        self.value.elevation = results[0].elevation;
                    } else {
                        console.error( 'Google Maps', 'Failed to Fetch Elevation' );
                    }
                } );
            }

            function updateValue( lat, lng ) {
                if ( this.editable == undefined ) return;
                var latlng = { lat: parseFloat( lat ), lng: parseFloat( lng ) };
                if ( isNaN( latlng.lat ) || isNaN( latlng.lng ) ) return;
                if ( !this.value ) return;
                this.value.latitude = latlng.lat;
                this.value.longitude = latlng.lng;
                fetchElevation.call( this );
                this.$emit( 'input', this.value );
            }

            function onMarkerClick( marker ) {
                var node = $( this._infowindow.getContent() );
                node.find( 'h5' ).html( marker._data.baseName );
                node.find( 'p' ).html( marker._data.courseName || '<i>No Course</i>' );
                node.data( 'location', marker._data );
                this._infowindow.open( this._map, marker );
            }

            function onMapClick( e ) {
                updateValue.call( this, e.latLng.lat(), e.latLng.lng() );
            }

            function onMounted() {
                var self = this;
                this._search = {};
                this._polyline = null;
                // Construct Google Maps Objects
                this._elevator = new google.maps.ElevationService();
                this._map = new google.maps.Map( this.$el, {
                    center: defaultBounds.getCenter(),
                    mapTypeId: 'terrain',
                    zoom: 4,
                    maxZoom: 24,
                    draggableCursor: ( this.editable == undefined ) ? null : 'crosshair',
                    zoomControl: this.locked == undefined,
                    draggable: this.locked == undefined,
                    scrollwheel: this.locked == undefined,
                    streetViewControl: false,
                    scaleControl: this.locked == undefined,
                    disableDoubleClickZoom: this.locked != undefined,
                    gestureHandling: ( this.locked == undefined ) ? 'auto' : 'none'
                } );
                // Attach Listeners
                this._map.addListener( 'click', onMapClick.bind( self ) );
                this._map.addListener( 'bounds_changed', _.debounce( onBoundsChange.bind( this ), 500 ) );
                // Construct Info Window
                var node = $( '<div></div>' );
                node.append( '<h5><i>No Title</i></h5>' );
                node.append( '<p><i>No Description</i></p>' );
                node.append( '<a class="js-clone btn-sm btn btn-primary">Clone Location</a>' );
                node.on( 'click', '.js-clone', function() {
                    self._infowindow.close();
                    updateValue.call( self, node.data( 'location' ).latitude, node.data( 'location' ).longitude );
                } );
                this._infowindow = new google.maps.InfoWindow( {
                    content: node[0]
                } );
                // Google Maps in Modal Fix
                $( this.$el ).closest( '.modal' ).on( 'shown.bs.modal', function() {
                    google.maps.event.trigger( self._map, 'resize' );
                    self._map.fitBounds( self._routeBounds || defaultBounds );
                } );
                onRouteChange.call( self );
                onValueChange.call( self );
            }

            return {
                init: function() {
                    Vue.component( 'google-map', {
                        template: '<div class="splits-modal-map-wrap js-google-maps"></div>',
                        props: {
                            locked: {},
                            fit: {},
                            editable: {},
                            searchUrl: { type: String, default: null },
                            route: { type: Array, default: null },
                            value: { type: Object, default: null }
                        },
                        mounted: onMounted,
                        watch: {
                            route: {
                                handler: onRouteChange,
                                deep: true
                            },
                            'value': onValueChange,
                            'value.latitude': onValueChange,
                            'value.longitude': onValueChange,
                            'value.distanceFromStart': onValueChange
                        }
                    } );
                }
            }
        } )(),

        /**
         *  Editing Modal Component
         *  
         *  Allows a bootstrap modal to be used to conditionally edit the v-model
         *  object. Before opening the model, a local copy of the provided object
         *  is made and sent to the inline-template in the component instantiation.
         *  The original object is not modified until a 'done' event is sent by
         *  the modal template. 
         *
         *  Note: Child objects in the v-model that are object references will 
         *  not be preserved. A new copy of all child objects is made when the modal
         *  opens, and any object references are replaced when the 'done' event 
         *  occurs.
         */
         editModal: {
            init: function() {
                Vue.component( 'edit-modal', {
                    template: '<div>No Template</div>',
                    props: {
                        value: { required: true },
                        extra: { default: function() { return {} } },
                    },
                    watch: {
                        model: {
                            handler: function( model ) {
                                this.invalid = !( model.validate && model.validate() )
                            },
                            deep: true
                        }
                    },
                    mounted: function() {
                        var self = this;
                        var reset = function() {
                            // Locally clone existing object
                            setTimeout(function(){
                                self.model = self.value;
                                if ( self.model ) self.model.fetch();
                                self.error = null;
                            });
                        };
                        $( this.$el ).on( 'show.bs.modal hide.bs.modal', reset );
                        this.$on( 'cancel', reset );
                        this.$on( 'done', function() {
                            self.$emit( 'change' );
                            $( this.$el ).modal( 'hide' );
                        } );
                        $( this.$el ).on( 'shown.bs.modal' , function() {
                            $( '[autofocus]', this.$el ).focus();
                        } );
                    },
                    data: function() {
                        return {
                            countries: locales.countries,
                            regions: locales.regions,
                            units: units,
                            model: {},
                            invalid: true,
                            error: null
                        };
                    }
                } );
            }
         },

        inputMask: {
            init: function() {
                Vue.directive( 'mask', {
                    bind: function( el, binding ) {
                        var update = function( e ) {
                            /*
                             * BruceLampson on Dec 31, 2016
                             * https://github.com/RobinHerbots/Inputmask/issues/1468
                             */
                            var event = document.createEvent( 'HTMLEvents' );
                            event.initEvent( 'input', true, true );
                            e.currentTarget.dispatchEvent( event );
                            $( this ).trigger( 'change' );
                        };
                        var options = {
                            placeholder: $( el ).attr( 'placeholder' ) || undefined,
                            insertMode: binding.modifiers.insert || false,
                            rightAlign: binding.modifiers.right || false,
                            clearIncomplete: true,
                            clearMaskOnLostFocus: true,
                            oncomplete: update,
                            onincomplete: update,
                            oncleared: update
                        };
                        if ( ! $.isPlainObject( binding.value ) )
                            binding.value = { mask: binding.value };
                        $.extend( options, binding.value );
                        $( el ).inputmask( options );
                    }
                } );
            }
        },

        datetime: {
            init: function() {
                Vue.component( 'input-datetime', {
                    template: '<div class="row">\
                        <div class="col-6">\
                            <div class="input-group">\
                                <input type="text" class="js-date form-control"/>\
                                <span class="input-group-append">\
                                    <span class="input-group-text fa fa-calendar"></span>\
                                </span>\
                            </div>\
                        </div>\
                        <div class="col-6">\
                            <div class="input-group">\
                                <input type="text" class="js-time form-control"/>\
                                <span class="input-group-append">\
                                    <span class="input-group-text fa fa-clock-o"></span>\
                                </span>\
                            </div>\
                        </div>\
                    </div>',
                    props: {
                        value: { required: true, default: null }
                    },
                    mounted: function() {
                        // Shared Variables
                        var self = this;
                        var datestamp = null;
                        var timestamp = null;
                        // Mount Value Watcher
                        this.$watch( 'value', function() {
                            if ( this.value instanceof Date ) {
                                date = moment( this.value );
                                datestamp = date.format( 'MM/DD/YYYY' );
                                timestamp = date.format( 'hh:mm a' );
                            } else {
                                // Enforce Default Values
                                datestamp = null;
                                timestamp = '06:00 am';
                                self.$emit( 'input', null );
                            }
                            $( '.js-date', this.$el ).val( datestamp );
                            $( '.js-time', this.$el ).val( timestamp );
                        }, { immediate: true } );
                        // Prepare Transform Function
                        function update() {
                            if ( datestamp == null || timestamp == null ) return;
                            date = moment( datestamp + ' ' + timestamp, 'MM/DD/YYYY hh:mm a' );
                            self.$emit( 'input', date.toDate() );
                        }
                        // Mount Datepickers
                        $( '.js-date', this.$el )
                            .datetimepicker( {
                                format: 'MM/DD/YYYY'
                            } )
                            .on( 'dp.change', function( e ) {
                                datestamp = e.date.format( 'MM/DD/YYYY' );
                                update();
                            } );
                        $( '.js-time', this.$el )
                            .datetimepicker( {
                                format: 'hh:mm a'
                            } )
                            .on( 'dp.change', function( e ) {
                                timestamp = e.date.format( 'hh:mm a' );
                                update();
                            } );
                    }
                } );

                Vue.component( 'input-date', {
                    template: '<div class="input-group">\
                                    <input type="text" class="js-date form-control"/>\
                                    <span class="input-group-addon">\
                                        <span class="glyphicon glyphicon-calendar"></span>\
                                    </span>\
                               </div>',
                    props: {
                        value: { required: true, default: null }
                    },
                    mounted: function() {
                        // Shared Variables
                        var self = this;
                        var datestamp = null;
                        // Mount Value Watcher
                        this.$watch( 'value', function() {
                            if ( this.value ) {
                                date = moment( this.value );
                                datestamp = date.format( 'MM/DD/YYYY' );
                            } else {
                                // Enforce Default Values
                                datestamp = null;
                                self.$emit( 'input', null );
                            }
                            $( '.js-date', this.$el ).val( datestamp );
                        }, { immediate: true } );
                        // Mount Datepicker
                        $( '.js-date', this.$el )
                            .datetimepicker( {
                                format: 'MM/DD/YYYY',
                                viewMode: 'years',
                                defaultDate: '1980-01-01'
                            } )
                            .on( 'dp.change', function( e ) {
                                self.$emit( 'input', e.date.format( 'YYYY-MM-DD' ) );
                            } );
                    }
                } );
            }
        },

        /**
         *  Prefill Directive
         *
         *  The value passed to this directive will be applied to its input 
         *  element until the input is changed manually. The prefill will stay
         *  deactivated until the input is emptied.
         */
        prefill: {
            init: function() {
                Vue.directive( 'prefill', {
                    update: function( el, binding ) {
                        var update = function( el ) {
                            /*
                             * BruceLampson on Dec 31, 2016
                             * https://github.com/RobinHerbots/Inputmask/issues/1468
                             */
                            var event = document.createEvent( 'HTMLEvents' );
                            event.initEvent( 'input', true, true );
                            el.dispatchEvent( event );
                            $( el ).trigger( 'change' );
                        };
                        if ( binding.value !== binding.oldValue ) {
                            if ( !$( el ).val() || $( el ).val() == binding.oldValue ) {
                                $( el ).val( binding.value );
                                update( el );
                            }
                        }
                    }
                } );
            }
        },

        confirm: {
            init: function() {
                Vue.directive( 'confirm', {
                    update: function( el, binding ) {
                        var $el = $( el );
                        $el.data( 'v-confirm' )[ binding.arg ] = binding.value;
                    },
                    bind: function( el, binding, vnode, c ) {
                        var $el = $( el );
                        $el.data( 'v-confirm', {} );
                        binding.def.update( el, binding );
                        // Native Event Helper
                        function fireEvent( name ) {
                            return function( response ) {
                                var event = document.createEvent( 'HTMLEvents' );
                                event.initEvent( name, true, true );
                                event.data = response;
                                el.dispatchEvent( event );
                            }
                        }
                        // Bind requested event
                        $el.on( binding.arg, function( $event ) {
                            // Prevent Any Defaults
                            $event.preventDefault();
                            $event.stopPropagation();
                            // Fire on next tick to allow data to update completely
                            Vue.nextTick( function() {
                                // Generate Button
                                var button = $( '<p></p><button class="btn btn-danger">Confirm</button>' );
                                button.filter( 'p' )
                                    .text( $el.data( 'v-confirm' )[ binding.arg ] )
                                    .css( 'max-width', '150px' );
                                button.filter( 'button' )
                                    .css( 'margin', '0 auto' )
                                    .css( 'display', 'block' )
                                    .one( 'click', fireEvent( 'confirm' ) );
                                // Generate Popover
                                $el.popover( {
                                    trigger: 'manual',
                                    container: 'body',
                                    placement: 'left',
                                    content: button,
                                    html: true
                                } );
                                $el.popover( 'show' );
                                // Hide on next click
                                $( document ).one( 'click', $el.popover.bind( $el, 'destroy' ) );
                            } );
                        } );
                    }
                } );
            }
        },

        /**
         *  Promise Directive
         *
         *  The promise directive will call the passed function when the specified event occurs.
         *  If the function returns a Promise, 'done', 'fail', and 'always' events will be fired
         *  on the element when the promise either resolves or is rejected.
         *
         *  NOTE: Limitations occasionally prevent the correct context from passing to the directive.
         *  To specify context for the function, the passed value must be an array of length two 
         *  where the first element is the function, and the second element is the context.
         */
        promise: {
            init: function() {
                Vue.directive( 'promise', {
                    update: function( el, binding ) {
                        var fn = binding.value;
                        if ( $.isArray( fn ) && fn.length === 2 ) {
                            if ( $.isFunction( fn[0] ) && !$.isFunction( fn[1] ) ) {
                                var target = fn[0];
                                var context = fn[1];
                                fn = function() { return target.call( context ) }
                            }
                        }
                        if ( !$.isFunction( fn ) ) return;
                        $( el ).data( 'v-promise' )[ binding.arg ] = fn;
                    },
                    bind: function( el, binding, vnode, c ) {
                        var $el = $( el );
                        $el.data( 'v-promise', {} );
                        binding.def.update( el, binding );
                        // Native Event Helper
                        function fireEvent( name ) {
                            return function( response ) {
                                var event = document.createEvent( 'HTMLEvents' );
                                event.initEvent( name, true, true );
                                event.data = response;
                                el.dispatchEvent( event );
                            }
                        }
                        // Bind requested event
                        $el.on( binding.arg, function( $event ) {
                            // Prevent Any Defaults
                            $event.preventDefault();
                            $event.stopPropagation();
                            // Fire on next tick to allow data to update completely
                            Vue.nextTick( function() {
                                // Fire Function
                                var promise = $el.data( 'v-promise' )[ binding.arg ]();

                                try {
                                    promise.done( fireEvent( 'done' ) );
                                    promise.fail( fireEvent( 'fail' ) );
                                    promise.always( fireEvent( 'always' ) );
                                } catch( err ) {
                                    console.error( 'v-promise Functions Must Return a Promise!' );
                                }
                            } );
                        } );
                    } 
                } );
            }
        },

        /**
         *  Resource Select Component
         *
         *  Contacts the provided endpoint to retrieve it's values. Surround the component
         *  with <keep-alive> to prevent the component from requesting data from the server 
         *  again. Additional data to be sent to the server can be sent using the data property.
         */
        resourceSelect: {
            onMounted: function() {
                var data = $.extend( {}, this.data );
                var self = this;

                // Fetch New Entries
                api.all( self.source ).done( function( data ) {
                    self.ajaxed = data;
                    // Force update after list is rendered
                    self.$nextTick( function() {
                        self.$forceUpdate();
                    } );
                } );
            },
            init: function() {
                Vue.component( 'resource-select', {
                    props: {
                        data: { type: Object, default: function() { return {} } },
                        source: { type: String, required: true, default: '' },
                        value: { default: {} }
                    },
                    computed: {
                        id: { 
                            get: function() {
                                return ( this.value ) ? this.value.id : null;
                            },
                            set: function( id ) {
                                var model = null;
                                for ( var i = this.ajaxed.length - 1; i >= 0; i-- ) {
                                    if ( this.ajaxed[i].id == id ) {
                                        model = this.ajaxed[i];
                                    }
                                }
                                if ( model !== null ) {
                                    this.$emit( 'input', model );
                                }
                            }
                        }
                    },
                    data: function() { return { ajaxed: null } },
                    template: 
                        '<select v-model="id" :disabled="!ajaxed || ajaxed.length <= 0">\
                            <slot></slot>\
                            <option v-if="ajaxed === null && id !== null" :value="id">{{ value.name }}</option>\
                            <option v-else v-for="obj in ajaxed" :value="obj.id">{{ obj.name }}</option>\
                        </select>',
                    mounted: eventStage.resourceSelect.onMounted
                } );
            }
        },

        /**
         *
         */
        ajaxImport: {
            onMounted: function() {
                var self = this;
                $( 'input', this.$el ).fileupload({
                    dataType: 'json',
                    url: this.url,
                    submit: function (e, data) {
                        self.busy = true;
                    },
                    done: function (e, data) {
                        self.$emit( 'import', 'yay' );
                    },
                    fail: function (e, data, a,b) {
                        self.error = true;
                        setTimeout( function() {
                            self.error = false;
                        }, 500 );
                        if ( data.jqXHR.responseJSON && data.jqXHR.responseJSON.errors ) {
                            var errors = data.jqXHR.responseJSON.errors;
                            for ( var i = 0; i < errors.length; i++ ) {
                                errors[i].dump = errors[i].detail.attributes;
                                $.notify({
                                    title: errors[i].title,
                                    message: errors[i].detail.messages.join(', ')
                                }, {
                                    type: 'danger'
                                });
                            }
                        } else {
                            $.notify({
                                title: 'Failed to Upload File',
                                message: 'Unknown Server Error'
                            }, {
                                type: 'danger'
                            });
                        }
                    },
                    always: function () {
                        self.busy = false;
                    }
                });
            },
            init: function() {
                Vue.component( 'ajax-import', {
                    template:   '<a class="fileinput-button" v-bind:class="{ \'btn-danger\': error }" :disabled="busy || error">\
                                    <slot></slot>\
                                    <input type="file" name="file"/>\
                                </a>',
                    props: {
                        url: { type: String, required: true, default: '' }
                    },
                    data: function() { return { busy: false, error: false } },
                    mounted: eventStage.ajaxImport.onMounted
                } );
            }
        },

        errorAlert: ( function() {
            return {
                init: function() {
                    Vue.component( 'error-alert', {
                        template: '<div class="alert alert-danger" role="alert" v-if="errors && errors.length > 0">\
                            <template v-for="error in errors" v-if="typeof error == \'object\'">\
                                <strong>{{ error.title }}</strong> {{ error.details }}\
                            </template>\
                        </div>',
                        props: {
                            errors: { type: Array, default: null }
                        }
                    } );
                }
            };
        } )(),

        inputUnits: ( function() {
            return {
                init: function() {
                    Vue.component( 'input-units', {
                        template: '<input v-model="normalized"></input>',
                        props: {
                            value: { required: true },
                            scale: { type: Number, default: 1.0 },
                            places: { type: Number, default: 2 }
                        },
                        data: function() {
                            return {
                                lastValue: null,
                                lastInput: ''
                            };
                        },
                        computed: {
                            normalized: {
                                get: function() {
                                    // Return the last input if the source value hasn't changed
                                    if ( this.lastValue !== this.value ) {
                                        this.lastValue = this.value;
                                        this.lastInput = $.isNumeric( this.value ) ? this.round( this.value * this.scale ) : '';
                                    }
                                    return this.lastInput;
                                },
                                set: function( newValue ) {
                                    this.lastInput = newValue;
                                    this.lastValue = $.isNumeric( newValue ) ? newValue / this.scale : '';
                                    this.$emit( 'input', this.lastValue );
                                }
                            }
                        },
                        methods: {
                            round: function( val ) {
                                var scalar = Math.pow( 10, Math.round( this.places ) );
                                return Math.round( val * scalar ) / scalar;
                            }
                        }
                    } );
                }
            };
        } )()
    };

    document.addEventListener("turbolinks:load", function() {
        if(Rails.$('.events.app').length > 0) {
            eventStage.init();
        }
    });

    window.eventStage = eventStage;
})(jQuery);

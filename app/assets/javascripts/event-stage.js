(function ($) {

    function formatDate( date ) {
        return ("0" + (date.getMonth() + 1)).slice(-2) + "/" + ("0" + date.getDate()).slice(-2) + "/" + date.getFullYear();
    }

    /**
     * This object stores the countries and regions array
     */
    var locales = {
    	countries : [],
    	regions : {}
    }

    /**
     * Prototypes
     */
    var Effort = ( function() {
        function Effort( data ) {
            this.import( data || {} );
        }
        Effort.prototype.import = function( data ) {
            this.id = data.id || null;
            this.age = data.age || '';
            this.email = data.email || '';
            this.bibNumber = data.bibNumber || '';
            this.birthdate = data.birthdate || '';
            this.city = data.city || '';
            this.countryCode = data.countryCode || '';
            this.stateCode = data.stateCode || '';
            this.gender = data.gender || '';
            this.firstName = data.firstName || '';
            this.lastName = data.lastName || '';
            this.participantId = data.participantId || '';
        }
        Effort.prototype.post = function( eventModel ) {
            var dfd = $.Deferred()
            console.warn( 'Effort', this.id, 'POST Not Fully Implemented' );
            var self = this;
            var data = { effort: {
                event_id: eventModel.id,
                first_name: this.firstName,
                last_name: this.lastName,
                bib_number: this.bibNumber,
                birth_date: this.birthdate,
                gender: this.gender,
                city: this.city,
                country_code: this.countryCode,
                state_code: this.stateCode
            } };
            if ( this.id ) {
                $.ajax( '/api/v1/efforts/' + this.id, {
                    type: "PUT",
                    data: data,
                    dataType: "json",
                } ).done( function( response ) {
                    if ( response.effort && response.effort.id ) {
                        self.import( response.effort );
                        dfd.resolve();
                    } else {
                        console.error( 'Effort', self.id, 'Update failed with error ', response );
                        dfd.reject();
                    }
                } ).fail( function( response ) {
                    console.error( 'Effort', self.id, 'Update failed with error ', response.responseText || response.status );
                    dfd.reject();
                } );
            } else {
                $.ajax( '/api/v1/efforts/', {
                    type: "POST",
                    data: data,
                    dataType: "json",
                } ).done( function( response ) {
                    if ( response.effort && response.effort.id ) {
                        self.import( response.effort );
                        dfd.resolve();
                    } else {
                        console.error( 'Effort', self.id, 'Create failed with error ', response );
                        dfd.reject();
                    }
                } ).fail( function( response ) {
                    console.error( 'Effort', self.id, 'Create failed with error ', response.responseText || response.status );
                    dfd.reject();
                } );
            }
            return dfd.promise();
        }
        Effort.prototype.validate = function( context ) {
            var self = ( context ) ? context : this;
            console.warn( 'Effort', self.id, 'Validator Not Fully Implemented', ( context ) ? '[ External Context ]' : undefined );
            if ( !self.firstName || self.firstName.length < 1 ) return false;
            if ( !self.lastName || self.lastName.length < 1 ) return false;
            if ( !self.gender ) return false;
            if ( !self.countryCode ) return false;
            if ( !self.stateCode ) return false;
            if ( !self.email || self.city.email < 1 ) return false;
            if ( !self.city || self.city.length < 1 ) return false;
            if ( !self.bibNumber || self.bibNumber.length < 1 ) return false;
            return true;
        }
        Effort.prototype.fetch = function() {
            var dfd = $.Deferred()
            console.warn( 'Effort', this.id, 'FETCH Not Fully Implemented' );
            return dfd.promise();
        }
        return Effort;
    } )();

    var Location = ( function() {
        function Location( data ) {
            this.import( data || {} );
        }
        Location.prototype.import = function( data ) {
            this.id = data.id || null;
            this.name = data.name || '';
            this.description = data.description || '';
            this.elevation = data.elevation || null;
            this.latitude = data.latitude || null;
            this.longitude = data.longitude || null;
        }
        Location.prototype.fetch = function() {
            var dfd = $.Deferred()
            
            return dfd.promise();
        }
        return Location;
    } )();

    var Split = ( function() {
        function Split( data ) {
            this.location = new Location();
            this.import( data || {} );
        }
        Split.prototype.import = function( data ) {
            this.id = data.id || null;
            this.baseName = data.baseName || '';
            this.distanceFromStart = data.distanceFromStart || '';
            this.vertGainFromStart = data.vertGainFromStart || '';
            this.vertLossFromStart = data.vertLossFromStart || '';
            this.nameExtensions = data.nameExtensions || [];
            this.kind = data.kind || '';
            this.locationId = data.locationId || null;
            this.location.import( data.location || {} );
        }
        Split.prototype.fetch = function() {
            var dfd = $.Deferred()
            
            return dfd.promise();
        }
        return Split;
    } )();

    var Event = ( function() {
        function Event( data ) {
            // Children
            this.splits = [];
            this.efforts = [];
            // Intermediate Variables
            this.courseNew = false;
            this.organizationNew = false;
            this.import( data || {} );
        }
        Event.prototype.__defineGetter__( 'startTime', function () {
            var startTime = Date.parse( this.date );
            if ( isNaN( startTime ) ) {
                return null;
            } else {
                startTime = new Date( startTime );
                startTime.setHours( this.hours );
                startTime.setMinutes( this.minutes );
            }
            return startTime;
        } );
        Event.prototype.import = function( data ) {
            // Import Properties
            this.id = data.id || null;
            this.stagingId = data.stagingId || null;
            this.name = data.name || '';
            this.description = data.description || '';
            this.lapsRequired = data.lapsRequired || '';
            this.organizationId = data.organizationId || '';
            this.organization = $.extend( {
                id: null,
                name: '',
                description: ''
            }, data.organization || {} );
            this.courseId = data.courseId || '';
            this.course = $.extend( {
                id: null,
                name: '',
                description: ''
            }, data.course || {} );
            // Import Child Objects
            this.splits.splice( 0, this.splits.length );
            for ( var i = 0; i < ( data.splits || [] ).length; i++ ) {
                this.splits.push( new Split( data.splits[i] ) );
            }
            this.efforts.splice( 0, this.efforts.length );
            for ( var i = 0; i < ( data.efforts || [] ).length; i++ ) {
                this.efforts.push( new Effort( data.efforts[i] ) );
            }
            // Extract Start Time
            var startTime = Date.parse( data.startTime || null );
            if ( isNaN( startTime ) ) {
                this.date = "";
                this.hours = 6;
                this.minutes = 0;
            } else {
                startTime = new Date( startTime );
                this.date = formatDate( startTime );
                this.hours = startTime.getHours();
                this.minutes = startTime.getMinutes();
            }
        }
        Event.prototype.validate = function( context ) {
            var self = ( context ) ? context : this;
            console.warn( 'Event', self.stagingId, 'Validator Not Fully Implemented' );
            if ( !self.startTime ) return false;
            return true;
        }
        Event.prototype.post = function() {
            var dfd = $.Deferred()
            if ( this.validate() ) {
                $.post( '/api/v1/staging/' + this.stagingId + '/post_event', {
                    dataType: "json",
                    data: {
                        id: this.id,
                        stagingId: this.stagingId,
                        name: this.name,
                        courseId: this.courseId,
                        course: this.course,
                        organizationId: this.organizationId,
                        organization: this.organization,
                        startTime: this.startTime
                    },
                } ).done( function( ) {
                    dfd.resolve();
                } ).fail( function() {
                    dfd.reject();
                } );
            } else {
                dfd.reject( 'Invalid Event' );
            }
            return dfd.promise();
        };
        Event.prototype.fetch = function() {
            var dfd = $.Deferred()
            var self = this;
            $.get( '/api/v1/staging/' + this.stagingId + '/get_event', {
                dataType: "json",
            } ).done( function( data ) {
                console.info( 'Event', self.stagingId, 'Fetched Event Data From Server', data );
                self.import( data );
                dfd.resolve();
            } ).fail( function () {
                dfd.reject();
            } );
            
            // Return Test Data

            // dfd.resolve();

            return dfd.promise();
        }
        return Event;
    } )();

    /**
     * UI object for the live event view
     *
     */
    var eventStage = {

        router: null,
        app: null,
        data: {
            isDirty: false,
            isStaged: false,
            eventModel: new Event()
        },

        /**
         * This method is used to populate the locale array
         */
        ajaxPopulateLocale: function() {
        	$.get( '/api/v1/staging/get_countries', function( response ) {
        		for ( var i in response.countries ) {
        			locales.countries.push( { code: response.countries[i].code, name: response.countries[i].name } );
                    if ( $.isEmptyObject( response.countries[i].subregions ) ) continue;
                    locales.regions[ response.countries[i].code ] = response.countries[i].subregions;
        		}
        		console.log( locales );
        	} );
        },

        isEventValid: function( eventData ) {
            if ( ! eventData.organization.name ) return false;
            if ( ! eventData.event.name ) return false;
            if ( ! eventData.course.name ) return false;
            return true;
        },

        onRouteChange: function( to, from, next ) {
            eventStage.data.eventModel.fetch();
            next(); return; // NO!
            if ( !eventStage.isEventValid( eventStage.data.eventData ) /* || <other forms> */ ) {
                // Event data must be valid
                next( '/' );
            } else if ( from.name !== 'home' && !eventStage.data.isStaged ) {
                // Event must be staged for any page that isn't home
                next( '/' );
            } else if ( from.name === 'home' && !eventStage.data.isStaged ) {
                $.post( 'save-stage', {
                    data: eventStage.data.eventData
                } ).fail( function() {
                    eventStage.data.isStaged = true;
                    eventStage.data.isDirty = false;
                    next();
                } ).done( function() {
                    // Save cannot fail when not staged yet.
                    next( '/' );
                } );
            } else if ( to.name === 'publish' ) {
                if ( from.name === 'confirm' ) {
                    // Perform publish routine
                    $.post( 'publish-stage', {
                        data: eventStage.data.eventData
                    } ).fail( function() {
                        next();
                    } ).done( function() {
                        next( false ); // ABORT!
                    } );
                } else {
                    // Only accessible from confirm form
                    next( false );
                }
            } else {
                next();
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
            this.prefill.init();
            this.ajaxSelect.init();
            this.ajaxImport.init();
            this.ajaxPopulateLocale();

            // Load UUID
            this.data.eventModel.stagingId = $( '#event-app' ).data( 'uuid' );
            this.data.eventModel.fetch();

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
                            }
                        },
                        template: '#event'
                    }
                },
                { 
                    path: '/splits', 
                    component: {
                        props: ['eventModel'],
                        methods: {
                            isValid: function( split ) {
                                if ( !split.name ) return false;
                                if ( !split.description ) return false;
                                if ( !split.distance ) return false;
                                if ( !split.times ) return false;
                                if ( !split.verticalGain ) return false;
                                if ( !split.verticalLoss ) return false;
                                return true;
                            },
                            blank: function() {
                                return new Split();
                            }
                        },
                        watch: {
                            'eventModel.splits': {
                                handler: function() {
                                    /**
                                     * Make sure locations that reference the same database object
                                     * also use the same javascript object.
                                     */
                                    var count = 0;
                                    // var cache = {};
                                    // if ( !this._cache ) this._cache = {};
                                    // for ( var i = this.eventData.splits.length - 1; i >= 0; i-- ) {
                                    //     var obj = this.eventData.splits[i].location;
                                    //     if ( !obj || !obj.id ) continue;
                                    //     if ( !this._cache[ obj.id ] ) {
                                    //         this._cache[ obj.id ] = obj;
                                    //     } else if ( this._cache[ obj.id ] !== obj ) {
                                    //         count++;
                                    //         $.extend( this._cache[ obj.id ], obj );
                                    //         this.eventData.splits[i].location = this._cache[ obj.id ];
                                    //     }
                                    // }
                                    console.info( 'splits', this._uid, 'Consolidated', count, 'Location Objects' );
                                },
                                deep: true,
                                immediate: true
                            }
                        },
                        data: function() { return { modalData: {}, filter: '' } },
                        template: '#splits'
                    },
                    beforeEnter: this.onRouteChange
                },
                { 
                    path: '/participants', 
                    component: { 
                        props: ['eventModel'], 
                        methods: {
                            isValid: function( participant ) {
                                if ( !participant.first ) return false;
                                if ( !participant.last ) return false;
                                if ( !participant.gender ) return false;
                                if ( !participant.bibnumber ) return false;
                                if ( !participant.email ) return false;
                                if ( !participant.city ) return false;
                                if ( !participant.state ) return false;
                                if ( !participant.country ) return false;
                                return true;
                            },
                            blank: function() {
                                return new Effort();
                            },
                            saveEffort: function() {
                                if ( !this.modalData._dtid ) {
                                    this.eventModel.efforts.push( this.modalData );
                                }
                                this.$nextTick( function() {
                                    this.modalData.post( this.eventModel );
                                } );
                            }
                        },
                        data: function() { return { 
                            countries: locales.countries,
                            regions: locales.regions,
                            modalData: {},
                            filter: ''
                        } }, 
                        template: '#participants'
                    },
                    beforeEnter: this.onRouteChange
                },
                { 
                    path: '/confirmation', 
                    name: 'confirm',
                    component: { props: ['eventModel'], template: '#confirmation' },
                    beforeEnter: this.onRouteChange
                },
                { 
                    path: '/published',
                    name: 'publish',
                    component: { template: '#published' },
                    beforeEnter: this.onRouteChange
                }
            ];
            var router = new VueRouter( {
                routes
            } );
            eventStage.router = router;
            eventStage.app = new Vue( {
                router,
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
                            console.log( 'You got it dirty!' );
                            this._autosave = setTimeout( function() {
                                console.log( 'Do Save!' );
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
                console.info( 'data-tables', this._uid, 'Data Changed: Rebuilding table database' );
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

                        self._table.row.add( row.$el );
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
                this.rows.forEach( function( obj, index ) {
                    obj._dtid = null;
                } );
            },
            onMounted: function() {
                this._queue = [];
                this._table = $( this.$el ).DataTable( {
                    pageLength: this.entries,
                    dom:    "<'row'<'col-sm-12'tr>><'row'<'col-sm-5'i><'col-sm-7'p>>",
                } );
                // Create render Function for Table Rows
                var self = this;
                this._row = Vue.extend( {
                    parent: self,
                    render: function( createElement ) {
                        return createElement( 'tr', {}, self.$scopedSlots.row( this ) );
                    },
                    watch: {
                        row: { 
                            handler: _.debounce( function() {
                                console.info( 'data-tables', this._uid, 'Data Changed: Invalidated table row' );
                                this.$nextTick( function() {
                                    self._table.row( this.$el ).invalidate( 'dom' ).draw();
                                } );
                            }, 1000 ),
                            deep: true
                        }
                    }
                } );
                eventStage.dataTables.onDataChange.call( this );
            },
            init: function() {
                Vue.component( 'data-tables', {
                    template: '<table class="table table-striped" width="100%"><thead><slot name="header"></slot></thead><tbody><slot></slot></tbody></table>',
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
        googleMaps: {
            onValueChange: function() {
                if ( this.value ) {
                    console.info( 'google-map', this._uid, 'Building Location' );

                    if ( this.value !== this._lastLocation ) {
                        this._lastLocation = this.value;
                        if ( this._temp ) this._temp.setVisible( true );
                        if ( isNaN( parseFloat( this.value.latitude ) ) || isNaN( parseFloat( this.value.longitude ) ) ) {
                            if ( this._location ) {
                                this._location.setMap( null );
                                this._location = null;
                            }
                        } else {
                            this._map.setCenter( { lat: parseFloat( this.value.latitude ) , lng: parseFloat( this.value.longitude ) } );
                        }
                    }
                    if ( !this._location ) {
                        // Make new location marker
                        this._location = new google.maps.Marker( {
                            position: { lat: parseFloat( this.value.latitude ) , lng: parseFloat( this.value.longitude ) },
                            map: this._map,
                            title: this.value.name,
                            draggable: true,
                            zIndex: google.maps.Marker.MAX_ZINDEX + 1
                        } );
                        var self = this;
                        this._location.addListener( 'dragend', function( e ) {
                            self.value.latitude = self._location.getPosition().lat();
                            self.value.longitude = self._location.getPosition().lng();
                        } );
                    } else {
                        this._location.setPosition(
                            { lat: parseFloat( this.value.latitude ) , lng: parseFloat( this.value.longitude ) }
                        );
                    }
                }
            },
            onRouteChange: function( e ) {
                if ( this.polyline && $.isArray( this.polyline ) ) {
                    console.info( 'google-map', this._uid, 'Building Polyline' );
                    // Destroy existing polyline
                    if ( this._polyline ) {
                        this._polyline.setMap( null );
                        this._polyline = null;
                    }
                    // Build new polyline
                    var path = [];
                    for ( var i = 0; i < this.polyline.length; i++ ) {
                        if ( isNaN( parseFloat( this.polyline[i].lat ) ) || isNaN( parseFloat( this.polyline[i].lng ) ) ) continue;
                        path.push( { lat: parseFloat( this.polyline[i].lat ) , lng: parseFloat( this.polyline[i].lng ) } );
                    }
                    // Append polyline to map
                    this._polyline = new google.maps.Polyline( {
                        path: path,
                        map: this._map,
                        geodesic: true,
                        strokeColor: '#2A9FD8',
                        strokeOpacity: 1.0,
                        strokeWeight: 4
                    } );
                }
            },
            onBoundsChange: function( e ) {
                var self = this;
                console.info( 'google-map', this._uid, 'Bounds Updated', this._map.getBounds().toJSON() );
                if ( this.searchUrl ) {
                    var bounds = this._map.getBounds().toJSON();
                    $.ajax( this.searchUrl, {
                        dataType: 'json',
                        data: bounds
                    } ).done( function( data ) {
                        console.info( 'google-map', self._uid, 'Location List Updated', data );

                        // Load New Markers
                        console.warn( 'google-maps', self._uid, 'TODO: Need to ignore locations in Route parameter' );
                        console.warn( 'google-maps', self._uid, 'TODO: Need to build out marker cache' );
                        for ( var i = 0; i < data.length; i++ ) {
                            if ( isNaN( parseFloat( data[i].latitude ) ) || isNaN( parseFloat( data[i].longitude ) ) ) continue;
                            if ( self._temp && ( self._temp._data.id == data[i].id ) ) continue; // Preserve Selected Marker
                            var existing = null;
                            for ( var j = self._search.length - 1; j >= 0; j-- ) {
                                if ( self._search[j]._data.id == data[i].id ) {
                                    existing = self._search[j];
                                    break;
                                }
                            }
                            if ( existing !== null ) continue; // Preserve Existing Markers
                            var marker = new google.maps.Marker( {
                                position: { lat: parseFloat( data[i].latitude ) , lng: parseFloat( data[i].longitude ) },
                                map: self._map,
                                icon: {
                                    url: data[i].editable ? '/assets/icons/dot-blue.svg' : '/assets/icons/dot-lblue.svg',
                                    labelOrigin: new google.maps.Point( 12, 14 ),
                                    anchor: new google.maps.Point( 16, 16 )
                                },
                                title: data[i].name,
                            } );
                            marker._data = new Location( data[i] );
                            marker.addListener( 'click', (function( self, marker ) {
                                return function( e ) { // Need extra context to work properly
                                    // Build out content window
                                    var node = $( self._infowindow.getContent() );
                                    node.find( 'h5' ).html( marker._data.name );
                                    node.find( 'p' ).html( marker._data.description || '<i>No Description</i>' );
                                    node.data( 'location', marker._data );
                                    self._infowindow.open( self._map, marker );
                                    // eventStage.googleMaps.onMarkerClick.call( self, e, marker );
                                }
                            } )( self, marker ) );
                            self._search.push( marker );
                        }

                    } );
                }
            },
            onMarkerClick: function( e, marker ) {
                console.info( 'google-map', this._uid, 'Marker Clicked', marker );
                if ( this.value ) {
                    this._temp && this._temp.setVisible( true );
                    this._temp = marker;
                    this._temp && this._temp.setVisible( false );
                    this._lastLocation = {
                        id: marker._data.id,
                        name: marker._data.name,
                        latitude: marker._data.latitude,
                        longitude: marker._data.longitude
                    };
                    this.$emit( 'input', this._lastLocation );
                }
            },
            onMapClick: function( e ) {
                console.info( 'google-map', this._uid, 'Map Clicked', e.latLng.lat(), e.latLng.lng() );
                if ( this.value ) {
                    this._temp && this._temp.setVisible( true );
                    this._temp = null;
                    this._lastLocation = {
                        id: null,
                        latitude: e.latLng.lat(),
                        longitude: e.latLng.lng()
                    };
                    this.$emit( 'input', this._lastLocation );
                }
            },
            onMounted: function() {
                var self = this;
                this._search = [];
                this._route = [];
                this._polyline = null;
                this._difference = null;
                this._map = new google.maps.Map( this.$el, {
                    center: { lat: 39.978915, lng: -105.131036 },
                    zoom: 8
                } );
                // Prepare Info Window
                var node = $( '<div></div>' );
                node.append( '<h5><i>No Title</i></h5>' );
                node.append( '<p><i>No Description</i></p>' );
                node.append( '<a class="js-use btn-sm btn btn-primary">Use</a>' );
                node.append( '<a class="js-clone btn-sm btn btn-default">Clone</a>' );
                this._infowindow = new google.maps.InfoWindow( { content: node[0] } );
                node.on( 'click', '.js-use', function() {
                    self._infowindow.close();
                    self.$emit( 'input', new Location( node.data( 'location' ) ) );
                } );
                node.on( 'click', '.js-clone', function() {
                    self._infowindow.close();
                    self.$emit( 'input', new Location( {
                        latitude: node.data( 'location' ).latitude,
                        longitude: node.data( 'location' ).longitude,
                        elevation: node.data( 'location' ).elevation
                    } ) );
                } );
                // Google Maps in Modal Fix
                $( this.$el ).closest( '.modal' ).on( 'shown.bs.modal', function() {
                    google.maps.event.trigger( self._map, 'resize' );
                } );
                // Attach Listeners
                this._map.addListener( 'click', function( e ) {
                    eventStage.googleMaps.onMapClick.call( self, e );
                } );
                this._map.addListener( 'bounds_changed', _.debounce( function( e ) {
                    eventStage.googleMaps.onBoundsChange.call( self );
                }, 500 ) );
                eventStage.googleMaps.onRouteChange.call( this );
            },
            init: function() {
                Vue.component( 'google-map', {
                    template: '<div class="splits-modal-map-wrap js-google-maps"></div>',
                    props: {
                        editable: {},
                        searchUrl: { type: String, default: null },
                        route: { default: null },
                        value: { default: null }
                    },
                    mounted: eventStage.googleMaps.onMounted,
                    watch: {
                        markers: {
                            handler: eventStage.googleMaps.onMarkerChange,
                            deep: true
                        },
                        route: {
                            handler: eventStage.googleMaps.onRouteChange,
                            deep: true
                        },
                        value: {
                            handler: eventStage.googleMaps.onValueChange,
                            deep: true
                        }
                    }
                } );
            }
        },

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
                        validator: { 
                            type: Function,
                            default: function() { return true }
                        }
                    },
                    watch: {
                        model: {
                            handler: function () {
                                this.valid = !this.validator( this.model );
                            },
                            deep: true
                        }
                    },
                    mounted: function() {
                        var self = this;
                        var reset = function() {
                            // Locally clone existing object
                            self.model = $.extend( true, {}, self.value );
                            // Remove Function References
                            for ( var name in self.model ) {
                                if ( self.model.hasOwnProperty( name ) && $.isFunction( self.model[ name ] ) ) {
                                    delete self.model[ name ];
                                }
                            }
                            console.info( 'edit-modal', self._uid, 'Reseting model data from source' );
                        };
                        $( this.$el ).on( 'show.bs.modal hidden.bs.modal', reset );
                        this.$on( 'cancel', reset );
                        this.$on( 'done', function() {
                            // Copy properties to original object
                            $.extend( self.value, self.model );
                            console.log( self.value, self.model );
                            console.info( 'edit-modal', self._uid, 'Cloning changes back to source' );
                        } );
                    },
                    data: function() {
                    	return {
                    		countries: locales.countries,
                    		regions: locales.regions,
                    		model: {},
                    		valid: false
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

        /**
         *  Ajax Select Component
         *
         *  Contacts the provided endpoint to retrieve it's values. Surround the component
         *  with <keep-alive> to prevent the component from requesting data from the server 
         *  again. Additional data to be sent to the server can be sent using the data property.
         */
        ajaxSelect: {
            onMounted: function() {
                var data = $.extend( {}, this.data );
                var self = this;

                // Mark existing entries
                $( this.$el ).find( 'option' ).addClass( 'static' );

                // Fetch New Entries
                $.ajax( this.url, {
                    method: this.method,
                    dataType: 'json',
                    data: this.data
                } ).done( function( a,b,c ) {
                    $( self.$el ).find( 'option:not( .static )' ).remove();
                } );
            },
            init: function() {
                Vue.component( 'ajax-select', {
                    props: {
                        data: { type: Object, default: function() { return {} } },
                        method: { type: String, default: 'get' },
                        url: { type: String, required: true, default: '' },
                        value: { default: '' }
                    },
                    template: '<select v-bind:value="value" v-on:change="$emit( \'input\', $event.target.value )"><slot></slot></select>',
                    mounted: eventStage.ajaxSelect.onMounted
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
                    fail: function (e, data) {
                        self.error = true;
                        setTimeout( function() {
                            self.error = false;
                        }, 500 );
                    },
                    always: function () {
                        self.busy = false;
                    }
                });
            },
            init: function() {
                Vue.component( 'ajax-import', {
                    template:   '<button class="btn btn-default fileinput-button" v-bind:class="{ \'btn-danger\': error }" :disabled="busy || error">\
                                    <slot></slot>\
                                    <input type="file" name="file"/>\
                                </button>',
                    props: {
                        url: { type: String, required: true, default: '' }
                    },
                    data: function() { return { busy: false, error: false } },
                    mounted: eventStage.ajaxImport.onMounted
                } );
            }
        }
    };

    $( '.events.app' ).ready(function () {
        eventStage.init();
    });

    window.eventStage = eventStage;
})(jQuery);

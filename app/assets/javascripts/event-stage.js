(function ($) {

    function formatDate( date ) {
        return ( "0" + ( date.getMonth() + 1 ) ).slice( -2 ) + "/" + ( "0" + date.getDate() ).slice( -2 ) + "/" + date.getFullYear();
    }

    /**
     * This object stores the countries and regions array
     */
    var locales = {
        countries : [],
        regions : {}
    }

    /**
     * Ajax headers to be used for every transaction
     */
    var headers = {
        'X-Key-Inflection': 'camel' 
    }

    /**
     * Object Inheritance Helper
     */
    function extend( base, child ) {
        function surrogate() {}
        surrogate.prototype = base.prototype;
        child.prototype = new surrogate();
        child.prototype.constructor = child;
    }

    /**
     * Prototypes
     */
    var Resource = ( function() {
        function Resource( parent ) {
            if ( !( parent instanceof Resource ) ) {
                parent = null;
            }
            // Prepare Invisible Parent / Busy Attributes
            Object.defineProperty( this, 'parent', {
                value: parent,
                enumerable: false,
                writable: true,
                configurable: false
            } );
            Object.defineProperty( this, 'busy', {
                value: false,
                enumerable: false,
                writable: true,
                configurable: false
            } );
        }
        /**
         * Copies the specified properties to the Resource if available,
         * otherwise the property is assigned the provided default if unpopulated.
         */
        Resource.prototype.copy = function( dest, src, defaults, reset ) {
            // Enforce Default Values
            defaults = defaults || Object.keys( src );
            reset = reset || false;
            for ( var property in defaults ) {
                if ( src[ property ] !== undefined ) {
                    dest[ property ] = src[ property ];
                } else if ( dest[ property ] === undefined || reset ) {
                    dest[ property ] = $.isPlainObject( defaults ) ? defaults[ property ] : null;
                }
            }
        }
        /**
         *
         */
        Resource.prototype.isBusy = function() {
            if ( this.busy ) console.warn( 'Resource', this.id, 'Model is Busy!' );
            return this.busy;
        }
        /**
         * Manages the busy attribute of the model to prevent ajax calls from 
         * stacking and messing up the data.
         */
        Resource.prototype.waitFor = function( deferred ) {
            var self = this;
            this.busy = true;            
            deferred.fail( function( response ) {
                if ( response.responseJSON && response.responseJSON.error ) {
                    try {
                        response.errors = JSON.parse( response.responseJSON.error ) || [];
                    } catch( err ) {}
                }
            } );
            deferred.always( function() {
                self.busy = false;                
            } );
            return deferred;
        }
        return Resource;
    } )();

    var Effort = ( function() {
        function Effort( data ) {
            Resource.call( this );
            // Calculated Properties
            var self = this;
            function getStartTime() {
                return new Date( self.parent.startTime.getTime() + ( self.startOffset * 1000 ) );
            }
            function setStartOffset( date ) {
                self.startOffset = ( date.getTime() - self.parent.startTime.getTime() ) / 1000;
            }
            var startTime = new Date();
            var startOffset = 0;
            Object.defineProperty( this, 'startMinutes', {
                enumerable: true,
                configurable: true,
                get: function() {
                    try {
                        return getStartTime().getMinutes();
                    } catch( err ) { return 0; }
                },
                set: function( value ) {
                    if ( !value && value !== 0 ) return;
                    var date = getStartTime();
                    date.setMinutes( value );
                    setStartOffset( date );
                }
            } );
            Object.defineProperty( this, 'startHours', {
                enumerable: true,
                configurable: true,
                get: function() {
                    try {
                        return getStartTime().getHours();
                    } catch( err ) { return 0; }
                },
                set: function( value ) {
                    if ( !value && value !== 0 ) return;
                    var date = getStartTime();
                    date.setHours( value );
                    setStartOffset( date );
                }
            } );
            Object.defineProperty( this, 'startDate', {
                enumerable: true,
                configurable: true,
                get: function() {
                    try {
                        return formatDate( getStartTime() );
                    } catch( err ) { return ''; }
                },
                set: function( value ) {
                    var value = Date.parse( value );
                    if ( isNaN( value ) ) return;
                    value = new Date( value );
                    var date = getStartTime();
                    date.setDate( value.getDate() );
                    date.setMonth( value.getMonth() );
                    date.setFullYear( value.getFullYear() );
                    setStartOffset( date );
                }
            } );
            Object.defineProperty( this, 'offsetTime', {
                get: function() {
                    var offset = Math.abs( this.startOffset / 60 );
                    var minutes = offset % 60;
                    var hours = ( offset - minutes ) / 60;
                    return ( this.startOffset < 0 ? '-' : '' ) + hours + ':' + ( '0' + minutes ).slice( -2 );
                },
                set: function( value ) {
                    if ( value == '' ) {
                        this.startOffset = 0;
                    } else {
                        var val = value.split( ':' );
                        var hours = Math.abs( parseInt( val[0] ) );
                        var minutes = Math.abs( parseInt( val[1] ) );
                        var offset = ( ( hours * 60 ) + minutes ) * 60;
                        if ( value.startsWith( '-' ) ) {
                            offset = -offset;
                        }
                        this.startOffset = offset;
                    }
                }
            } );
            this.import( data || {} );
        }
        extend( Resource, Effort );
        Effort.prototype.import = function( data ) {
            this.copy( this, data, {
                id: null,
                age: null,
                email: '',
                bibNumber: '',
                birthdate: '',
                city: '',
                countryCode: '',
                stateCode: '',
                gender: null,
                firstName: '',
                lastName: '',
                participantId: null,
                startOffset: 0
            } );
        }
        Effort.prototype.post = function() {
            var dfd = $.Deferred();
            var self = this;
            var data = { effort: {
                event_id: this.parent.id,
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
                dfd = $.ajax( '/api/v1/efforts/' + this.id, {
                    type: "PUT",
                    data: data,
                    dataType: "json",
                } );
            } else {
                dfd = $.ajax( '/api/v1/efforts/', {
                    type: "POST",
                    data: data,
                    dataType: "json",
                } );
            }
            dfd = dfd.then( function( data ) {
                self.import( data );
            } );
            return this.waitFor( dfd.promise() );
        }
        Effort.prototype.validate = function( context ) {
            var self = ( context ) ? context : this;
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
            var dfd = $.Deferred();
            var self = this;
            if ( this.id && this.id !== null ) {
                dfd = $.ajax( '/api/v1/efforts/' + this.id, {
                    type: "GET",
                    headers: headers,
                    dataType: "json"
                } ).done( function( data ) {                    
                    self.import( data );
                } );
            } else {
                console.warn( 'Course', this.id, 'Tried to Fetch Effort without ID' );
                dfd.reject();
            }
            return this.waitFor( dfd.promise() );
        }
        Effort.prototype.delete = function() {
            var dfd = $.Deferred();
            var self = this;
            if ( this.id && this.id !== null ) {
                dfd = $.ajax( '/api/v1/efforts/' + this.id, {
                    type: "DELETE",
                    headers: headers,
                    dataType: "json"
                } ).done( function( data ) {                    
                } );
            } else {
                console.warn( 'Course', this.id, 'Tried to Delete Effort without ID' );
                dfd.reject();
            }
            return this.waitFor( dfd.promise() );
        }
        return Effort;
    } )();

    var Split = ( function() {
        function Split( parent, data ) {
            Resource.call( this, parent );
            this.import( data || {} );
        }
        extend( Resource, Split );
        Split.prototype.export = function( data ) {
            var data = {};
            this.copy( data, this, {
                id: null,
                baseName: null,
                course_id: this.parent.id,
                kind: null,
                distanceFromStart: null,
                vertGainFromStart: null,
                vertLossFromStart: null,
                description: null,
                nameExtensions: [],
                elevation: null,
                latitude: null,
                longitude: null
            } );
            return data;
        }
        Split.prototype.import = function( data ) {
            this.nameExtensions = data.nameExtensions || [];
            this.copy( this, data, {
                id: null,
                editable: true,
                baseName: '',
                distanceFromStart: null,
                vertGainFromStart: null,
                vertLossFromStart: null,
                kind: 'intermediate',
                associated: false,
                elevation: null,
                latitude: null,
                longitude: null
            } );
        }
        Split.prototype.associate = function( associated ) {
            var dfd = $.Deferred();
            if ( this.isBusy() ) return dfd.reject();
            if ( !this.id || !this.parent || !this.parent.parent ) {
                console.error( 'Split', this.id, 'Cannot associate a split with no ID or Parents' )
                dfd.reject();
            } else {
                dfd = $.ajax( '/api/v1/events/' + this.parent.parent.stagingId + ( associated ? '/associate_splits' : '/remove_splits' ), {
                    type: ( associated ? 'PUT' : 'DELETE' ),
                    data: {
                        'splitIds': this.id
                    },
                    headers: headers,
                    dataType: "json",
                } );
                var self = this;
                dfd = dfd.then( function( data ) {
                    if ( data.message == 'splits removed from event' ) {
                        self.associated = false;
                    } else if ( data.message == 'splits associated with event' ) {
                        self.associated = true;
                    } else {
                        return $.Deferred().reject();
                    }
                } );
            }
            return this.waitFor( dfd.promise() );
        }
        Split.prototype.validate = function( context ) {
            var self = ( context ) ? context : this;
            if ( !self.baseName || self.baseName.length < 1 ) return false;
            if ( !$.isNumeric( self.distanceFromStart ) ) return false;
            if ( !$.isNumeric( self.vertGainFromStart ) ) return false;
            if ( !$.isNumeric( self.vertLossFromStart ) ) return false;
            return true;
        }
        Split.prototype.post = function() {
            var dfd = $.Deferred();
            if ( this.isBusy() ) return dfd.reject();
            var self = this;
            if ( !this.id ) {
                dfd = $.ajax( '/api/v1/splits/', {
                    type: 'POST',
                    data: { split: this.export() },
                    headers: headers,
                    dataType: "json",
                } ).then( function( data ) {
                    self.import( data.split );
                    self.busy = false; // Allow Operation to continue
                    return self.associate( true );
                } );
            } else {
                dfd = $.ajax( '/api/v1/splits/' + this.id, {
                    type: 'PUT',
                    data: { split: this.export() },
                    headers: headers,
                    dataType: "json",
                } ).then( function( data ) {
                    self.import( data );
                } );
            }
            dfd.then( function() { self.parent.normalize(); } );
            return this.waitFor( dfd.promise() );
        }
        Split.prototype.fetch = function() {
            var dfd = $.Deferred();
            var self = this;
            if ( this.isBusy() ) return dfd.reject();
            if ( this.id && this.id !== null ) {
                dfd = $.ajax( '/api/v1/splits/' + this.id, {
                    type: "GET",
                    headers: headers,
                    dataType: "json"
                } ).then( function( data ) {
                    self.import( data );
                } );
            } else {
                console.warn( 'Course', this.id, 'Tried to Fetch Split without ID' );
                dfd.reject();
            }
            dfd.then( function() { self.parent.normalize(); } );
            return this.waitFor( dfd.promise() );
        }
        Split.prototype.delete = function() {
            var dfd = $.Deferred();
            var self = this;
            if ( this.id && this.id !== null ) {
                dfd = $.ajax( '/api/v1/splits/' + this.id, {
                    type: "DELETE",
                    headers: headers,
                    dataType: "json"
                } );
            } else {
                console.warn( 'Course', this.id, 'Tried to Delete Split without ID' );
                dfd.reject();
            }
            dfd.then( function() { self.parent.normalize(); } );
            return this.waitFor( dfd.promise() );
        }
        return Split;
    } )();

    var Organization = ( function() {
        function Organization( data ) {
            Resource.call( this );
            this.import( data || {} );
        }
        extend( Resource, Organization );
        Organization.prototype.export = function() {
            var data = {};
            this.copy( data, this, {
                id: null,
                name: ''
            } );
            return data;
        }
        Organization.prototype.validate = function() {
            if ( !this.name ||this.name.length < 1 ) return false;
            return true;
        }
        Organization.prototype.import = function( data, reset ) {
            this.copy( this, data, {
                id: null,
                name: '',
                editable: false
            }, reset && true );
        }
        Organization.prototype.fetch = function() {
            var dfd = $.Deferred();
            if ( this.isBusy() ) return dfd.reject();
            if ( !this.id || !this.parent ) {
                dfd.reject();
            } else {
                dfd = $.ajax( '/api/v1/organizations/' + this.id, {
                    type: "GET",
                    headers: headers,
                    dataType: "json",
                } );
                var self = this;
                dfd = dfd.then( function( data ) {
                    self.import( data );
                } );
            }
            return this.waitFor( dfd.promise() );
        }
        return Organization;
    } )();

    var Course = ( function() {
        function Course( data ) {
            Resource.call( this );
            this.id = null;
            this.splits = [];
            this.import( data || {} );            
        }
        extend( Resource, Course );
        Course.prototype.endSplit = function( kind ) {
            for ( var i = this.splits.length - 1; i >= 0; i-- ) {
                if ( this.splits[i].kind === kind ) {
                    return this.splits[i];
                }
            }
            return null;
        }
        Course.prototype.normalize = function( ) {
            // Verify Existence of End Splits
            if ( this.endSplit( 'start' ) === null ) {
                this.splits.push( new Split( this, { kind: 'start', baseName: 'Start', distanceFromStart: 0, vertGainFromStart: 0, vertLossFromStart: 0 } ) );
                this.normalize();
            }
            if ( this.endSplit( 'finish' ) === null ) {
                this.splits.push( new Split( this, { kind: 'finish', baseName: 'Finish' } ) );
                this.normalize();
            }
            this.splits.sort( function( a, b ) {
                return a.distanceFromStart - b.distanceFromStart;
            } );
        }
        Course.prototype.export = function() {
            var data = {};
            this.copy( data, this, {
                id: null,
                name: '',
                description: '',
                splits_attributes: []
            } );
            for ( var i = this.splits.length - 1; i >= 0; i-- ) {
                if ( this.splits[i].kind === 'start' || 
                        this.splits[i].kind === 'finish' ) {
                    data.splits_attributes.push( this.splits[i].export() );
                }
            }
            return data;
        }
        Course.prototype.import = function( data, reset ) {
            this.copy( this, data, {
                id: null,
                name: '',
                description: '',
                editable: false
            }, reset );
            if ( data.splits || reset ) {
                this.splits.splice( 0, this.splits.length );
                for ( var i = 0; i < ( data.splits || [] ).length; i++ ) {
                    this.splits.push( new Split( this, data.splits[i] ) );
                }
            }
            // Mark Associated Courses
            if ( this.parent instanceof Event ) {
                for ( var i = 0; i < this.splits.length; i++ ) {
                    // Splits are associated if their id is included in Event.splitIds
                    this.splits[i].associated = 
                        ( this.parent.splitIds.indexOf( this.splits[i].id ) !== -1 );
                }
            }
            this.normalize();
        }
        Course.prototype.validate = function( context ) {
            var self = ( context ) ? context : this;
            if ( !self.name || self.name.length < 1 ) return false;
            if ( !self.endSplit( 'finish' ).validate() ) return false;
            return true;
        }
        Course.prototype.fetch = function() {
            var self = this;
            if ( this.id !== null ) {
                return $.ajax( '/api/v1/courses/' + this.id, {
                    type: "GET",
                    headers: headers,
                    dataType: "json"
                } ).done( function( data ) {                    
                    self.import( data );
                } );
            } else {
                console.warn( 'Course', this.id, 'Tried to Fetch Course without ID' );
                return $.Deferred().resolve().promise();
            }
        };
        return Course;
    } )();

    var Event = ( function() {
        function Event( data ) {
            Resource.call( this );
            // Children
            this.course = new Course();
            this.course.parent = this;
            this.organization = new Organization();
            this.organization.parent = this;
            this.efforts = [];
            // Intermediate Variables
            this.laps = false;
            this.courseNew = false;
            this.organizationNew = false;
            this.import( data || {} );
        }
        extend( Resource, Event );
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
        Event.prototype.export = function() {
            var data = { event: {} };
            this.copy( data.event, this, {
                id: null,
                name: '',
                description: '',
                lapsRequired: 1,
                courseId: this.course.id,
                organizationId: this.organization.id
            } );
            data.course = this.course.export();
            data.organization = this.organization.export();
            return data;
        }
        Event.prototype.import = function( data, reset ) {
            // Import Properties
            this.organization.id = data.organizationId || null;
            this.course.id = data.courseId || null;
            this.copy( this, data, {
                id: null,
                stagingId: null,
                name: '',
                description: '',
                lapsRequired: 1,
                editable: false,
                splitIds: []
            }, reset );
            this.laps = this.lapsRequired !== 1;
            if ( data.efforts ) {
                this.efforts.splice( 0, this.efforts.length );
                for ( var i = 0; i < data.efforts.length; i++ ) {
                    var effort = new Effort( data.efforts[i] );
                    effort.parent = this;
                    this.efforts.push( effort );
                }
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
            if ( !self.name || self.name.length < 1 ) return false;
            if ( !( self.organization.id || self.organizationNew ) ) return false;
            if ( !self.organization.validate() ) return false;
            if ( !self.course.validate() ) return false;
            if ( !self.startTime ) return false;
            return true;
        }
        Event.prototype.post = function() {
            var self = this;
            var dfd = $.Deferred()
            if ( this.validate() ) {
                var dfd = $.ajax( '/api/v1/staging/' + this.stagingId + '/post_event_course_org', {
                    headers: headers,
                    dataType: "json",
                    type: "POST",
                    data: this.export()
                } );
                dfd = dfd.then( function( data ) {                
                    self.import( data.event );
                    self.organization.import( data.organization || {} );
                    return self.course.fetch();
                } );
            } else {
                dfd.reject( 'Invalid Event' );
            }
            return dfd.promise();
        };
        Event.prototype.fetch = function() {
            var self = this;
            var dfd = $.get( '/api/v1/staging/' + this.stagingId + '/get_event', {
                dataType: "json",
            } );
            dfd = dfd.then( function( data ) {                
                self.import( data );
                self.organization.import( data.organization || {} );
                return self.course.fetch();
            } );
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
            $.get( '/api/v1/staging/' + eventStage.data.eventModel.stagingId + '/get_countries', function( response ) {
                for ( var i in response.countries ) {
                    locales.countries.push( { code: response.countries[i].code, name: response.countries[i].name } );
                    if ( $.isEmptyObject( response.countries[i].subregions ) ) continue;
                    locales.regions[ response.countries[i].code ] = response.countries[i].subregions;
                }               
            } );
        },

        isEventValid: function( eventData ) {
            if ( ! eventData.organization.name ) return false;
            if ( ! eventData.event.name ) return false;
            if ( ! eventData.course.name ) return false;
            return true;
        },

        onRouteChange: function( to, from, next ) {
            if ( to.name === 'publish' && from.name !== 'confirm' ) {
                next( false );
            } else if ( from.name === 'home' ) {
                eventStage.data.eventModel.post().done( function() {
                    next();
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
            this.prefill.init();
            this.promise.init();
            this.resourceSelect.init();
            this.ajaxImport.init();

            // Load UUID
            this.data.eventModel.stagingId = $( '#event-app' ).data( 'uuid' );
            this.ajaxPopulateLocale();

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
                    },
                    beforeEnter: this.onRouteChange
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
                                var split = new Split( this.eventModel.course );
                                return split;
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
                                var effort = new Effort();
                                effort.parent = this.eventModel;
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
                if ( $.isArray( this.rows ) ) {
                    this.rows.forEach( function( obj, index ) {
                        obj._dtid = null;
                    } );
                }
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
            uniqueId: 1,
            onValueChange: function() {
                if ( this.value ) {
                    if ( !this._location ) {
                        // Make new location marker
                        this._location = new google.maps.Marker( {
                            position: { lat: parseFloat( this.value.latitude ) , lng: parseFloat( this.value.longitude ) },
                            icon: {
                                url: '/assets/icons/green.svg'
                            },
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
                    eventStage.googleMaps.onRouteChange.call( this );
                }
            },
            onRouteChange: function( e ) {
                if ( this.route && $.isArray( this.route ) ) {                    
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
                        var marker = null;
                        if ( !e[i]._gmid || !this._route[ e[i]._gmid ] ) {
                            // No Unique Google Map ID or Not In Cache
                            if ( !e[i]._gmid ) {
                                e[i]._gmid = eventStage.googleMaps.uniqueId++;
                            }
                            marker = new google.maps.Marker( {
                                map: this._map
                            } );
                            marker._data = e[i];
                            this._route[ e[i]._gmid ] = marker;
                        }
                        // Update Marker
                        marker = this._route[ e[i]._gmid ];
                        marker.setIcon( {
                            url: '/assets/icons/dot-blue.svg',
                            labelOrigin: new google.maps.Point( 12, 14 ),
                            anchor: new google.maps.Point( 16, 16 )
                        } );
                        marker.setPosition( latlng );
                        marker.setOpacity( e[i].associated ? 1.0 : 0.5 );
                        path.push( latlng );
                        // Update Cache
                        gmids.push( e[i]._gmid );
                    }
                    // Append Value to Polyline
                    if ( value ) {
                        // Inject Value into Polyline
                        path.push( { lat: parseFloat( value.latitude ) , lng: parseFloat( value.longitude ) } );
                    }
                    // Remove Unused Markers
                    for ( var _gmid in this._route ) {
                        if ( gmids.indexOf( Number.parseInt( _gmid ) ) === -1 ) {
                            this._route[ _gmid ].setMap( null );
                            delete this._route[ _gmid ];
                        } 
                    }
                    // Append route to map
                    this._polyline = new google.maps.Polyline( {
                        path: path,
                        map: this._map,
                        geodesic: true,
                        strokeColor: '#2A9FD8',
                        strokeOpacity: 1.0,
                        strokeWeight: 4
                    } );
                    // Fit Map
                    if ( this.locked !== undefined ) {
                        this._map.fitBounds( bounds );
                    }
                }
            },
            onBoundsChange: function( e ) {
                var self = this;                
                if ( this.searchUrl ) {
                    var bounds = this._map.getBounds().toJSON();
                    $.ajax( this.searchUrl, {
                        dataType: 'json',
                        data: bounds
                    } ).done( function( data ) {                        

                        // Load New Markers
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
                            marker._data = data[i];
                            marker.addListener( 'click', (function( self, marker ) {
                                return function( e ) { // Need extra context to work properly
                                    // Build out content window
                                    var node = $( self._infowindow.getContent() );
                                    node.find( 'h5' ).html( marker._data.baseName );
                                    node.find( 'p' ).html( marker._data.courseName || '<i>No Course</i>' );
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
                if ( this.value ) {
                    this._temp && this._temp.setVisible( true );
                    this._temp = marker;
                    this._temp && this._temp.setVisible( false );
                    this.value.latitude = marker._data.latitude;
                    this.value.longitude = marker._data.longitude;
                    this.$emit( 'input', this.value );
                }
            },
            onMapClick: function( e ) {                
                if ( this.value ) {
                    this._temp && this._temp.setVisible( true );
                    this._temp = null;
                    this.value.latitude = e.latLng.lat();
                    this.value.longitude = e.latLng.lng();
                    this.$emit( 'input', this.value );
                }
            },
            onMounted: function() {
                var self = this;
                this._search = [];
                this._route = {};
                this._polyline = null;
                this._difference = null;
                this._map = new google.maps.Map( this.$el, {
                    center: { lat: 39.978915, lng: -105.131036 },
                    zoom: 8,
                    zoomControl: this.locked == undefined,
                    draggable: this.locked == undefined,
                    scrollwheel: this.locked == undefined,
                    navigationControl: this.locked == undefined,
                    mapTypeControl: this.locked == undefined,
                    scaleControl: this.locked == undefined
                } );
                // Prepare Info Window
                var node = $( '<div></div>' );
                node.append( '<h5><i>No Title</i></h5>' );
                node.append( '<p><i>No Description</i></p>' );
                node.append( '<a class="js-clone btn-sm btn btn-primary">Clone Location</a>' );                
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
                    if ( self.value ) {
                        self._map.setCenter( { lat: parseFloat( self.value.latitude ) , lng: parseFloat( self.value.longitude ) } );
                    }
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
                        locked: {},
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
                        'value.latitude': eventStage.googleMaps.onValueChange,
                        'value.longitude': eventStage.googleMaps.onValueChange,
                        'value.distanceFromStart': eventStage.googleMaps.onValueChange
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
                            self.model = self.value;
                            self.error = null;
                            $( self.$el ).modal( 'hide' );
                        };
                        $( this.$el ).on( 'show.bs.modal hidden.bs.modal', reset );
                        this.$on( 'cancel', reset );
                        this.$on( 'done', function() {
                            self.$emit( 'change' );
                            $( this.$el ).modal( 'hide' );
                        } );
                    },
                    data: function() {
                        return {
                            countries: locales.countries,
                            regions: locales.regions,
                            model: {},
                            valid: false,
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
                        if ( !$.isFunction( fn ) ) {
                            console.error( 'v-promise Directive Must Be Passed a Function!' );
                            return;
                        }
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
                $.ajax( this.source, {
                    type: 'GET',
                    dataType: 'json',
                    data: this.data
                } ).done( function( data ) {
                    self.ajaxed = data;
                    // Force update after list is rendered
                    self.$nextTick( function() {
                        self.$forceUpdate();
                    } );
                } );
            },
            onChanged: function( id ) {
                var model = null;
                for ( var i = this.ajaxed.length - 1; i >= 0; i-- ) {
                    if ( this.ajaxed[i].id == id ) {
                        model = this.ajaxed[i];
                    }
                }
                if ( this.value instanceof Resource ) {
                    this.value.import( model );
                    this.value.fetch();
                }
            },
            init: function() {
                Vue.component( 'resource-select', {
                    props: {
                        data: { type: Object, default: function() { return {} } },
                        source: { type: String, required: true, default: '' },
                        value: { type: Object, required: true, default: {} }
                    },
                    methods: {
                        onChanged: eventStage.resourceSelect.onChanged
                    },
                    data: function() { return { ajaxed: null } },
                    template: 
                        '<select v-bind:value="value.id" v-on:change="onChanged( $event.target.value )">\
                            <slot></slot>\
                            <option v-if="ajaxed === null" :value="value.id">{{ value.name }}</option>\
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

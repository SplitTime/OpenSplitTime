{
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
            if ( response && response.responseJSON && response.responseJSON.error ) {
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
    Effort.prototype.export = function() {
        var data = {};
        this.copy( data, this, {
            eventId: this.parent.id,
            id: null,
            firstName: '',
            lastName: '',
            bibNumber: '',
            gender: '',
            city: '',
            countryCode: '',
            stateCode: ''
        } );
        return data;
    }
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
        if ( this.id ) {
            dfd = $.ajax( '/api/v1/efforts/' + this.id, {
                type: "PUT",
                data: { effort: this.export() },
                dataType: "json",
            } );
        } else {
            dfd = $.ajax( '/api/v1/efforts/', {
                type: "POST",
                data: { effort: this.export() },
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
        if ( !this.id || !this.parent || !this.parent.parent || !this.parent.parent.id ) {
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
                self.import( data );
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
        var start = this.endSplit( 'start' );
        var finish = this.endSplit( 'finish' );
        if ( start === null ) {
            this.splits.push( new Split( this, { kind: 'start', baseName: 'Start', distanceFromStart: 0, vertGainFromStart: 0, vertLossFromStart: 0 } ) );
            this.normalize();
        } else if ( start.id && this.parent.id && start.associated === false ) {
            start.associate( true );
        }
        if ( finish === null ) {
            this.splits.push( new Split( this, { kind: 'finish', baseName: 'Finish' } ) );
            this.normalize();
        } else if ( finish.id && this.parent.id && finish.associated === false ) {
            finish.associate( true );
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
            organizationId: this.organization.id,
            startTime: null
        } );
        data.course = this.course.export();
        data.organization = this.organization.export();
        return data;
    }
    Event.prototype.import = function( data, reset ) {
        // Import Properties
        this.organization.id = data.organizationId || null;
        this.course.id = data.courseId || null;
        data.lapsRequired = ( data.lapsRequired === null ) ? 1 : data.lapsRequired;
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
    };
    Event.prototype.visibility = function( visibility ) {
        var dfd = $.Deferred();
        if ( this.isBusy() ) return dfd.reject();
        if ( !this.id ) {
            dfd.reject();
        } else {
            dfd = $.ajax( '/api/v1/staging/' + this.stagingId + '/update_event_visibility', {
                type: "PATCH",
                headers: headers,
                data: { status: visibility ? 'public' : 'private' },
                dataType: "json"
            } );
            var self = this;
            dfd = dfd.then( function( data ) {
                self.import( data );
            } );
        };
        return this.waitFor( dfd.promise() );
    }
    return Event;
} )();

}
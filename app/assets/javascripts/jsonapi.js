var JSONAPI = (function ($) {
    function JSONAPI( apiurl ) {
        // Auto-Instantiation
        if ( !( this instanceof JSONAPI ) ) return new JSONAPI( apiurl );

        /** Helper Functions **/
        function extend( base, child ) {
            function surrogate() {}
            surrogate.prototype = base.prototype;
            child.prototype = new surrogate();
            child.prototype.constructor = child;
        }
        function normalizeKey( key ) {
            return key.replace( /([^a-zA-Z0-9-_]+)/g, '_' );
        }
        function normalizeRelationships( relationships ) {
            if ( !relationships || !$.isPlainObject( relationships ) ) return {};
            var normal = {};
            for ( var name in relationships ) {
                if ( $.isArray( relationships[ name ] ) ) {
                    normal[ name ] = [ relationships[ name ][0] ];
                } else if ( $.type( relationships[ name ] ) === 'string' ) {
                    normal[ name ] = relationships[ name ];
                }
            }
            return normal;
        }
        function normalizeAttributes( attributes ) {
            attributes = $.extend( attributes || {}, { id: Number, errors: { type: Array, default: [] } } );
            var defaults = {
                default: null,
                hidden: false
            };
            var normal = {};
            if ( $.isArray( attributes ) ) {
                for ( var i = 0; i < attributes.length; i++ ) {
                    normal[ attributes[i] ] = $.extend( {}, defaults );
                }
            } else {
                for ( var name in attributes ) {
                    if ( $.isPlainObject( attributes[ name ] ) ) {
                        normal[ name ] = $.extend( {}, defaults, attributes[ name ] );
                    } else {
                        normal[ name ] = $.extend( { type: attributes[ name ] }, defaults );
                    }
                }
            }
            return normal;
        }
        function normalizeURL( url ) {
            return ( url.lastIndexOf( '/' ) === url.length - 1 ) ? url.slice( 0, -1 ) : url;
        }
        apiurl = normalizeURL( apiurl );

        // Normalize API url
        var API = this;
        var registrar = {};

        function error( self, args ) {
            var errors = [];
            for ( var i = 1; i < arguments.length; i++ ) {
                errors = $.merge( errors, $.isArray( arguments[i] ) ? arguments[i] : [ arguments[i] ] );
            }
            if ( self instanceof API.Model ) {
                self.errors = errors;
                return $.Deferred().reject( self );
            } else {
                return $.Deferred().reject( [], errors );
            }
        }

        function parse( json, url ) {
            var self = this;
            var cache = [];
            var models = [];
            /* OST Specific Transform */
            if ( json.event && json.course && json.organization ) {
                json.data = {
                    id: json.event.id,
                    type: 'events',
                    attributes: json.event,
                    relationships: {
                        course: {
                            data: {
                                id: json.course.id,
                                type: 'courses'
                            }
                        },
                        organization: {
                            data: {
                                id: json.organization.id,
                                type: 'organizations'
                            }
                        }
                    }
                };
                json.includes = [
                    {
                        id: json.course.id,
                        type: 'courses',
                        attributes: json.course
                    },
                    {
                        id: json.organization.id,
                        type: 'organizations',
                        attributes: json.organization
                    }
                ];
            }
            /* OST Specific Transform */
            if ( self instanceof API.Model ) {
                if ( json.data === null ) {
                    console.warn( 'Server does not recognize the \'' + self.__type__ + '\' model ID.' );
                    return error( self, 'Unknown Model ID' );
                }
                // Server must return a single object of the correct type
                if ( !$.isPlainObject( json.data ) || json.data.type !== self.__type__ ) {
                    console.error( 'Invalid JSON API response for \'' + self.__type__ + '\' model.' );
                    return error( self, 'Invalid Response' );
                }
                self.__new__ = false;
                cache = self.parse( json.data, [ self ] );
            } else {
                if ( !$.isArray( json.data ) ) {
                    console.error( 'Invalid JSON API response from \'' + url + '\'' );
                    return error( self, 'Invalid Response' );
                }
                for ( var i = 0; i < json.data.length; i++ ) {
                    var model = API.create( json.data[i].type, { id: json.data[i].id } );
                    model.__new__ = false;
                    if ( model instanceof API.Model ) {
                        var data = model.in( cache );
                        if ( data !== false ) {
                            model = data;
                        } else {
                            cache.push( model );
                        }
                        model.parse( json.data[i], cache );
                        models.push( model );
                    }
                }
            }
            for ( var i = 0; i < cache.length; i++ ) {
                if ( cache[i] === self ) continue;
                var data = cache[i].in( json.included );
                if ( data !== false ) {
                    cache[i].parse( data, cache );
                }
            }

            for ( var i = 0; i < cache.length; i++ ) {
                if ( cache[i].afterParse ) cache[i].afterParse();
            }

            if ( self instanceof API.Model ) {
                console.info( 'JSONAPI', 'Parsed JSON API response for \'' + self.__type__ + '\' model.' );
                self.errors = [];
            } else {
                console.info( 'JSONAPI', 'Parsed JSON API response from \'' + url + '\'' );
            }

            return ( self instanceof API.Model ) ? self : models;
        }

        function request( url, type, includes, contentType ) {
            var self = this;
            type = type.toLowerCase();
            if ( $.inArray( type, [ 'get', 'put', 'post', 'patch', 'delete' ] ) === -1 ) {
                console.error( 'JSONAPI', 'Invalid request type \'' + type + '\'' );
                return error( self, 'Invalid request type \'' + type + '\'' );
            }
            var data = null;
            if ( this instanceof API.Model && type !== 'get' ) {
                data = JSON.stringify( this.jsonify() );
            } else {
                data = $.isArray( includes ) ? { include: includes.join( ',' ) } : null;
            }
            contentType = contentType || 'application/vnd.api+json';
            return $.ajax( apiurl + '/' + url, {
                    type: type,
                    headers: {
                        'Accepted': 'application/vnd.api+json',
                        'Content-Type': ( type !== 'get' ) ? 'application/json' : undefined
                    },
                    data: data
                } )
                .then( function( json ) {
                    return parse.call( self, json, url );
                } , function( a,b,c ) {
                    if ( a.responseJSON && a.responseJSON.errors ) {
                        console.error( 'JSONAPI', 'Server reported errors \'' + self.__type__ + '\' model.' )
                        $( document ).trigger( 'global-error', [ a.responseJSON.errors ] );
                        return error( self, 'ERRORS' );
                    } else if ( a.status === 404 ) {
                        console.warn( 'JSONAPI', 'Server does not recognize the \'' + self.__type__ + '\' model ID.' );
                        return error( self, 'Unknown Model ID' );
                    } else if ( a.status === 400 ) {
                        console.error( 'JSONAPI', 'Server reported a protocol violation on \'' + self.__type__ + '\' model.' )
                        var errors = 'Protocol Violation';
                        try {
                            errors = JSON.stringify( a.responseJSON.error );
                        } catch( e ) {}
                        return error( self, errors );
                    } else {
                        return error( self, 'Unknown Error' );
                    }
                } ).promise();
        }

        /** Default Resource Model **/
        this.Model = (function() {
            function Model( type, attributes, relationships, hooks, includes ) {
                Object.defineProperty( this, '__type__', { value: type } );
                Object.defineProperty( this, '__new__', { value: true, writable: true } );
                Object.defineProperty( this, '__attributes__', { value: attributes } );
                Object.defineProperty( this, '__relationships__', { value: relationships } );
                Object.defineProperty( this, '__includes__', { value: includes } );
                if ( attributes && $.isPlainObject( attributes ) ) {
                    // Generate attribute list
                    for ( var name in attributes ) {
                        var property = attributes[ name ];
                        if ( $.isFunction( property.get ) || $.isFunction( property.set ) ) {
                            Object.defineProperty( this, name, {
                                enumerable: !( property.hidden || false ),
                                configurable: true,
                                get: property.get,
                                set: property.set || undefined
                            } );
                        } else {
                            Object.defineProperty( this, name, {
                                value: ( property.default === undefined ? null : property.default ),
                                enumerable: !( property.hidden || false ),
                                configurable: true,
                                writable: true
                            } );
                        }
                    }
                }
                if ( relationships && $.isPlainObject( relationships ) ) {
                    // Generate relationship list
                    for ( var name in relationships ) {
                        Object.defineProperty( this, name, {
                            value: $.isArray( relationships[ name ] ) ? [] : null,
                            enumerable: true,
                            configurable: true,
                            writable: true
                        } );
                    }
                }
                if ( this.afterCreate ) this.afterCreate();
            }

            Model.prototype.parse = function( json, cache ) {
                var cache = $.isArray( cache ) ? cache : [];
                this.id = json.id;
                this.import( json.attributes || {} );

                for ( var name in json.relationships ) {
                    if ( this.__relationships__[ name ] ) {
                        var data = json.relationships[ name ].data
                        if ( $.isArray( this.__relationships__[ name ] ) ) {
                            if ( $.isArray( data ) ) {
                                for ( var i = 0; i < this[ name ].length; i++ ) {
                                    this[ name ][i].in( cache ) || cache.push( this[ name ][i] );
                                }
                                this[ name ].splice( 0, this[ name ].length );
                                for ( var i = 0; i < data.length; i++ ) {
                                    var model = API.create( data[i].type, { id: data[i].id } );
                                    model.__new__ = false;
                                    var cached = model.in( cache )
                                    this[ name ].push( cached || model );
                                    cached || cache.push( model );
                                }
                            }
                        } else {
                            if ( $.isPlainObject( data ) ) {
                                if ( this[ name ] === null || this[ name ].id != data.id ) {
                                    var model = API.create( data.type, { id: data.id } );
                                    model.__new__ = false;
                                    this[ name ] = model.in( cache ) || model;
                                }
                                this[ name ].in( cache ) || cache.push( this[ name ] );
                            } else {
                                this[ name ] = null;
                            }
                        }
                    }
                }

                return cache;
            }

            Model.prototype.attributes = function() {
                var data = {};
                for ( var name in this.__attributes__ ) {
                    if ( this.__attributes__[ name ].type === Number ) {
                        if ( $.isNumeric( this[ name ] ) ) {
                            data[ name ] = Number( this[ name ] );
                        } else {
                            data[ name ] = this.__attributes__[ name ].default;
                        }
                    } else {
                        data[ name ] = this[ name ];
                    }
                }
                return data;
            }

            Model.prototype._jsonify = function() {
                var json = {
                     data: {
                        type: this.__type__,
                        id: this.id,
                        attributes: this.attributes(),
                        relationships: {}
                     }
                };

                for ( var name in this.__relationships__ ) {
                    if ( $.isArray( this.__relationships__[ name ] ) ) {
                        json.data.relationships[ name ] = { data: [] };
                        for ( var i = 0; i < this[ name ].length; i++ ) {
                            json.data.relationships[ name ].data.push( {
                                id: this[ name ][i].id,
                                type: this[ name ][i].__type__
                            } );
                        }
                    } else {
                        if ( this[ name ] && this[ name ].id !== null ) {
                            json.data.relationships[ name ] = {
                                data: {
                                    id: this[ name ].id,
                                    type: this[ name ].__type__
                                }
                            };
                        } else {
                            json.data.relationships[ name ] = {
                                data: null
                            };
                        }
                    }
                }

                return json;
            }

            Model.prototype.jsonify = function() {
                return this._jsonify();
            }

            Model.prototype.request = function( url, type, contentType ) {
                var self = this;
                return request.call( this, url, type, this.__includes__, contentType );
            }

            Model.prototype.fetch = function( deep ) {
                var id = ( this[ this.__slug__ ] || this.id );
                if ( id === null || id === undefined ) {
                    console.warn( 'JSONAPI', 'Tried to fetch \'' + this.__type__ + '\' without ID' );
                    return $.Deferred().reject();
                }
                if ( deep ) console.warn( 'JSONAPI', 'Deep Fetch NOT IMPLEMENTED' );
                return this.request( this.__url__ + '/' + id, 'GET' );
            }

            Model.prototype.post = function() {
                if ( this.id === null || this.id === undefined ) {
                    if ( this.beforeUpdate ) this.beforeUpdate();
                    return this.request( this.__url__ + '/', 'POST' );
                } else {
                    return this.update();
                }
            }

            Model.prototype.update = function( createIfNeeded ) {
                if ( this.id === null || this.id === undefined ) {
                    if ( createIfNeeded === true ) {
                        return this.post();
                    } else {
                        console.error( 'JSONAPI', 'Tried to update \'' + this.__type__ + '\' without ID' );
                        return error( this, 'No Model ID' );
                    }
                }
                if ( this.beforeUpdate ) this.beforeUpdate();
                return this.request( this.__url__ + '/' + ( this[ this.__slug__ ] || this.id ), 'PUT' );
            }

            Model.prototype.delete = function() {
                if ( this.id === null || this.id === undefined ) {
                    console.error( 'JSONAPI', 'Tried to delete \'' + this.__type__ + '\' without ID' );
                    return error( this, 'No Model ID' );
                }
                // return error( this, 'Delete not implemented' );
                return this.request( this.__url__ + '/' + ( this[ this.__slug__ ] || this.id ), 'DELETE' );
            }

            Model.prototype.import = function( data ) {
                if ( !data ) return;
                for ( var name in this.__attributes__ ) {
                    if ( data[ name ] !== undefined ) {
                        // TODO: Add validation and type checking
                        if ( this.__attributes__[ name ].type === Date ) {
                            this[ name ] = new Date( data[ name ] );
                        } else {
                            this[ name ] = data[ name ];
                        }
                    }
                }
            }

            Model.prototype.reset = function() {
                for ( var name in this.__attributes__ ) {
                    this[ name ] = this.__attributes__[ name ].default;
                }
                for ( var name in this.__relationships__ ) {
                    if ( $.isArray( this.__relationships__[ name ] ) ) {
                        this[ name ].splice( 0, this[ name ].length );
                    } else {
                        this[ name ] = API.create( this.__relationships__[ name ] );
                    }
                }
                if ( this.afterCreate ) this.afterCreate();
            }

            Model.prototype.in = function( array ) {
                if ( !$.isArray( array ) ) return false;
                for ( var i = array.length - 1; i >= 0; i-- ) {
                    if ( !array[i] ) continue;
                    if ( array[i].id == this.id ) {
                        if ( ( array[i].__type__ || array[i].type ) == this.__type__ ) {
                            return array[i];
                        }
                    }
                }
                return false;
            }

            Model.prototype.is = function( name ) {
                return this instanceof registrar[ name ];
            }
            return Model;
        })();

        /** Registration / Model Creation **/

        this.define = function( name, options ) {
            if ( registrar[ name ] !== undefined ) {
                console.error( 'JSONAPI', 'The model name \'' + name + '\' has already been defined.' );
                return;
            }
            // Normalize Attributes/Relationships/Hook Lists
            // options.hooks = normalizeHooks( options.hooks );
            options.attributes = normalizeAttributes( options.attributes );
            options.relationships = normalizeRelationships( options.relationships );
            // Create a submodel that extends Model
            function DefinedModel( data ) {
                API.Model.call( this, name, options.attributes, options.relationships, options.hooks, options.includes );
                Object.defineProperty( this, '__url__', { value: options.url || name } );
                Object.defineProperty( this, '__slug__', { value: options.slug || 'id' } );
                this.import( data );
            }
            extend( this.Model, DefinedModel );
            // Add provided methods to the Model
            if ( options.methods && $.isPlainObject( options.methods ) ) {
                for ( var func in options.methods ) {
                    if ( $.isFunction( options.methods[ func ] ) ) {
                        DefinedModel.prototype[ func ] = options.methods[ func ];
                    }
                }
            }
            registrar[ name ] = DefinedModel;
            console.info( 'JSONAPI', 'The model name \'' + name + '\' has been defined.' );
        }

        this.create = function( name, data ) {
            if ( registrar[ name ] === undefined ) {
                console.error( 'JSONAPI', 'The model name \'' + name + '\' has not been defined.' );
                return null;
            }
            return new registrar[ name ]( data );
        }

        this.find = function( name, id ) {
            var model = this.create( name, { id: id } );
            return ( model instanceof API.Model ) ? model.fetch() : $.Deferred().reject();
        }

        this.parse = function( json ) {
            return parse( json || {} );
        }

        this.all = function( name ) {
            var model = this.create( name.split('?')[0] );
            if ( model === null ) return $.Deferred().reject();
            return request( name, 'get', model.__includes__ );
        }
    }
    return JSONAPI;
})(jQuery);
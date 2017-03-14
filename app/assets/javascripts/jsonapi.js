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
            attributes = $.extend( attributes || {}, { id: Number } );
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

        /** Default Resource Model **/
        this.Model = (function() {
            function Model( type, attributes, relationships, hooks, includes ) {
                Object.defineProperty( this, '__type__', { value: type } );
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
                                value: property.default || null,
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
                            value: $.isArray( relationships[ name ] ) ? [] : API.create( relationships[ name ] ),
                            enumerable: true,
                            configurable: true,
                            writable: true
                        } );
                    }
                }
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
                                    var cached = model.in( cache )
                                    this[ name ].push( cached || model );
                                    cached || cache.push( model );
                                }
                            }
                        } else {
                            if ( $.isPlainObject( data ) ) {
                                if ( this[ name ].id != data.id ) {
                                    var model = API.create( data.type, { id: data.id } );
                                    this[ name ] = model.in( cache ) || model;
                                }
                                this[ name ].in( cache ) || cache.push( this[ name ] );
                            } else {
                                this[ name ] = API.create( this.__relationships__[ name ] );
                            }
                        }
                    }
                }

                return cache;
            }

            Model.prototype.jsonify = function() {
                var json = {
                     data: {
                        type: this.__type__,
                        id: this.id,
                        attributes: {},
                        relationships: {}
                     }
                };

                for ( var name in this.__attributes__ ) {
                    json.data.attributes[ name ] = this[ name ];
                }

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

            Model.prototype.request = function( url, type ) {
                type = type.toLowerCase();
                if ( $.inArray( type, [ 'get', 'put', 'post', 'patch', 'delete' ] ) === -1 ) {
                    console.error( 'JSONAPI', 'Invalid request type \'' + type + ' \'for \' ' + this.__type__ + '\' model.' );
                    return $.Deferred().reject();
                }
                var self = this;
                var getData = $.isArray( this.__includes__ ) ? { include: this.__includes__.join( ',' ) } : null;
                return $.ajax( apiurl + '/' + url, {
                        type: type,
                        headers: {
                            'Accepted': 'application/vnd.api+json',
                            'Content-Type': ( type !== 'get' ) ? 'application/vnd.api+json' : undefined
                        },
                        data: ( type !== 'get' ) ? JSON.stringify( this.jsonify() ) : getData
                    } )
                    .done( function( json ) {
                        console.log( json );
                        if ( json.data === null ) {
                            console.warn( 'JSONAPI', 'Server does not recognize the \'' + self.__type__ + '\' model ID.' );
                            return;
                        }
                        // Server must return a single object of the correct type
                        if ( !$.isPlainObject( json.data ) || json.data.type !== self.__type__ ) {
                            console.error( 'JSONAPI', 'Invalid JSON API response for \'' + self.__type__ + '\' model.' );
                            return $.Deferred().reject();
                        }
                        var cache = self.parse( json.data, [ self ] );
                        for ( var i = cache.length - 1; i >= 0; i-- ) {
                            if ( cache[i] === self ) continue;
                            var data = cache[i].in( json.included );
                            if ( data !== false ) {
                                cache[i].parse( data, cache );
                            }
                        }
                        console.info( 'JSONAPI', 'Parsed JSON API respone for \'' + self.__type__ + '\' model.' );

                        if ( self.afterRequest ) this.afterRequest();
                    } )
                    .fail( function( a,b,c ) {
                        if ( a.status === 404 ) {
                            console.warn( 'JSONAPI', 'Server does not recognize the \'' + self.__type__ + '\' model ID.' );
                        } else if ( a.status === 400 ) {
                            console.error( 'JSONAPI', 'Server reported a protocol violation on \'' + self.__type__ + '\' model.' )
                        }
                    } );
            }

            Model.prototype.fetch = function( deep ) {
                if ( this.id === null || this.id === undefined ) {
                    console.warn( 'JSONAPI', 'Tried to fetch \'' + this.__type + '\' without ID' );
                    return $.Deferred().reject();
                }
                if ( deep ) console.warn( 'JSONAPI', 'Deep Fetch NOT IMPLEMENTED' );
                return this.request( this.__type__ + '/' + this.id, 'GET' );
            }

            Model.prototype.post = function() {
                if ( this.id === null || this.id === undefined ) {
                    console.warn( 'JSONAPI', 'Tried to post \'' + this.__type + '\' without ID' );
                    return $.Deferred().reject();
                }
                console.warn( 'JSONAPI', 'Post not implemented.' );
                return $.Deferred().resolve();
            }

            Model.prototype.update = function() {
                if ( this.id === null || this.id === undefined ) {
                    console.warn( 'JSONAPI', 'Tried to update \'' + this.__type + '\' without ID' );
                    return $.Deferred().reject();
                }
                console.warn( 'JSONAPI', 'Update not implemented.' );
                return $.Deferred().resolve();
                // return this.request( this.__type__ + '/' + this.id, 'PUT' );
            }

            Model.prototype.delete = function() {
                if ( this.id === null || this.id === undefined ) {
                    console.warn( 'JSONAPI', 'Tried to delete \'' + this.__type + '\' without ID' );
                    return $.Deferred().reject();
                }
                console.warn( 'JSONAPI', 'Delete not implemented.' );
                return $.Deferred().resolve();
                // return this.request( this.__type__ + '/' + this.id, 'DELETE' );
            }

            Model.prototype.import = function( data ) {
                for ( var name in data ) {
                    if ( this.__attributes__[ name ] !== undefined ) {
                        // TODO: Add validation and type checking
                        if ( this.__attributes__[ name ].type === Date ) {
                            this[ name ] = new Date( data[ name ] );
                        } else {
                            this[ name ] = data[ name ];
                        }
                    }
                }
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
    }
    return JSONAPI;
})(jQuery);
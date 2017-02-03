(function ($) {

    /**
     * Blanks for adding new items to lists. Vuejs 
     * will not work if these are not defined.
     */
    var blanks = {
        participant: {
            first: '',
            last: '',
            dob: '',
            email: '',
            phone: '',
            gender: '',
            bibnumber: '',
            beacon: '',
            city: '',
            state: '',
            country: ''
        },
        split: {
            name: '',
            description: '',
            distance: '',
            times: '',
            times: '',
            verticalGain: '',
            verticalLoss: '',
            locationName: '',
            lat: '',
            lng: '',
            elevation: ''
        }
    }

    /**
     * UI object for the live event view
     *
     */
    var eventStage = {

        router: null,
        app: null,
        data: {
            eventData: {
                race: {
                    name: ''
                },
                event: {
                    name: '',
                    description: '',
                    date: '',
                    hours: 06,
                    minutes: 00,
                    laps: false
                },
                course: {
                    new: false,
                    name: '',
                },
                participants: [ $.extend( {}, blanks.participant, { first: 'Abram', last: 'Early', gender: 'M' } ) ],
                splits: [
                    {
                        name: 'Starting Line',
                        lat: 39.978915,
                        lng: -105.131036,
                        distance: 0,
                        verticalGain: 0,
                        verticalLoss: 0
                    },
                    {
                        name: 'Endling Line',
                        lat: 39.982682,
                        lng: -105.132188,
                        distance: 0,
                        verticalGain: 0,
                        verticalLoss: 0
                    }
                ]
            }
        },

        isEventValid: function( eventData ) {
            if ( ! eventData.race.name ) return false;
            if ( ! eventData.event.name ) return false;
            if ( ! eventData.course.name ) return false;
            return true;
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

            // Initialize Vue Router and Vue App
            const routes = [
                { 
                    path: '/', 
                    component: {
                        props: ['eventData'],
                        methods: {
                            isEventValid: function() {
                                return eventStage.isEventValid( this.eventData );
                            }
                        },
                        template: '#event'
                    }
                },
                { 
                    path: '/splits', 
                    component: {
                        props: ['eventData'],
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
                                return $.extend( {}, blanks.split );
                            }
                        },
                        data: function() { return { modalData: {}, filter: '' } },
                        template: '#splits'
                    },
                    beforeEnter: function( to, from, next ) {
                        next( eventStage.isEventValid( eventStage.data.eventData ) ? undefined : '/' );
                    }
                },
                { 
                    path: '/participants', 
                    component: { 
                        props: ['eventData'], 
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
                                return $.extend( {}, blanks.participant );
                            }
                        },
                        data: function() { return { modalData: {}, filter: '' } }, 
                        template: '#participants'
                    },
                    beforeEnter: function( to, from, next ) {
                        next( eventStage.isEventValid( eventStage.data.eventData ) ? undefined : '/' );
                    }
                },
                { 
                    path: '/confirmation', 
                    component: { props: ['eventData'], template: '#confirmation' },
                    beforeEnter: function( to, from, next ) {
                        next( eventStage.isEventValid( eventStage.data.eventData ) ? undefined : '/' );
                    }
                },
                { 
                    path: '/published', 
                    component: { template: '#published' },
                    beforeEnter: function( to, from, next ) {
                        next( eventStage.isEventValid( eventStage.data.eventData ) ? undefined : '/' );
                    }
                }
            ];
            var router = new VueRouter( {
                routes
            } );
            eventStage.router = router;
            eventStage.app = new Vue( {
                router,
                el: '#event-app',
                data: eventStage.data
            });
            router.afterEach( function( a, b, c ) {
                eventStage.app.$nextTick( function() {
                    $( eventStage.app.$el ).trigger( 'vue-ready' );
                } );
            } );
        },

        dataTables: {
            uniqueId: 1,
            onDataChange: function() {
                if ( !this.rows || !$.isArray( this.rows ) ) return;
                var self = this;
                this.rows.forEach( function( obj, index ) {
                    if ( !obj._dtid ) {
                        // New Data: Add Index and Add to Table
                        obj._dtid = eventStage.dataTables.uniqueId++;
                        var row = new self._row( { data: { row: obj } } ).$mount();
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
                } );
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
                            handler: function() {
                                // TODO: Add Debouncer
                                this.$nextTick( function() {
                                    self._table.row( this.$el ).invalidate( 'dom' ).draw();
                                } );
                            },
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

        googleMaps: {
            onMarkerChange: function() {
                if ( this.markers ) {
                    // Remove Old Markers/Polyline
                    if ( this._markers ) {
                        for ( var i = 0; i < this._markers.length; i++ ) {
                            this._markers[i].setMap( null );
                        }
                        this._markers = [];
                    }
                    if ( this._polyline ) {
                        this._polyline.setMap( null );
                        this._polyline = null;
                    }

                    // Add New Markers/Polyline and Resize Map
                    var bounds = new google.maps.LatLngBounds();
                    var path = [];
                    for ( var i = 0; i < this.markers.length; i++ ) {
                        if ( isNaN( parseFloat( this.markers[i].lat ) ) || isNaN( parseFloat( this.markers[i].lng ) ) ) continue;
                        var marker = new google.maps.Marker( {
                            position: { lat: parseFloat( this.markers[i].lat ) , lng: parseFloat( this.markers[i].lng ) },
                            map: this._map,
                            title: this.markers[i].name,
                            label: i + 1 + ''
                        } );
                        this._markers.push( marker );
                        path.push( { lat: parseFloat( this.markers[i].lat ) , lng: parseFloat( this.markers[i].lng ) } );
                        bounds.extend( marker.getPosition() );
                    }
                    this._map.fitBounds( bounds );
                    this._polyline = new google.maps.Polyline( {
                        path: path,
                        map: this._map,
                        geodesic: true,
                        strokeColor: '#2A9FD8',
                        strokeOpacity: 1.0,
                        strokeWeight: 6
                    } );
                }
            },
            onMapClick: function( e ) {
                if ( this.location ) {
                    this.location.lat = e.latLng.lat();
                    this.location.lng = e.latLng.lng();
                }
            },
            onMounted: function() {
                var self = this;
                this._markers = [];
                this._polyline = null;
                this._map = new google.maps.Map( this.$el, {
                    center: { lat: -34.397, lng: 150.644 },
                    zoom: 1
                } );
                this._map.addListener( 'click', function( e ) {
                    eventStage.googleMaps.onMapClick.call( self, e );
                } );
                eventStage.googleMaps.onMarkerChange.call( this );
            },
            init: function() {
                Vue.component( 'google-map', {
                    template: '<div class="splits-modal-map-wrap"></div>',
                    props: { markers: { default: null }, location: { default: null } },
                    mounted: eventStage.googleMaps.onMounted,
                    watch: {
                        markers: {
                            handler: eventStage.googleMaps.onMarkerChange,
                            deep: true
                        }
                    }
                } );
            }
        },

        /**
         *  Editing Modal Component
         */
         editModal: {
            init: function() {
                Vue.component( 'edit-modal', {
                    template: '<div>No Template</div>',
                    props: {
                        value: { required: true },
                        validator: { 
                            type: Function,
                            default: function() { return true; }
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
                            self.model = $.extend( {}, self.value );
                        };
                        $( this.$el ).on( 'show.bs.modal hidden.bs.modal', reset );
                        this.$on( 'cancel', reset );
                        this.$on( 'done', function() {
                            // Copy properties to original object
                            // for ( var prop in self.model ) {
                            //     if( self.model.hasOwnProperty( prop ) ) {
                            //         Vue.set( self.value, prop, self.model[ prop ] );
                            //     }
                            // }
                            $.extend( self.value, self.model );
                        } );
                    },
                    data: function() { return { model: {}, valid: false }; }
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
            onMounted: function( a,b,c ) {
                var data = $.extend( {}, this.data );
                var self = this;

                // Mark existing entries
                $( this.$el ).find( 'option' ).addClass( 'static' );

                // Fetch New Entries
                $.ajax( this.url, {
                    method: this.method,
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
                        url: { type: String, required: true, default: '' }
                    },
                    template: '<select><slot></slot></select>',
                    mounted: eventStage.ajaxSelect.onMounted
                } );
            }
         }
    };

    $( 'body.stage' ).ready(function () {
        eventStage.init();
    });

    window.eventStage = eventStage;
})(jQuery);

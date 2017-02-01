(function ($) {

    /**
     * UI object for the live event view
     *
     */
    var eventStage = {

        router: null,
        app: null,
        data: {
            eventData: {
                event: {
                    name: '',
                    description: '',
                    date: '',
                    hours: 06,
                    minutes: 00
                },
                course: {
                    new: false,
                    name: '',
                },
                participants: [ { name: 'Abram' }, { name: 'Winter' }, { name: 'Daniel' }, { name: 'Mark' }, { name: 'Laura' }, { name: 'Adam' }, { name: 'Steven' }, { name: 'Eric' }, { name: 'Laurel' }, { name: 'Justin' } ],
                splits: [
                    {
                        name: 'Starting Line',
                        lat: 0,
                        lng: 0,
                        distance: 0,
                        verticalGain: 0,
                        verticalLoss: 0
                    }
                ]
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
            Vue.component( 'split-modal', { template: '#split-modal', props: [ 'split', 'isNew' ], methods: { isValid: function() {
                return false;
            } } } );
            Vue.component( 'participant-modal', { template: '#participant-modal', props: [ 'participant', 'isNew' ], methods: { isValid: function() {
                return false;
            } } } );

            // Initialize Vue Router and Vue App
            const routes = [
                { 
                    path: '/', 
                    component: { props: ['eventData'], template: '#event' }
                },
                { 
                    path: '/splits', 
                    component: { props: ['eventData'], data: function() { return { modalSplit: {}, modalNew: false }; }, template: '#splits' }
                },
                { 
                    path: '/participants', 
                    component: { props: ['eventData'], data: function() { return { modalData: {}, modalNew: false }; }, template: '#participants' }
                },
                { 
                    path: '/confirmation', 
                    component: { props: ['eventData'], template: '#confirmation' }
                },
                { 
                    path: '/published', 
                    component: { template: '#published' }
                }
            ];
            const router = new VueRouter( {
                routes
            } );
            eventStage.router = router;
            eventStage.app = new Vue( {
                router,
                el: '#event-app',
                data: eventStage.data
            });
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
                        var row = new self._row( { propsData: { row: obj } } ).$mount();
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
            onDestroyed: function() {
                // Erase DataTable IDs
                this.rows.forEach( function( obj, index ) {
                    obj._dtid = null;
                } );
            },
            onMounted: function() {
                this._queue = [];
                this._table = $( this.$el ).DataTable( {
                    oLanguage: {
                        'sSearch': 'Filter:&nbsp;'
                    }
                } );
                // Create render Function for Table Rows
                var self = this;
                this._row = Vue.extend( {
                    props: [ 'row' ],
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
                        rows: {
                            handler: eventStage.dataTables.onDataChange,
                            deep: true
                        }
                    }
                } );
            }
        },

        googleMaps: {
            onChange: function() {
                // Remove Old Markers
                if ( this._markers ) {
                    for ( var i = 0; i < this._markers.length; i++ ) {
                        this._markers[i].setMap( null );
                    }
                    this._markers = [];
                }

                // Add New Markers and Resize Map
                var bounds = new google.maps.LatLngBounds();
                for ( var i = 0; i < this.markers.length; i++ ) {
                    if ( isNaN( parseFloat( this.markers[i].lat ) ) || isNaN( parseFloat( this.markers[i].lng ) ) ) continue;
                    var marker = new google.maps.Marker( {
                        position: { lat: parseFloat( this.markers[i].lat ) , lng: parseFloat( this.markers[i].lng ) },
                        map: this._map,
                        title: this.markers[i].name
                    } );
                    this._markers.push( marker );
                    bounds.extend( marker.getPosition() );
                }
                this._map.fitBounds( bounds );
            },
            onMounted: function() {
                this._markers = [];
                this._map = new google.maps.Map( this.$el, {
                    center: { lat: -34.397, lng: 150.644 },
                    zoom: 1
                } );
                eventStage.googleMaps.onChange.call( this );
            },
            init: function() {
                Vue.component( 'google-map', {
                    template: '<div style="min-height: 300px"></div>',
                    props: { markers: { default: [] } },
                    mounted: eventStage.googleMaps.onMounted,
                    watch: {
                        markers: {
                            handler: eventStage.googleMaps.onChange,
                            deep: true
                        }
                    }
                } );
            }
        }
    };

    $( 'body.stage' ).ready(function () {
        eventStage.init();
    });

    window.eventStage = eventStage;
})(jQuery);
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
                participants: [
                ],
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
            Vue.component( 'split-modal', { template: '#split-modal', props: [ 'split', 'isNew' ], methods: { isValid: function() {
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
                    component: { template: '#participants' }
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
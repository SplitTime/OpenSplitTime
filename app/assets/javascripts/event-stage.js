(function ($) {

    /**
     * UI object for the live event view
     *
     */
    var eventStage = {

        router: null,
        app: null,

        /**
         * This kicks off the full UI
         *
         */
        init: function () {

            // Initialize Vue Router and Vue App
            const routes = [
                { 
                    path: '/', 
                    component: { template: '#event' }
                },
                { 
                    path: '/splits', 
                    component: { template: '#splits' }
                },
                { 
                    path: '/participants', 
                    component: { template: '#participants' }
                },
                { 
                    path: '/confirmation', 
                    component: { template: '#confirmation' }
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
                router
            }).$mount( '#app' );

        },
    };

    $( 'body.stage' ).ready(function () {
        eventStage.init();
    });
})(jQuery);
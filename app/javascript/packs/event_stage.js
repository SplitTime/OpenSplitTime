import Inputmask from "inputmask/dist/jquery.inputmask";
import "datatables.net-bs5";
import Vue from "vue";
import VueRouter from "vue-router";
import TurboLinksAdapter from "vue-turbolinks";

Vue.use(TurboLinksAdapter);
Vue.use( VueRouter );
Vue.filter( 'padding', function( value, length, character ) {
  var strlen = ( value + '' ).length;
  for ( strlen; strlen < length; strlen++ ) {
    value = ( character ).concat( value );
  }
  return value;
} );

import "event_stage/index";

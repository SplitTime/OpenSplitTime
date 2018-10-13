// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery-ui/effects/effect-highlight
//= require rails-ujs
//= require twitter/bootstrap
//= require turbolinks
//= require jquery-readyselector
//= require jquery-fileupload/basic
//= require switchery
//= require moment
//= require bootstrap-datetimepicker
//= require vue
//= require vue-router
//= require local-time
//= require_tree .

Vue.use( VueRouter );
Vue.filter( 'padding', function( value, length, character ) {
	var strlen = ( value + '' ).length;
	for ( strlen; strlen < length; strlen++ ) {
		value = ( character ).concat( value );
	}
	return value;
} );
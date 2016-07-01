(function($) {
	homepage = {
		$parallaxDivs:null,
		init:function() {
			homepage.$parallaxDivs = $('.homepage .first, .homepage .third, .homepage .fifth');
			$(window).on('scroll', homepage.parallax);
		},
		parallax:function() {
			homepage.$parallaxDivs.each(function(){
				var $this = $(this);
				var scrollTop = $(window).scrollTop();
				var bgTopPosition = ($this.offset().top - scrollTop) * .2;
				if (bgTopPosition < 0) {
					bgTopPosition = 0;
				}
				$this.css('background-position', '0 ' + bgTopPosition + 'px')
			} );
		}
	}
	$(document).ready(function() {
		homepage.init();
	});
})(jQuery);
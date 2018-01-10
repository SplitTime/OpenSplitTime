(function($) {
	homepage = {
		$parallaxDivs:null,
		lastScrollTop:null,
		isMobile:function() {
			return ( /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) );
		},
		init:function() {
			homepage.$parallaxDivs = $('.homepage .first, .homepage .third, .homepage .fifth');
			if ( ! homepage.isMobile() ) {
				window.requestAnimationFrame( homepage.parallax );	
			}
		},
		parallax:function() {
			var scrollTop = $(window).scrollTop();

			if ( !homepage.lastScrollTop || homepage.lastScrollTop !== scrollTop ) {
				homepage.lastScrollTop = scrollTop;

				homepage.$parallaxDivs.each(function( index ){
					var $this = $(this);
					var bgTopPosition = Math.floor( -($this.offset().top - scrollTop) * .3 - 30 );
					$this.css('background-position', 'center ' + bgTopPosition + 'px');
				});
			}
			window.requestAnimationFrame( homepage.parallax );
		}
	}
    document.addEventListener("turbolinks:load", function() {
		homepage.init();
	});
})(jQuery);

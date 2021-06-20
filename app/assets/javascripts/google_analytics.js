document.addEventListener('turbo:load', function(event) {
    if (typeof ga === 'function') {
        ga('set', 'location', event.data.url);
        ga('send', 'pageview');
    }
});

import { Controller } from "@hotwired/stimulus"
import { isMobileSafari } from "utils";

function safeParse(str) {
    try {
        return JSON.parse(str);
    } catch (e) {
        return null;
    }
}

export default class extends Controller {
    connect() {
        let effortIds = safeParse(this.element.dataset.effortIds);
        let theme = this.element.dataset.theme;
        let $self = $(this.element);
        $self.attr('tabindex', $self.attr('tabindex') || '0')
            .attr('role', 'button')
            .data('ajax', null)
            .css('cursor', 'pointer')
            .popover({
                'html': true,
                'trigger': 'focus',
                'container': 'body'
            });
        let popover = $self.data('bs.popover');
        this.allowListAdditions(popover.config);
        $self.on('show.bs.popover', (event) => {
            if (effortIds) {
                var ajax = $self.data('ajax');
                if (!ajax || typeof ajax.status == 'undefined') {
                    $(popover.tip).addClass('efforts-popover');
                    var data = {effortIds};
                    $self.data('ajax', $.post('/efforts/mini_table/', data)
                        .done(function (response) {
                            popover.config.content = response;
                            popover.show();
                        }).always(function () {
                            $self.data('ajax', null);
                        })
                    );
                    event.preventDefault();
                }
            } else {
                $(popover.tip).addClass('static-popover');
                if (theme) {
                    $(popover.tip).addClass(`static-popover-${theme}`);
                }
            }
        });
        if (isMobileSafari()) {
            $('body').css('cursor', 'pointer');
        }
    }

    allowListAdditions(popoverConfig) {
        popoverConfig.allowList['table'] = [];
        popoverConfig.allowList['thead'] = [];
        popoverConfig.allowList['tbody'] = [];
        popoverConfig.allowList['tr'] = [];
        popoverConfig.allowList['td'] = [];
        popoverConfig.allowList['th'] = [];
    }
}

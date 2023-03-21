import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    effortIds: Array,
    theme: String,
  }

  connect() {
    const theme = this.themeValue
    const popover = window.bootstrap.Popover.getInstance(this.element)

    this.element.addEventListener("inserted.bs.popover", function () {
      popover.tip.classList.add("static-popover");

      if (theme) {
        popover.tip.classList.add(`static-popover-${theme}`);
      }
    })
  }

  // connect() {
  //     let effortIds = safeParse(this.element.dataset.effortIds);
  //     let theme = this.element.dataset.theme;
  //     let $self = $(this.element);
  //     $self.attr('tabindex', $self.attr('tabindex') || '0')
  //         .attr('role', 'button')
  //         .data('ajax', null)
  //         .css('cursor', 'pointer')
  //         .popover({
  //             'html': true,
  //             'trigger': 'focus',
  //             'container': 'body'
  //         });
  //     let popover = $self.data('bs.popover');
  //     this.allowListAdditions(popover.config);
  //     $self.on('show.bs.popover', (event) => {
  //         if (effortIds) {
  //             var ajax = $self.data('ajax');
  //             if (!ajax || typeof ajax.status == 'undefined') {
  //                 $(popover.tip).addClass('efforts-popover');
  //                 var data = {effortIds};
  //                 $self.data('ajax', $.post('/efforts/mini_table/', data)
  //                     .done(function (response) {
  //                         popover.config.content = response;
  //                         popover.show();
  //                     }).always(function () {
  //                         $self.data('ajax', null);
  //                     })
  //                 );
  //                 event.preventDefault();
  //             }
  //         } else {
  //             $(popover.tip).addClass('static-popover');
  //             if (theme) {
  //                 $(popover.tip).addClass(`static-popover-${theme}`);
  //             }
  //         }
  //     });
  // }
}

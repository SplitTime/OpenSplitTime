import {Controller} from "stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {

    connect() {
        let notificationController = this;

        this.subscription = consumer.subscriptions.create(
            {
                channel: this.data.get("channel"),
                id: this.data.get("id")
            },
            {
                connected() {
                    notificationController.triggerRawTimesPush();
                },
                disconnected() {
                },
                received(data) {
                    const unreviewedCount = (typeof data.unreviewed === 'number') ? data.unreviewed : 0;
                    const unmatchedCount = (typeof data.unmatched === 'number') ? data.unmatched : 0;
                    notificationController.displayNewCount(unreviewedCount, unmatchedCount);
                }
            }
        )
    }

    disconnect() {
        this.subscription.unsubscribe();
    }

    displayNewCount(unreviewedCount, unmatchedCount) {
        const unreviewedText = (unreviewedCount > 0) ? unreviewedCount : '';
        const unmatchedText = (unmatchedCount > 0) ? unmatchedCount : '';
        $('#js-pull-times-count').text(unreviewedText);
        $('#js-force-pull-times-count').text(unmatchedText);

        if (unreviewedCount > 0) {
            const notifier = this.data.get("notifier");

            if (!notifier || !notifier.$ele.is(':visible') || notifier.$ele.data('closing')) {
                const newNotifier = $.notify({
                    icon: 'fas fa-stopwatch',
                    title: 'New Live Times Available',
                    message: 'Click to pull times.',
                    url: '#js-pull-times',
                    target: '_self'
                }, {delay: 0});

                this.data.set("notifier", newNotifier)
            }
        } else if (notifier) {
            notifier.close();
        }
    }

    triggerRawTimesPush() {
        const url = "/api/v1/event_groups/" + this.data.get("id") + "/trigger_raw_times_push";
        $.ajax({
            url: url,
            cache: false
        });
    }
}

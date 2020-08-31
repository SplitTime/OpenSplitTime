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
                    console.log(data)
                }
            }
        )
    }

    disconnect() {

        console.log("disconnected from stimulus controller")

        this.subscription.unsubscribe();
    }
    
    triggerRawTimesPush() {
        const url = "/api/v1/event_groups/" + this.data.get("id") + "/trigger_raw_times_push";
        $.ajax({
            url: url,
            cache: false
        });
    }
}

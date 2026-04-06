---
title: Create and Activate an Exporter
parent: RaceResult RFID Integration
nav_order: 3
---

# Create and Activate an Exporter <span class="label">Beta</span>

## 1. Find your OpenSplitTime webhook token

In OpenSplitTime, make sure you are logged in and go to your Event Group. Click **Admin** → **Construction** → **Status**.

Make sure Live Entry is enabled — the **RaceResult RFID Integration** card will only appear when Live Entry is active. If it is not enabled, click **Enable Live Entry** on the same page.

In the **RaceResult RFID Integration** card, if a webhook token has not yet been generated, click **Set Token** to generate one. Once a token exists, the **Webhook URL** and **Post Body Expression** fields will be displayed. You will need both of these values in the next step.

## 2. Create an exporter

In the left panel of RaceResult, go to **Timing** → **Settings** → **Exporters + Tracking**. Add a new **Exporter** with the following settings:

- **Name**: OST Webhook (or whatever name you prefer)
- **TimingPoint/Split**: <All Timing Points>
- **Filter**: Leave as blank
- **Destination**: HTTP(S) Post, then copy the **Webhook URL** from the OpenSplitTime setup summary page into the next field. The URL will look something like this:

  `https://opensplittime.org/webhooks/raceresult?token=abc123def456`

- **Export Data**: Custom, then copy the **Post Body Expression** from the OpenSplitTime setup summary page into the next field. The post body will look something like this:

  `'{"record": ' & [RD_RecordJSON] & ', "event_group_name": "my-event-group"}'`
- **LineEnd**: CRLF

### A sample configuration is shown below:

![RaceResult Exporter Configuration](../assets/images/docs/race_result/race_result_doc_3.png)

## 3. Activate the exporter

In the left panel, go to **Timing** → **Chip Timing** → **Chip Timing**. Under the **Exporters + Tracking** section, locate the exporter created in the previous step and activate it by pressing the green triangle button.

![RaceResult Exporter Activation](../assets/images/docs/race_result/race_result_doc_4.png)

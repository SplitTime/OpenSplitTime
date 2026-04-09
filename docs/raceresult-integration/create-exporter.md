---
title: Create and Activate an Exporter
parent: RaceResult RFID Integration
nav_order: 3
---

# Create and Activate an Exporter <span class="label">Beta</span>

## 1. Find your OpenSplitTime webhook token

In OpenSplitTime, make sure you are logged in and go to your Event Group. Click **Admin** → **Construction** → **Status**.

![OST instruction to Admin/Construction tab](/assets/images/docs/race_result/race_result_doc_5.png)

![OST status icon](/assets/images/docs/race_result/race_result_doc_6.png)

Make sure [Live Entry is enabled](../confirm-data-flow/) — the **RaceResult RFID Integration** card will only appear when Live Entry is active. If it is not enabled, click **Enable Live Entry** on the same page.

In the **RaceResult RFID Integration** card, if a webhook token has not yet been generated, click **Set Token** to generate one. Once a token exists, the **Webhook URL** field will be displayed. You will need this URL in the next step.

![OST get webhook token](/assets/images/docs/race_result/race_result_doc_8.png)

## 2. Create an exporter

In the left panel of RaceResult, go to **Timing** → **Settings** → **Exporters + Tracking**. Add a new **Exporter** with the following settings:

- **Name**: `OST Webhook` (or whatever name you prefer)
- **TimingPoint/Split**: `<All Timing Points>`
- **Filter**: Leave this field blank
- **Destination**: `HTTP(S) Post`, then copy the **Webhook URL** from the OpenSplitTime **Admin** → **Construction** → **Status** page into the next field. Do not use the example below — always copy your actual URL from OpenSplitTime, as it contains a unique token and Event Group identifier.

  Example: `https://www.opensplittime.org/webhooks/raceresult?token=abc123def456&event_group_name=my-event-group`

- **Export Data**: Select `Raw Data Record JSON` from the dropdown
- **LineEnd**: `CRLF`

### A sample configuration is shown below:

![RaceResult Exporter Configuration](/assets/images/docs/race_result/race_result_doc_3.png)

## 3. Activate the exporter

In the left panel, go to **Timing** → **Chip Timing** → **Chip Timing**. Under the **Exporters + Tracking** section, locate the exporter created in the previous step and activate it by pressing the green triangle button.

![RaceResult Exporter Activation](/assets/images/docs/race_result/race_result_doc_4.png)

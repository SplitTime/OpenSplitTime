---
title: Overview
parent: RaceResult RFID Integration
nav_order: 1
---

# RaceResult RFID Integration Overview <span class="label">Beta</span>

[RaceResult](https://www.raceresult.com){:target="_blank"} is a sports timing platform widely used for endurance events. RaceResult RFID decoders read transponders (chips) worn by athletes as they pass through timing points along the course. The RaceResult software collects these readings and can forward them to external systems via webhooks.

OpenSplitTime can be configured to receive timing data from RaceResult webhooks. By connecting RaceResult to OpenSplitTime, RFID chip reads flow automatically into your event's live results as they happen. This guide walks you through setting up that connection.

**Prerequisite:** Live Entry must be enabled for your Event Group before you can configure the RaceResult RFID integration. You can enable it from the **Status** page under **Admin** → **Construction**.

For detailed information about RaceResult hardware and software, see the [RaceResult Knowledge Base](https://www.raceresult.com/en-us/support/kb){:target="_blank"}.

## Steps Overview

1. [**Configure the RaceResult Event**](../configure-event/) — Set up timing points and connect RFID decoders in RaceResult.
2. [**Create and Activate an Exporter**](../create-exporter/) — Generate your OpenSplitTime webhook token, create an exporter in RaceResult, and activate it.
3. [**Confirm Data is Flowing**](../confirm-data-flow/) — Verify that RFID chip reads are arriving in both RaceResult and OpenSplitTime.

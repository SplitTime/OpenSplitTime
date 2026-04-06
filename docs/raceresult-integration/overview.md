---
title: Overview
parent: RaceResult RFID Integration
nav_order: 1
---

# RaceResult RFID Integration Overview <span class="label">Beta</span>

[RaceResult](https://www.raceresult.com){:target="_blank"} is a sports timing platform widely used for endurance events. RaceResult RFID decoders read transponders (chips) worn by athletes as they pass through timing points along the course. The RaceResult software collects these readings and can forward them to external systems via webhooks.

By connecting RaceResult to OpenSplitTime, RFID chip reads flow automatically into your event's live results as they happen. This guide walks you through setting up that connection.

For detailed information about RaceResult hardware and software, see the [RaceResult Knowledge Base](https://www.raceresult.com/en-us/support/kb){:target="_blank"}.

## Steps Overview

1. Opening the target event in RaceResult
2. Configuring timing points to match OpenSplitTime aid stations
3. Connecting and mapping RFID decoders to timing points
4. Finding your OpenSplitTime webhook token
5. Creating an exporter to send data to OpenSplitTime
6. Activating the exporter to start sending live data
7. Confirming that data is flowing in both RaceResult and OpenSplitTime

For full details, see the [Webhook Configuration](webhook-setup/) guide.

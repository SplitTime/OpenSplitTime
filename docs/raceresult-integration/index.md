---
title: RaceResult RFID Integration
has_children: true
nav_order: 4
---

# RaceResult RFID Integration <span class="label">Beta</span>

[RaceResult](https://www.raceresult.com){:target="_blank"} is a sports timing platform that provides RFID-based chip timing hardware and software for endurance events. RaceResult decoders read RFID transponders worn by athletes at timing points along the course, and the RaceResult software can forward this data to external systems via webhooks.

RaceResult RFID can be combined with [OST Remote](../ost-remote/) and other live entry methods to create a hybrid timing system. For example, you might use RFID chip readers at the start and finish lines while volunteers use OST Remote to record times at remote aid stations along the course. All data flows into the same Event Group in OpenSplitTime regardless of the input source.

This section explains how to connect RaceResult to OpenSplitTime so that timing data flows automatically from RFID chip readers into your event's live results.

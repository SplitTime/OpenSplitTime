---
title: Overview
parent: Getting Started
nav_order: 1
---

# Overview

## Welcome

OpenSplitTime is a free and easy service to organize and analyze your timed event data. All this data fits into a
defined pattern, and there is a fair amount of terminology behind it. Things can seem a bit confusing at first, but
it all works out. Here's a short description of the terms you need to know.

All this data is stored in a logical way with proper relations, which makes it possible to do just about
anything you want with it. If you've never seen endurance event data organized like this before, maybe that's
because nobody has gone to the trouble of doing it right before. Some geeky people gave this a lot of
thought. Trust us! The form follows the function.

## Organizations, Courses, and Events

**Organization:** This is the basic administrative unit in
OpenSplitTime, like Hardrock 100. Each Event Group, Event Series,
and Course belongs to an Organization. This is the way you (as the
Organization creator) can create and modify your own Events and invite trusted Stewards to help.

**Course:** The physical course on which your event is run, ridden, flown, or climbed, like Hardrock Clockwise.

**Split:** A point on a course at which times are recorded,
like Kroger Aid Station. A Split may include optional elevation, latitude, and longitude data.

**Event Group:** A group of events happening on or about the same time, like 2019 RUFA. Some
Event Groups will have just one Event, like a 100 miler that has no shorter course alternative. Others will have
multiple Events, like a 30K, 50K, and 100K that are run on the same day.

**Event:** A single running of a race, ride, stage, or other...you
know, event. An example would be the 2026 RUFA (24 hours)

**Person:** A person who has been entered in at least one Event, like Kilian Jornet.

**Entrant:** A Person in a single Event, like Kilian at Hardrock 2016.

## Two Types of Time Records

**Raw Time:** A single time at which a bib number is recorded live at a given Split while an Event is ongoing. 
Raw Times are viewable by Organization personnel and stewards, but **not by the general public**. 
Any number of Raw Times may exist for an entrant at a particular point on the Course. 
This allows multiple devices or methods to be used to input Raw Times.

**Split Time:** A
**publicly viewable** time at which an Entrant is deemed to have been recorded at a given Split. When
Raw Time records are available, Split Times will ideally represent the best possible interpretation of the complete
Raw Time record. Only one Split Time may exist for an entrant at a particular point on the Course.

## Creating Raw Times

Raw Times are created using the Live Entry screen in opensplittime.org, or via [OST Remote](../ost-remote/),
the easy-to-use iOS client app for live time recording, or by [posting time data to the OpenSplitTime API](../api/queries.html#posting-raw-times).

## Creating Split Times

Split Times will normally be created automatically from Raw Times that OpenSplitTime has analyzed and categorized as either
"good" or "questionable." Raw Times that are categorized as "bad" do not result in automatic Split Time creation.

If a Split Time already exists for a given Entrant at a particular point on the Course, any Raw Times for that Entrant
at that point on the Course will be captured as Raw Time records but will not automatically change the existing Split Time.

Split Times may also be created using the **Effort > Audit** view or the
**Effort > Actions > Edit Times** views.

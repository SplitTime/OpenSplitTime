---
title: Event Construction
parent: Getting Started
nav_order: 2
---

# Event Construction

This page walks through assembling everything OpenSplitTime needs before your race day: an Organization, an Event Group, one or more Events, the Course they run on, and the list of Entrants who'll be participating. See the [Overview](overview/) for the meaning of each of these terms.

The flow is:

1. Create an [Organization](#create-an-organization-and-event-group) and [Event Group](#create-an-organization-and-event-group)
2. [Add one or more Events](#add-an-event), choosing or creating a [Course](#set-up-the-course) for each
3. Flesh out each [Course](#set-up-the-course) with splits (aid stations, checkpoints, etc.)
4. [Add Entrants](#add-entrants) by connecting an external registration service or importing a CSV

If you're carrying forward an event from a previous year, [duplicating an existing Event Group](#duplicate-an-existing-event-group) skips most of this.

## Create an Organization and Event Group

[Sign up](https://www.opensplittime.org/users/sign_up) (or sign in). An Organization is the administrative container — every Event Group, Event Series, and Course belongs to one.

If you already have an Organization (for example, from a prior year's event), open it from **My Stuff > My Organizations** and skip ahead to creating an Event Group. Otherwise, create a new Organization from **My Stuff > My Organizations > New organization**.

From the Organization page, click **New event group**. This brings you to the **Event Construction** pages. Give the group a name (for example, "2026 Sufferfest") and a date.

Until you make it public, an Event Group — and everything inside it — is visible only to you and any Stewards you've invited. You can experiment freely.

## Add an Event

An Event is a group of entrants whose performance is measured against each other. If your Event Group has a single Event, the Event Group's name effectively names the Event too. If it has more than one — say, a half-marathon, a 50K, and a 50-miler all on the same day — each is a separate Event because the entrants in one aren't competing with the entrants in another, and each needs a **Short name** to distinguish it.

Wave-style starts are the opposite case. If multiple waves run the same course at different start times and the entrants are still competing against each other, those waves belong to a single Event, not several.

From the Event Group, click **Add an event** and fill in:

- **Course** — pick an existing Course from the Organization, or create a new one inline by entering a name and distance.
- **Laps required** — `1` if the course is to be completed once, a higher number if the exact course is to be completed a set number of times, or `Unlimited` for time-based events where entrants complete as many laps as they can within a fixed time.
- **Short name** — a brief identifier (e.g. "100M" or "50K") that distinguishes this Event from others in the same group. For a group having only one Event, this can be left blank. See the explanation above.
- **Scheduled start time** — the earliest start time for any entrant in this Event, in the Event's local time zone. (Wave-style starts within a single Event can have later start times for individual entrants.)

If your Event Group has multiple Events on the same day, repeat for each race. Each competition is its own Event, but they all live under the same Event Group.

## Set up the Course

A Course is a physical route. Each Course has at least a Start split and a Finish split; you'll usually add splits for every aid station or timing checkpoint along the way.

From the Event row on the Construction page, click **Setup Course**. From there you can:

- **Add splits manually** by clicking the new-split row at the bottom of the splits table. Each split takes a name (e.g. "Cunningham"), a distance from the start, and optional latitude / longitude / elevation.
- **Import a splits CSV** for bulk-loaded courses. Click **Import > Download CSV Template** to get a blank template. Fill in split names, distances, lat/long/elevation, and the **Sub split kinds** column (`in` for one time per split, `in out` if you record both arrival and departure). Save as CSV and bring it back via **Import > Import splits**.
- **Upload a GPX file** to draw the course on the map for visual reference. The GPX is shown alongside your splits but doesn't change them — you still set split locations yourself.

Courses are reusable. Next year's event can pick the same Course from the dropdown without rebuilding it. Reusing a Course gives you:

- Consistent split locations across events on the same route. You can still add or remove splits for a future event without affecting prior years.
- Better planning and predictions for future events, since OpenSplitTime can draw on past performance data to estimate split times and pacing.

## Add Entrants

There are two ways to load Entrants into an Event Group:

### Option 1: Connect a registration service

If your race uses an external registration platform (as of this writing, Runsignup and Rattlesnake Ramble are supported), or if your entrants were determined using an OpenSplitTime lottery, OpenSplitTime can pull entrants directly. From the Event Group, go to **Admin > Construction > Entrants > Connections**. Pick a service from the dropdown, enter your service-specific identifier (e.g. RunSignup race ID), and connect each Event in the group to its corresponding event in the external service.

For RunSignup, see the [RunSignup Integration](../runsignup-integration/) section for getting API credentials and connecting your race.

Once connected, OpenSplitTime can sync entrants on demand. Pulling new registrations later takes just a few clicks; you don't have to re-import.

### Option 2: Import a CSV

If you already have your roster in a spreadsheet, or your registration platform isn't supported, import a CSV.

1. From the Event Group, go to **Admin > Construction > Entrants**.
2. Click **Import > Event Group Entrants > Download CSV Template**.
3. Fill in the template. Required columns are **First Name**, **Last Name**, and **Gender**.
4. **If your Event Group has multiple Events**, you'll also need an **Event Name** column whose value exactly matches each Event's Short Name.
5. Add anything else you have — birthdate, age, city, state, email, phone — to help OpenSplitTime match your entrants against existing people in the database. The more data you provide, the cleaner the reconciliation.
6. Save the file as CSV and import it via **Import > Event Group Entrants**.

Two optional columns worth knowing about:

- **Comments** — free text shown to organizers and stewards (e.g. on the Finish Line view), but not to the public. Useful for announcer notes.
- **Beacon URL** — a per-entrant URL to an external GPS tracker (MAProgress, SPOT, TrackLeaders, etc.).

After importing, OpenSplitTime walks you through a reconciliation step that matches new entrants against existing People records. You can revisit and adjust this at any time from **Admin > Reconcile**.

You can also add Entrants one at a time using the **Add** button on the Entrants page.

## Duplicate an existing Event Group

If you're carrying forward an event from a previous year, duplicating saves rebuilding the Event Group from scratch.

1. Sign in as an owner of the Organization.
1. Open the Event Group you want to copy.
1. Click **Admin > Construction > Group Actions > Duplicate Group**.
1. Enter a name and date for the new Event Group and click **Duplicate Event Group**.

OpenSplitTime copies the Event Group and all of its Events (each pointing at the same Course as last year), but does not copy Entrants. Make any adjustments — start times, course tweaks — and then [add this year's Entrants](#add-entrants).

## Once you're ready

For a live event, switch the group out of Construction Mode (**Admin > Construction > Group Actions > Enable or Disable Live**) and record times as they happen using the live entry tools, [OST Remote](../ost-remote/), or [RaceResult RFID](../raceresult-integration/) chip timing.

For a historical event, import time data after entrants are loaded; [contact us](mailto:mark@opensplittime.org) if you need help with the time-data import format.

If you get stuck or want a hand: [contact us](mailto:mark@opensplittime.org) — we're happy to help.

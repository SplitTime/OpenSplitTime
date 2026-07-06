---
title: Crew Access
parent: Managing an Event
nav_order: 5
---

# Crew Access

At many events, crews are permitted to drive to certain aid stations to meet their runners. Some aid stations have
limited parking or narrow access roads, so a race official controls when crews may begin driving toward them.
If crews leave too early, the access road and parking fill up long before the runners arrive. If they leave too
late, they miss their runners.

The Crew Access tools help you manage this. For each controlled location, you tell OpenSplitTime where the
runners are timed (the **gating aid station**) and where the crews are headed (the **target aid station**).
As runners pass through, OpenSplitTime predicts each runner's arrival at the target and calculates the earliest
time that runner's crew should be released to make the drive.

## Key Terms

1. **Gating location:** A place where a race official controls when crews may begin driving toward an aid
station with limited access. A single gating location can apply to more than one Event in your Event Group.

1. **Gating aid station:** The station where runners are timed and where the gate is enforced. This is often
the aid station the crews are waiting at, or a checkpoint the runners pass on the way.

1. **Target aid station:** The aid station the crews are driving toward.

1. **Travel buffer:** The number of minutes it takes a crew to drive from the gate to the target. The release
time is the runner's earliest projected arrival at the target, minus this buffer.

## Setting Up Gating Locations

Crew Access is configured in the construction area of your Event Group.

1. Go to **Admin > Construction > Crew Access**.

1. Click **Add a gating location** and give it a descriptive name, for example "Highway 50 Turnoff."

1. For each Event in the group, choose a **gating aid station** and a **target aid station**, and set a
**default travel buffer** in minutes. Leave both aid stations blank for any Event to which this location does
not apply.

1. Save. The gating location will appear as a card summarizing each Event's gate, target, and buffer.

You can add as many gating locations as you need. To change or remove one, use the menu (**…**) on its card and
choose **Edit** or **Delete**. Deleting a gating location removes its configuration for all Events in the group.

The default travel buffer you set here is used directly in the public per-runner view (described below). In the
live view, it becomes the starting value, which you can adjust on the fly.

## The Live Crew Access View

The live Crew Access view is where you manage releases during the Event. It is available only to the Event
Group's Owner and its designated Stewards, and it appears in the menu only after at least one gating location
has been configured.

1. Go to **Live > Crew Access** to see a list of your gating locations.

1. Click a gating location to open its release board. The board shows one table per Event.

For each runner, the table shows:

1. **Bib** and **Name.**

1. The runner's time at the gate. The column is labeled with the gating aid station and whether it uses the
station's "in" or "out" time (for example, "Engineer Mtn TH Out").

1. **Expected at [target]:** the runner's earliest projected arrival at the target aid station. Once the runner
actually reaches or leaves the target, this column shows the recorded arrival or departure instead of a
prediction.

1. **Release:** when the runner's crew may leave the gate.

1. **Crew:** a control to mark that runner's crew as having passed the gate (see below).

### Reading the Release Column

The Release column tells you, at a glance, what to do with each crew:

1. A **time** means the crew should be released at that time.

1. A green **Now** badge means the crew may be released immediately.

1. **Insufficient data** means OpenSplitTime cannot yet compute a release time. This is normal early in the
race, before the runner has departed the gate or before enough data exists to make a prediction.

1. **Stopped**, **Arrived**, or **Departed** indicate that a release is no longer relevant because the runner
has stopped, has reached the target, or has already left the target.

1. **Passed** indicates that you have marked this crew as having already been released (see below).

### Releases Wait for the Runner to Leave the Gate

When the gating aid station records both an "in" and an "out" time, OpenSplitTime waits for the **out** time
before it calculates a release. In other words, the crew is not released based on the moment the runner arrives
at the gate, but on the moment the runner leaves it.

This matters because a runner can spend a long time in an aid station. Calculating the release from the arrival
time would release the crew too early. Until the runner's departure is recorded, the runner's Release column
shows **Insufficient data**.

### Adjusting the View

Controls above each Event's table let you tailor the board:

1. **Buffer (min):** temporarily override the travel buffer for this Event. Increase it if the drive is slow
today, or decrease it if crews are moving quickly. This does not change the default you set during construction.

1. **Sort by:** order the runners by **Bib number** or by **Release time**. Sorting by release time keeps the
crews you need to act on soonest at the top.

1. **Find runner:** filter the table to a single bib number or name.

1. **Hide departed:** hide runners who have already left the target aid station.

1. **Hide passed:** hide runners whose crews you have already marked as passed.

The board reflects the data OpenSplitTime has at the moment you load it. Refresh the page to pick up newly
recorded times, much as you would with the other [monitoring tools](../monitor/).

### Marking a Crew as Passed

As you release each crew, use the control in the **Crew** column to mark that crew as passed. Marked crews move
to the bottom of the board and can be hidden entirely with the **Hide passed** switch, so you can keep your
attention on the crews still waiting. You can un-mark a crew if you release it by mistake. The runner's expected
arrival remains visible even after the crew is marked as passed.

## The Crew Access Tab on the Runner's Page

Crews and runners do not need access to the live board. Instead, every runner's page includes a public **Crew
Access** tab whenever the runner's Event has a gating location configured.

Open any Effort (runner) page and select the **Crew Access** tab. For each gating location, it shows:

1. When the runner reached the gate.

1. The runner's earliest projected arrival at the target aid station.

1. The earliest time the crew may be released.

This view uses the default travel buffer set during construction, so the times crews see are consistent with
your plan. Crews can bookmark their runner's page and check this tab to know when to head for the next aid
station.

## How the Predictions Work

Release times depend on OpenSplitTime's ability to predict each runner's arrival at the target aid station.
These predictions require time data from at least one prior-year Event on the same Course. See
[Power of Prediction](../monitor/#power-of-prediction) for more on how OpenSplitTime uses historical data.

**If no prior-year data exists for the Course, OpenSplitTime does not predict arrival times, and no release
time can be calculated.** The Release column will show **Insufficient data** for every runner, no matter how
the buffer is set. Crew Access is therefore only useful for a Course that has at least one prior year of results
in OpenSplitTime.

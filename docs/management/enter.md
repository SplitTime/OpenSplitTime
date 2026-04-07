---
title: Entering Times
parent: Managing an Event
nav_order: 3
---

# Entering Times

## Live Entry

The Live Entry screen is the primary place to manually enter time data. It also serves as a review point for time
entries that have been flagged by OpenSplitTime as faulty, meaning that they require human review before being
posted for public view.

**You will need to [Enable Live Entry](../prep/#enabling-and-disabling-live-entry)**
in order to access the Live Entry page.

You can reach the Live Entry page by selecting **Live > Time Entry** from the main menu.

## Manual Time Entry

For aid stations that have no data connectivity, the best way to report time entries is often by voice over ham
radio or some similar mechanism. The timing crew may record the times using OST Remote and read them from
the Review/Sync screen, or they may use paper and pencil and read the time entries the old fashioned way.

When an aid station calls to report times, follow this procedure to record an entry:

1. Select the correct station from the Aid Station dropdown at the top of the Live Entry screen

1. Tab to the Bib field and enter the bib number

1. Tab to the time field and enter the time or times. There will be one time field if you are recording "in"
times only, and two fields if you are recording "in" and "out" times.

1. If the entry is a drop/stop, click **Dropped Here**

1. For Events that are monitoring pacers only: If the entry includes a pacer, click the "In" and/or "Out" pacer
toggles, as appropriate

1. Click **Add**. The entry will appear in the Local Data Workspace.

1. Repeat steps **2 through 6** for all times reported by the station.

The Live Entry screen is designed to be used exclusively with the keyboard, if the operator so chooses. This is
the most efficient way to enter times. Use Tab and Shift-Tab to move between fields. Use the space bar to toggle
the Dropped Here and Pacer boxes. Use Enter to activate the **Add** button.

## Real-Time Feedback

As you enter data into the Live Entry screen, **OpenSplitTime provides real-time feedback** to help
you evaluate the data.

If a bib is not found, a red "X" icon will appear next to the Bib field. If a bib is found but is associated with
an Event that is not expected to be at the selected station, a yellow "?" icon will appear next to the Bib
field.

If a time is questionable, a yellow "?" icon will appear next to the time. If a time is bad, a red "X" icon will
appear next to the time. If a time is duplicated (meaning that a Split Time already exists for that bib at that
station), a grey "!" icon will appear next to the time.

When you enter a bib number, OpenSplitTime will fetch all existing time data for that Entrant and display it in
the upper right corner of the Live Entry screen. This allows you to quickly evaluate the Entrant's status and
understand why a time may be flagged as bad. For example, if Bib #111 has dropped at Aid 3 and Aid 4 calls in a
time entry for Bib #111, the time will always be flagged as "bad."

## The Local Data Workspace

Times entered through the Live Entry screen are placed into the Local Data Workspace. Times in the Workspace are
not saved to the database and will not be visible to the public. The Local Data Workspace provides an area in
which time entries can be reviewed and checked for accuracy before being submitted to the database.

A time entry can be **edited** by clicking the **blue pencil** icon at the right side
of the row.

A time entry can be **discarded** by clicking the **red "X"** icon at the right side of
the row.

All time entries can be discarded at once by clicking the red **Discard All** button and confirming
the action.

## Submitting Time Entries

Submitting a time entry results in it being removed from the Local Data Workspace and saved as a Raw Time for
recordkeeping purposes and as a Split Time for view by the public until they are submitted. A single time entry is
submitted by clicking the green checkmark icon at the right side of the row.

Multiple time entries can be submitted to the database at once by clicking the green **Submit All**
button.

Each time entry in the Local Data Workspace is either "clean" or "not clean." "Clean" entries are those that have
a valid bib number, are not duplicates, and have times that OpenSplitTime does not consider to be faulty. Clean
entries will have green checkmark icons next to the bib number and all related times.

Clicking **Submit All** will submit only those entries that are clean, but clicking the green
checkmark icon next to a single time entry will submit that time entry whether or not it is clean.

Some time entries cannot be submitted using any method. For example, if the bib number does not exist in the
Event Group, the time entry cannot be submitted even using its individual submit button. It must be edited to fix
the bib number or discarded.

For example, say you have five time entries in your Local Data Workspace. Two are clean, one has a duplicate
time, one has a faulty time, and one has an invalid bib number. You click Submit All. The two clean entries are
submitted, and the other three entries remain in the Local Data Workspace.

You click the green checkmark next to the entry having the duplicate time. The entry is submitted and the new
time overwrites the old time.

Next you click the green checkmark next to the entry with the faulty time. The entry is submitted. The
related Entrant will now appear in the **Admin > Problems** list because one of her times is faulty.

You click the green checkmark next to the entry with the invalid bib number. The entry is not submitted because
there is no way to create a Split Time for an invalid bib number. The entry remains in the Local Data Workspace.
It can be removed only by discarding it or by correcting the bib number and then submitting it.

## Pulling Times For Review

Time entries coming through OST Remote are always saved as Raw Times. If the entries are **clean**,
they are automatically saved as Split Times for public view.

But when a time entry from OST Remote is **not clean**, either because the entry is a
**duplicate**, the time is **marked as bad**, or the **bib number is
invalid**, the Raw Time must be reviewed by a human before it can be saved as a Split Time. The Live Entry
screen is the place where such Raw Times are reviewed.

When times are available for review, a message will appear in the upper right corner of the screen, and the blue
**Pull Times** button will be enabled and will indicate the number of times available for review.
Click **Pull Times** to bring in a batch of time entries for review. Times are pulled in batches of
50 at most.

Once you have pulled a batch of times, review them and determine whether they should be submitted as-is, edited
to fix problems, or discarded. Review and analysis are covered in
the [Reviewing Raw Times](#reviewing-raw-times) section.

## Direct Edit

An Entrant's Split Times can be edited directly, either as military times, elapsed times, or full dates with
times. Follow this procedure to edit times directly:

1. Visit the Entrant Show screen by clicking on the Entrant's name in the Roster or Full Results screen

1. Click **Actions > Edit Times of Day** or **Actions > Edit Dates and Times** or
**Actions > Edit Elapsed Times**, depending on which format you prefer to edit

1. Make changes and click **Update Times**

## When to Use Direct Edit

Use restraint when editing times directly. On the plus side, if an Entrant has several incorrect or blank times,
it is easy to edit or add them all in a single stroke. On the minus side, times entered or edited directly in this
manner **will have no Raw Times associated with them**, so there will be no audit trail indicating
when they were changed or by whom. If you instead enter each time in the Live Entry screen, it will take a bit
longer, but Raw Time records will be created for each entry, making the changes easier to trace in the future.

## Directly Editing Start Times

An Entrant's **starting Split Time** can be edited in Time of Day or Date and Time format, but
**cannot be edited in Elapsed Time format** (because the starting elapsed time is always
00:00). Edit Times of Day or Dates and Times if you need to directly edit the start time.

## Rebuilding an Effort (Multi-Lap Events Only)

This tool applies only to multi-lap events.

Raw Times contain a bib number, time data, and the name of the station at which the bib was recorded. They do not
specify a lap. In a multi-lap Event, time entries are sometimes mismatched such that a later Raw Time for an
Entrant is mapped to one lap, and then an earlier Raw Time is discovered and is forced to map to a later lap.

When times for an Entrant are hopelessly confused, **the entire Effort can be rebuilt** from the Raw
Time record using the **Rebuild Times** tool. Follow these steps:

1. Visit the Entrant Show screen by clicking on the Entrant's name from the Roster or Full Results screen

1. Locate the green **Raw Time Records** button. The button includes a number indicating how many
Raw Time records exist for the Entrant.

1. Click **Raw Time Records** and review the list to ensure it is complete

1. Return to the Entrant Show page

1. Choose **Actions > Rebuild Times**

1. Click **OK** to confirm your choice

## Use This Tool With Care

Note: This is a powerful and blunt instrument. **It will delete all of the Entrant's Split Times**
and attempt to rebuild them from the available Raw Times. **If you do not have a complete Raw Time record,
you will lose data.** If there are no Raw Times (for example, if all of the Entrant's times were entered
using the [Direct Edit](#direct-edit) method), you will erase all
of the Entrant's Split Times and you will have to re-enter them from some other source.

## Reviewing Raw Times

When Raw Time entries are flagged as **bad**, they wait in a holding state until they are pulled for
review into the Live Entry screen. You should visit the Live Entry screen on a regular basis to review these
problem entries.

From the Live Entry screen, if time entries are waiting for review, you will see an alert in the upper right
corner to that effect. In addition, the blue "Pull Times" button will show a badge indicating how many time
entries are available for review. Pull the time entries as described in
the [Live Entry](#pulling-times-for-review) section.

## The Review Procedure

Each Raw Time entry was flagged for review for some reason, so please take a moment to review each one before
submitting. For each time entry, we recommend you follow this procedure:

1. Click the blue pencil icon next to the time entry. If the bib number is valid, OpenSplitTime will present the
related Effort data to the right with the selected aid station highlighted.

1. If the entry appears to have a wrong bib number, and if you are able to determine the correct bib number,
change the bib number, click **Update**, and then submit the entry by clicking the green
**checkmark** icon

1. If the entry appears to have a wrong bib number and you are not able to determine the correct bib number,
or if there is some other problem that you cannot discern given the information that you have, click
**Cancel** to return the entry to the Local Data Workspace, and then use other tools to try
to determine the problem

1. If the entry duplicates an existing Split Time, and if the **existing entry appears to be
correct**, click **Cancel** and then discard the entry by clicking the
red **X** icon

1. If the entry duplicates an existing Split Time, and if the **new entry appears to be correct**,
click **Cancel** and then submit the entry by clicking the green **checkmark** icon

1. If the entry appears to have been made at the wrong station, choose a new station from the dropdown menu,
click **Update**, and then submit the entry by clicking the green **checkmark** icon

1. **For multi-lap events**, if the entry appears to be correct but the **lap suggested by
OpenSplitTime is incorrect**, change the lap, click **Update**, and then submit the entry by
clicking the green **checkmark** icon

## How OpenSplitTime Evaluates Split Times

To understand how to fix problem Efforts, it helps to understand how OpenSplitTime evaluates Split Times. When a
Split Time is added or changed, OpenSplitTime reviews each Split Time for the Effort sequentially, following this
procedure:

1. Assume the starting Split Time is good and mark it as such

1. Locate the next recorded Split Time

1. Measure the elapsed time for the segment looking back to the previous **valid Split Time**,
ignoring questionable and bad Split Times that may exist in between

1. Mark the Split Time as **good**, **questionable**, or **bad**,
depending on how the elapsed segment time compares to statistical tolerances for the segment

1. Repeat steps **2 through 4** for each Split Time

If there is no starting Split Time for an Effort, OpenSplitTime has no way of calculating elapsed segment times,
so it does not attempt to evaluate the validity of Split Times for that Effort.

## Types of Problems

Problems fall into one of a few categories:

1. The Entrant's time **out of** a station is earlier than the Entrant's time
**into the same station**

1. The Entrant's time **into one station** is earlier than the Entrant's time
**into the previous station**

1. The Entrant's time into one station is **too soon after** the Entrant's time into the previous
station

1. The Entrant's time into one station is **too long after** the Entrant's time into the previous
station

1. The Entrant is recorded as having **stopped** at one station but is **recorded into a
later station**

## Confirming and Deleting Split Times

From many points within OpenSplitTime, you can reach the Effort screen for an Entrant by clicking on the
Entrant's name. Split Times that OpenSplitTime evaluates as **questionable** will be **yellow
and flagged with brackets**. Times that OpenSplitTime evaluates as **bad** will be
**red and flagged with brackets and asterisks**.

So long as you are logged in as an Owner or Steward, the Effort screen shows a set of
**Confirm (thumbs up)** buttons and a set of **Delete (trash can)** buttons, each
corresponding with the listed Split Times.

If OpenSplitTime has flagged a Split Time as **questionable** or **bad**, but you know
that the Split Time is correct, you can confirm the Split Time by clicking the corresponding
**Confirm (thumbs up)** button. When a Split Time has been confirmed, the corresponding button
changes from white to green. Confirming a Split Time overrides OpenSplitTime's analysis such that the Split Time
is treated as valid for all purposes. You can un-confirm a Split Time by clicking the corresponding
**Confirm** button again, changing it from green to white.

If you determine that a Split Time is faulty, you can quickly delete the Split Time by clicking the **red
trash can** icon corresponding with the bad Split Time. Deleting a Split Time cannot be undone.

## Analyzing Problem Efforts

OpenSplitTime provides tools for analyzing and fixing problem Efforts. This section discusses how to use the
Effort screen and the Effort Analysis screen to decipher and fix many problem Efforts.

As described in [Problem Efforts](../monitor/#the-problem-efforts-view), you should
check the Problems Report screen (**Admin > Problems**) regularly. Problems should be monitored and
corrected during the Event as time permits. Problems can be fixed after the event has concluded as well.

## The Effort Screen

When you find a problem Effort, click on the Entrant name to visit the Effort screen. All of the Entrant's Split
Times will be listed. Note the Split Times that are marked as **questionable** or
**bad**.

As you review a problem Effort, try to determine which Split Times are problematic. This is not always as easy
as it sounds. Consider the following example:

Assume we have a 50-mile course with aid stations at Mile 10, Mile 20, Mile 30, and Mile 40. Suppose an Effort
shows a starting Split Time at 06:00, a time into Aid 1 at 08:30, and a time into Aid 2 at 09:00, and suppose that
OpenSplitTime has marked the Aid 2 time as **bad**.

The Aid 2 time was flagged as bad because 2.5 hours is a reasonable period to travel from Start to Aid 1,
but 30 minutes is not long enough to travel from Aid 1 to Aid 2.

But this does not necessarily mean the Aid 2 time is faulty. In fact, there are two possibilities. One
possibility is that **the Aid 2 time is incorrect and should be much later**. The other possibility
is that **the Aid 1 time is incorrect and should be much earlier**.

A faster Entrant might cover 20 miles in 3 hours. If the Entrant was recorded with an incorrect time at Aid 1,
the Aid 2 time may be correct although it was flagged as **bad**.

A slower Entrant might cover 10 miles in 2.5 hours. If the Entrant was recorded with a correct time at Aid 1,
the Aid 2 time would be correctly flagged as **bad**.

In the above example, you might be able to make an educated guess as to which time is faulty, or you may be able
to ask your timing crews to verify by checking their paper records, or you may be able to verify using GPS
tracking. If you are still unsure, it is best to wait until the Entrant is recorded at Aid 3, at which time it
should become clear which of the two Split Times (Aid 1 or Aid 2) is faulty.

## The Effort Analysis Screen

Sometimes it is not obvious which Split Times are problematic, even after all times have been recorded for an
Effort. In these cases, the Effort Analysis screen is often helpful.

From the Effort screen, click the **Analyze Times** tab to view the Effort Analysis screen. This
screen presents columns of data showing actual and expected times for each completed segment and the differences,
shown in **Over (Under)** format, for each segment. Times that are longer than expected are shown as
a number of minutes without parentheses, and times that are shorter than expected are shown as a number of minutes
surrounded by parentheses.

Expected times are determined by using the **farthest recorded time for the Effort**, finding other
Efforts that reached that farthest point in a **similar amount of time**, and **averaging and
normalizing the segment times** for those similar Efforts.

The Effort Analysis view provides insight into which segments were relatively fast and which were relatively slow
for a given Effort. But when the Effort contains problem Split Times, it can often reveal which of the Split Times
are faulty and which are valid.

For example, assume we are viewing an Effort having a starting Split Time and five additional Split Times. The
Aid 1 Split Time is marked as **good**, the Aid 2 and Aid 3 Split Times are flagged as
**bad**, the Aid 4 Split Time is flagged as **questionable**, and the Aid 5 Split Time
is marked as **good**. From the Effort screen, it is not immediately apparent which Split Times are
causing the problems.

We click the **Analyze Times** tab to reach the Effort Analysis screen. Here we look at the
**Segment Over (Under)** column and note the following:

1. Aid 1: (3m)

1. Aid 2: 54m

1. Aid 3: (59m)

1. Aid 4: 1m

1. Aid 5: 6m

The actual times recorded for Aid 1, Aid 4, and Aid 5 are close to what we would expect for this Effort. The Aid
2 segment, by contrast, is much too slow, and the Aid 3 segment is much too fast. This tells us quite a lot about
this Effort.

It is highly unlikely that this Entrant was actually nearly an hour past due into Aid 2 and then nearly an hour
early into Aid 3. It is much more likely that the Aid 2 time is wrong. We should return to the Effort screen by
clicking the **Split Times** tab, and then delete the Aid 2 Split Time by clicking the
**Delete (trash can)** icon corresponding to Aid 2. OpenSplitTime re-evaluates the Effort, and all
Split Times are now marked as **good**. When we return to the Effort Analysis screen, the Segment
Over (Under) column now indicates that all actual segment times for the Effort are close to expected segment
times:

1. Aid 1: (3m)

1. Aid 2: --

1. Aid 3: (5m)

1. Aid 4: 1m

1. Aid 5: 6m

We now have a hole in our Split Times for this Effort. We can use the Raw Time tools or other resources to try to
fill in the hole.

## Using the Raw Times Record

You can gain additional insight into a problem Effort using the **Raw Times List**,
**Raw Time Splits**, and **Effort Audit** screens. Together with the Effort screen and the Effort Analysis screen, these
tools give you deep insight into what data is faulty and how it can be improved.

A full explanation of the Raw Times List screen is found on the
[Monitoring / Raw Times List](../monitor/#the-raw-times-list-view)
page.

A full explanation of the Raw Times Splits screen is found on the
[Monitoring / Raw Times Splits](../monitor/#the-raw-times-splits-view)
page.

A full explanation of the Effort Audit screen is found on the
[Entering and Editing / Effort Audit](#the-effort-audit-screen)
page.

For various reasons, valid Raw Times may be not be automatically saved as Split Times. The following scenarios
may be helpful in learning how to use the Raw Time record to find and fix problems.

## Scenario 1: A Duplicated Entry

Bib 111 comes through Aid 1 at 08:30, but the timing crew may inadvertently record her into OST Remote as bib 101
and then sync. The problematic time for bib 101 evaluates as good and is automatically saved as a Split Time. When
bib 101 comes through at 08:35 and is recorded into OST Remote, the Raw Time evaluates as not clean (because a
time for bib 101 already exists at Aid 1), so it is not automatically saved as a Split Time and must be
reviewed.

On review, the operator may not know whether the original 08:30 Split Time or the new 08:35 Raw Time is correct.
Unable to make the determination immediately, she discards the time to remove it from the Local Data
Workspace.

After the event, a Steward notices there is a hole for bib 111 at Aid 1. He also notices that there are two Raw
Times recorded at Aid 1 for bib 101, with a 5-minute discrepancy. He reviews the paper record and determines that
the 08:30 time belongs to 111 and the 08:35 time belongs to 101. He "un-pulls" the 08:30 time, pulls it into the
Live Entry screen for review, changes the bib from 101 to 111, and submits the time.

## Scenario 2: An Errant Finisher

Bib 234 is entered in an Event Group for which both 25-mile and 50-mile events are available. Bib 234 is entered
in the 50-mile event. The 50-mile Entrants are expected to finish a 25-mile loop, then run the same loop in the
opposite direction to complete the 50-mile course. Because the 25-mile and 50-mile events are run concurrently,
the slower 25-mile finishers will be finishing within the same timeframe as the faster 50-mile finishers. To avoid
confusion, the 50-mile Entrants are instructed not to enter the finisher's chute at the 25-mile mark, but instead
to report into a separate 25-mile timing station nearby.

When bib 234 comes in at mile 25, he decides he is going to drop. But instead of reporting into the 25-mile
timing station, he runs through the finisher's chute and is recorded as a finisher. Bib 234 now has a Raw Time at
the Finish station. The Raw Time is flagged as **bad** because the time from the prior station to the
finish is much too short.

The problem is soon discovered, and bib 234 is entered again, this time at the 25-mile station. The entry is
synced and the Raw Time is automatically saved as a Split Time.

Later, an operator pulls the faulty Raw Time for review. Although the Raw Time is marked as **bad**,
he submits it using the green **checkmark** icon. Now bib 234 shows as a finisher, and worse, he is
shown as having won the race as his 50-mile finish time reflects the time it took him to complete only 25 miles.

Another Steward notices the problem and pulls up the Effort screen for bib 234. She clicks the **Raw Time
Records** button to see what is going on, notices the errant Raw Time for bib 234 at the Finish station,
and figures out what happened. Based on the data, she visits the Effort screen for bib 234 and deletes the finish
Split Time.

Bib 234 now properly appears as a drop at Mile 25.

## The Effort Audit Screen

You can see the all Split Times and Raw Times for a single Effort in the Effort Audit screen. You can reach this
screen by clicking the **Audit** tab from any Effort screen or by clicking an Entrant's name from the
**Raw Times > Splits** screen.

The Effort Audit screen gives you a full picture of what Raw Times have been submitted for the Entrant's bib
number and which of those Raw Times have been matched to which Split Times.

From this screen you can also choose to match or un-match Raw Times and, for multiple matching Raw Times, choose
which time (if any) should govern the Split Time.

## Matching and Unmatching Raw Times

Sometimes Raw Times are not automatically matched to a Split Time. These unmatched Raw Times will appear in the
Unmatched Raw Times column. If there is a Split Time available, the Raw Time will have a **link**
icon allowing you to
match it. Click the **link** icon and the Raw Time will be matched to the Split Time.

A Raw Time that is already matched to a Split Time will have an **un-link** icon allowing you to
un-match it. Click
the **un-link** icon and the Raw Time will be un-matched from the Split Time.

For example, assume a runner having **Bib #132** comes through **Aid 2** at
**10:45**. A volunteer records the time using OST Remote but
**inadvertently enters the Bib as #123**. The time is synced, and OpenSplitTime evaluates
it as "good" and automatically creates a Split Time matching that Raw Time entry.

Now the runner wearing **Bib #123** comes through **Aid 2** and is recorded at
**10:55**, and this time is also synced. OpenSplitTime evaluates the second time as a duplicate and,
**because it is too different from the already-matched time**, it does not automatically match the
newly synced Raw Time.

A timing volunteer at race headquarters looks at the Effort Audit screen for **Bib #123** and sees a
**matched Raw Time (10:45)** and an **un-matched Raw Time (10:55)** for this entrant at
Aid 2. The volunteer determines that the 10:55 time is the correct time.

The volunteer clicks the **link** icon next to the 10:55 Raw Time.
**The Raw Time is matched and the Split Time is changed to 10:55.** Next, the volunteer clicks the
**un-link** icon next to the 10:45 Raw Time.
**That Raw Time is un-matched from the Split Time.**

## Changing the Governing Raw Time

You may have **multiple Raw Times that you want to keep matched to a single Split Time**. This may
happen if, for example, you have multiple volunteers at the Finish using OST Remote for redundancy. Whichever of
the Raw Times was synced first will be used to create the Split Time.

If the Raw Times are a few seconds apart, **you may decide to leave them both matched** but use the
other time to govern the Split Time. Click the **equals (=)** icon for the Raw Time you prefer. The
Split Time will change to match the Raw Time you clicked.

## Switching to the Raw Times Splits Screen

The Effort Audit screen shows times **for a single entrant at all aid stations**. To see all raw
times for a **single aid station for all entrants** in a similar format, visit the
[Raw Times Splits Screen](../monitor/#the-raw-times-splits-view), which can be reached by
clicking any split name in the Effort Audit screen.

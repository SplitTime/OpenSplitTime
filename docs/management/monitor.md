---
title: Monitoring
parent: Event Management
nav_order: 4
---

# Monitoring

## Tools to Monitor Entrants

OpenSplitTime provides you with advanced tools to monitor your Entrants on the course.

Many race directors and timing coordinators will create individual tabs in a browser, one for each primary
monitoring tool. They will then rotate through the various tabs on a regular schedule, perhaps every few
minutes.

The various monitoring tools will allow you to prompt stations for timing data, quickly provide information to
stations as to when Entrants should be expected, and flag overdue Entrants that may be injured, exhausted, or
lost.

The primary monitoring tools available are:

1. Full Results view (**Results > Full**)

1. Progress view (**Live > Progress**)

1. Aid Station Overview (**Live > Aid Stations**)

1. Aid Station Detail views (**Live > Aid Detail**)

1. Problem Efforts view (**Admin > Problems**)

1. Raw Times List view (**Raw Times > List**)

1. Raw Times Splits view (**Raw Times > Splits**)

1. Finish Line view (**Admin > Finish Line**)

Each tool is described in detail in the following pages.

## The Full Results View

The Full Results page provides the best overview of an Event. It shows all Entrants, whether or not started, in
progress, dropped, or finished.

The Full Results page shows only a single Event at a time. If your Event Group includes multiple Events, you can
quickly switch between them using the blue-and-white pill bar just above the table on the left side.

The Full Results page is available to the public as well as to the authorized Owner and Stewards.

## Sorting and Filtering

By default, Entrants in the Full Results view are ranked by distance traveled and elapsed time. You can change
the sort by clicking any of the blue table headings.

You can also change the style in which times are displayed. By default, an Event in progress will display AM/PM
times, but you can use the dropdown menu on the far right side above the table to change this to Elapsed, 24-Hour,
or Segment times.

Using the other dropdown menu at the upper right side of the table, you can show all Entrants (Combined), or
filter to show only male or only female Entrants.

## Looking for Holes

In an ideal Event, the Full Results view will show a complete set of data, with a Split Time at each station for
each Entrant. In real life, you may have "holes" in the data where an Entrant was missed or the bib number was not
correctly entered.

Look for patterns in the data holes. If a particular station is missing a long list of runners, check in with the
station to see if times are not being synced, or if some times had to be recorded manually and have yet to be
reported.

If a particular Entrant is missing several Split Times, consider whether the Entrant may not be displaying his or
her bib correctly. Where appropriate, consider whether it is possible the Entrant may not have completed the
entire course.

Some holes may be caused by data that OpenSplitTime has determined is not correct. For example, if Bib #111 is
recorded at Aid 2 at 12:30 and also recorded at Aid 3 at 12:10, OpenSplitTime will reject whichever of those times
is submitted second. Faulty times need to be pulled into
the [Live Entry](https://www.opensplittime.org) screen for review by a human.

## The Progress Report View

This report shows how many runners are in progress on the course and provides the easiest way to determine if an
Entrant has been delayed. Long delays indicate an Entrant may be injured or lost.

The Progress Report is available by selecting **Live > Progress**. The Entrant summary is followed
by a list of all Entrants that are "past due," meaning they were not recorded at their destination and more than
30 minutes have passed since their expected arrivals.

## Understanding the Report

If you see many Entrants listed as past due from a single station, **there is a good chance that station is
not reporting times**. Call the station to determine if they need to sync OST Remote. In most instances,
the timing crew has simply forgotten to report or sync times. If they are unable to sync because of connectivity
problems, consider taking a report of times manually and entering them using
the [Live Entry](https://www.opensplittime.org) screen.

If you see one or two Entrants from various stations listed, that is an indication that those Entrants may have
been missed or their bib numbers incorrectly recorded. Or it may be an indication that the Entrants are taking
longer than expected because of course conditions or simple fatigue. **But it may also be an indication that
they are injured or lost.** Keep an eye on Entrants that are seriously past due. Call the aid stations that
should have seen them, ask volunteers and course sweepers to watch for them, and use your judgment to determine if
further help is needed.

## The Aid Station Overview

The Aid Station Overview provides the easiest way to determine the status of your Event at a glance. You can
think of the Aid Station Overview as a distilled version of the Full Results screen.

When a station calls headquarters to ask a question about how many runners have passed through or how many
runners are yet expected, **the Aid Station Overview is usually the best place to start**.

## Understanding the Data

The Aid Station Overview lists all stations for a given event. For each station, it shows how many Entrants were
recorded there, how many Entrants were missed (meaning not recorded there but recorded at a later station), how
many dropped (or refused to continue) at that station, and how many are still expected.

## Drilling Down

Each aid station name is a link to an Aid Detail screen for that station. Click any of the links to visit the Aid
Detail screen.

In addition, each of the numbers in the table may be clicked to provide a simple list of the Entrants who are
included in that number.

## The Aid Station Detail View

The Aid Station Detail screen provides detailed information regarding the status of each Entrant at one
particular station.

You can reach the Aid Station Detail screen by selecting **Live > Aid Detail** from the menu. Or you
can visit the Aid Station Overview (**Live > Aid Summary**) and click on the name of any station to
reach the Aid Station Detail screen for that station.

## Selecting the Event and Aid Station

If your Event Group has multiple Events, you can switch between them using the blue-and-white Event selector
above the table on the left.

You can quickly switch from one station to another by clicking the dropdown menu labeled with the aid station
name, and then selecting another station. Or use the arrow buttons to the left and right of the station dropdown
selector to switch to the previous or next station.

## View Modes

The View Mode dropdown is above the table on the right side. This dropdown allows you to switch between several
views.

1. **Recorded:** Shows a list of all Entrants recorded at this station, together with their recorded
time and, when applicable, their prior and next recorded times before and after this station.

1. **In Aid:** Lists any Entrants who have been recorded into, but not out of, this station. This
option is available only if you have opted to record both "in" and "out" times at the station.

1. **Missed:** Lists Entrants who were not recorded at this station but who were recorded at a later
station.

1. **Dropped/Stopped:** Lists Entrants who dropped at this station (in the case of distance-based
Events) or refused to continue beyond this station (in the case of time-based Events).

1. **Expected:** Lists all Entrants who are still expected at this station, together with an
estimate of where and when they are due next, and when they are due at this station. An Entrant is expected
if he or she has started the Event but not been recorded at this station or at a later station, and has not
stopped/dropped at a previous station.

## Power of Prediction

OpenSplitTime uses existing data to predict arrival times for Entrants in progress. If you have time data
from at least one prior-year Event on the same Course, these predictive algorithms can be extremely helpful.

If a station contacts headquarters to ask what runners they should be expecting and when, the Aid Station Detail
screen is the best source to provide the answers.

## The Problem Efforts View

When an Entrant has recorded times that do not make sense, it is flagged as a "Problem" and made available for
review in the Problems screen. You can reach the Problems screen by selecting **Admin > Problems**.

## Handling Problems

Try to keep abreast of Problem efforts during the Event. Early discovery of problems may enable you to fix a
procedure and avoid the problem being repeated over the course of the Event.

If time does not permit during the Event, you can always fix problems after the Event concludes. Keep in mind,
however, that **problems affecting final standings will need to be understood before awards are
presented**.

You can fix problems by editing times, deleting times, or confirming times. More details are provided in the
[Fixing Problems](https://www.opensplittime.org) page.

## The Raw Times List View

You can see all Raw Times for an entire Event Group by visiting the Raw Times List screen (**Raw Times >
List**). By default, Raw Times are sorted by time created with most recent Raw Times at the top. The sort
order can be changed by clicking any of the blue headings in the table.

In most cases, the Raw Times List is more useful when filtered to show Raw Times related to only one or a few
Efforts. You can filter Raw Times by typing a bib number (or multiple bib numbers separated by spaces or commas)
into the search box and clicking the blue **Search** icon.

Each Raw Time indicates its bib number, the related name and Event (if the bib is valid), the station where the
Raw Time was recorded, the time information, whether or not the Entrant stopped at that point, and the source and
creation time for the record. In addition, each Raw Time indicates if it has been **reviewed** by a
human, and if so, when and by whom. Finally, it indicates whether the Raw Time has been **matched to a
Split Time**.

## Raw Times for an Effort

As a shortcut, you can reach the Raw Times List from the Effort screen. Visit an Effort screen and then click the
green **Raw Time Records** button. You will be taken to the Raw Times List screen with times already
**filtered for the Effort you were viewing**.

## Reviewed and Matched

When a Raw Time is submitted by OST Remote, it is saved to the database and analyzed. If OpenSplitTime evaluates
the Raw Time as **good** or **questionable**, it will be saved as a Split Time
automatically without human review. When a Raw Time is automatically **saved** as a Split Time, it is
also automatically **matched** with that Split Time.

In a typical Event Group, most Raw Times will be automatically saved as Split Times. As a result, they will show
as being **matched** but **not reviewed**.

When a Raw Time is submitted by OST Remote and OpenSplitTime evaluates the time as **bad**, the Raw
Time is not automatically saved as a Split Time. These Raw Times will initially show as being **not
matched** and also **not reviewed**. When these Raw Times are pulled for review into
the Live Entry screen, they will be marked as **reviewed**. If these times are submitted
without change, they will be marked as **matched**. If (as is more often the case) these times are
modified in the Live Entry view before being submitted, they will be marked as **not matched**, and
instead a new Raw Time record will be created for the modified time entry.

## Un-Reviewing and Deleting Raw Times

If a Raw Time has been reviewed, the **Reviewed** icon next to the Raw Time will be blue, and
if it has not been reviewed, the **Reviewed** icon will be white.

If a Raw Time has been reviewed but you need to pull it for review again, you can click the blue Reviewed icon.
The icon will change to white, and the Raw Time will be available to pull for review once again.
**This is not common**. It probably will be used only when a Raw Time was pulled for review and then
inadvertently discarded from the Live Entry Local Data Workspace when it should have been modified and submitted.

In unusual circumstances, you may want to delete a Raw Time entirely, removing it permanently from the record.
**Please do not delete any Raw Times unless there is a very good reason for doing so.** We recommend
that you keep a complete record of all Raw Times, whether or not valid, so that you have a good audit trail to
determine how and when problems occurred.

To delete a Raw Time, click the **Delete (trash can)** icon corresponding to the Raw Time.

## The Raw Times Splits View

You can see all Raw Times for any single station by visiting the Raw Times Splits screen (**Raw Times >
Splits**). This screen lists each bib number for which Raw Times have been recorded. For each bib number,
it shows the Split Time (if any) for that bib number at the station, and it shows all Raw Times recorded for that
bib number at that station.

**For multi-lap Events, multiple Split Times will be shown (one for each lap).**

The rightmost column shows the discrepancy, meaning the largest time interval among the Split Time and all
related Raw Times. A large discrepancy usually indicates one or more problem Raw Times or a problem Split
Time.

## Invalid Bib Numbers

The Raw Times Splits view lists all bib numbers for which Raw Times were submitted. This includes bib numbers
that **should not appear at the particular station** (for example, because a 50K Entrant was recorded
at a station that only 100K Entrants should visit). This also includes bib numbers that are **entirely
invalid**, because they were not issued to any Entrant or because they include a wildcard character (*).

Invalid bib numbers often represent typographical errors or transposed numbers. When you are trying to fill holes
or otherwise solve problems in the final Event results, it is critical to have the full record of bib numbers,
**both valid and invalid**, recorded at each station.

## Switching to the Effort Audit Screen

Raw Times Splits shows Raw Times **for all entrants at a single aid station**. To see all raw times
for a **single entrant at all aid stations** in a similar format, visit the
[Effort Audit Screen](https://www.opensplittime.org), which can be reached by
clicking any name in the Raw Times Splits list.

## The Finish Line View

Use the Finish Line view (**Admin > Finish Line**) to quickly get information about Entrants who
have recently finished or who are expected to finish soon. The Finish Line view also allows you to search for any
Entrant by bib number and see the same relevant information.

## Recently Finished and Next Expected Entrants

The Finish Line view shows a list of recently finished Entrants. It also shows a list of the next several
Entrants that are expected to finish, based on times leaving previous aid stations.

1. Recently finished Entrants will show finish times next to their names.

1. If OpenSplitTime has enough data to calculate expected finish times, next expected Entrants will show
expected finish times next to their names.

To get information about a recently finished or next expected Entrant, click the button for the Entrant.

## Finding an Entrant by Bib Number

To search for an entrant by bib number, type the bib number into the input box and hit Tab or click the "Go"
button.

## Information Displayed

Information displayed for an Entrant consists of the following, to the extent available:

1. Gender and age

1. Hometown and state

1. Status (Finished, dropped, in progress)

1. Place and time last recorded

1. Overall and gender rank where last recorded

1. Birthday information, if the Entrant's birthday is within a few days of the current date

1. Any comments you uploaded or added for the Entrant


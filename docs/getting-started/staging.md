---
title: Staging
parent: Getting Started
nav_order: 2
---

# Staging

## Creating or importing your first event

If you are starting from scratch, you've come to the right page. If you are working with an Organization that has
a prior-year Event like the one you are creating, it will be easier to [duplicate an event group](#duplicating-an-existing-event-group).
Otherwise, [create it from within the Organization](#creating-a-new-event-with-an-existing-organization).

1. [Sign up](https://www.opensplittime.org/users/sign_up) for an account (or log in to your existing account).

2. Create a new Organization.

3. Create a new Event Group.

4. Follow the instructions to add one or more Events and Courses. You can manually enter information or import a splits CSV
file.

5. Continue to add your entrants' personal information (names, ages, contact info) manually or import a
CSV file. To avoid duplication, you will need to reconcile Entrants with our participant database. You can always
add or change entrant information at any time, including after the event is finished.

6.a. If this is an upcoming event, use the Live features and OST Remote to track your entrants on the course. Your
time data will be available to the public instantly as it is submitted to the database.

or

6.b. If this is an event that happened in the past and you have the data somewhere in gmail, or sharing a
thumb drive in a drawer with the Sword of Many Truths, or scribbled in a notebook in your basement, dust it off and
enter it using our handy tools.

## Duplicating an existing Event Group

If you want to create a new Event Group based on an Event Group that already exists in OpenSplitTime (for example,
from a prior year), you can easily duplicate an Event Group.

1. Make sure you are logged in and have owner privileges for your Organization.

1. Go to **My Stuff > My Organizations**, then click on your Organization and click on the Event Group.

1. Click on **Admin > Construction > Group Actions > Duplicate group**.

1. Enter the name and date for the new Event Group and click "Duplicate Event Group".

1. OpenSplitTime will duplicate the Event Group and all Events within the original Event Group, but will not add any
Entrants.

1. Make any changes as necessary. For example, if the start time for your 100K was 6:00 last year but you've moved
it to 5:30 this year, you can click Admin > Construction, and then click the pencil to edit your event.

1. Now [import your Entrants](#formatting-your-entrant-data-for-import) and you are ready to go.

## Creating a new Event with an existing Organization

If your new Event Group doesn't share common characteristics with any existing Event Group, follow these steps to
create a new one:

1. Visit your Organization page, and click "New event group".

1. If you are using the same Course as last time, check to make sure all the Splits you need have been associated,
or click the check mark boxes to add or remove Splits for this event. If you are using a new Course, create it using
the fields provided.

1. Add your Entrants' information manually or import it.

1. Use OST Live or import existing time data. Please [contact us](mailto:mark@opensplittime.org) if you
need help with importing time data.

## Formatting your Split data for import

OpenSplitTime makes it easy (or at least reasonably doable for mere mortals) to import your data into the system.
To start, you'll need to get your data into comma-separated-value (.csv) format. Data is imported in two
steps: Split import and Entrant import.

## Split Import Template

First, download a template. After you create your Course and Event, go to **Admin > Construction**,
click the blue pencil icon to edit the Course, and then click **Import > Download CSV Template**. A blank
splits template will be downloaded by your browser. Use this template to add split names, distances, latitude,
longitude, and elevation. The "Sub split kinds" column should be either "in" (if you are recording only one time,
as runners enter the aid station) or "in out" (if you are recording times both in and out of the aid station).
When the spreadsheet is complete, save it back out (remember to save it in CSV format) and then return to
**Admin > Construction > [Setup Course Button] > Import > Import splits**.

## Formatting your Entrant data for import

Once your Splits are in place, it's time to get the Entrant data in.

Again, the first step is to download a template, which you can do from **Admin > Construction > Entrants >
Import > Event Group Entrants > Download CSV Template**. Required fields are First Name, Last Name, and Gender. But please add as much
information as you have about your entrants, as this will help OpenSplitTime match up your entrants with existing
entrants in the database. In particular, birthdate (or age) and city/state are helpful.

In addition, if your event group has multiple events, **you will need to include an Event Name field.
** Data in this field must exactly match the "Short Name" of each event in the group.

## Entrant import

If you are importing Entrant data without times (for example, if this is a new event that has not yet started),
simply complete the template, save it as a CSV file, and import it using
**Admin > Construction > Entrants > Import**.

One optional import field is "Comments." If you want to include comments about an entrant, import them in this
field. **Your comments will be not be visible to the public.** These comments appear, for example,
in the Finish Line view, and you can use them as announcer's notes when an entrant finishes the event.

Another optional import field is "Beacon URL." This allows you to link to an external GPS tracking service, like
MAProgress, SPOT, or TrackLeaders. If you use this field, you should include the entire URL for your entrants,
such as "https://silvertonultramarathon-2019.maprogress.com?bib=25".

## Experiment!

Sign in, click around, and play with the various screens and buttons. Add some things manually and import some data.
If you get hopelessly lost and make a mess, just delete your Event, and all Entrants and Split Times related to the
Event will be deleted with it. You cannot, accidentally or otherwise, delete any data that you did not create
yourself.

In addition, any Organization, Course, or Event Group that you create will remain private until you decide to make
it public.

We are here to help! If you run into a snag, please [contact us](mailto:mark@opensplittime.org) and we'll get right back to you.

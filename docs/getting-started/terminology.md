---
title: Terminology
parent: Getting Started
nav_order: 3
---

# Terminology

## Organizations

Your Organization allows certain users authorization to add, edit, or delete data for your events.
For example, the volunteer crew might be given access to add new time data as it is
received, or a friend might be given access to upload and organize archival data from earlier events.

Each Organization has a single Owner and can have one or more Stewards. Stewards have authority to enter and
modify time records and handle other ministerial tasks. The Owner has authority to make major changes, such as
creating or deleting an Event Group.

## Courses

A Course is the place where an event is physically run. You can give your Course a name and a description that will
appear when users view its page. You will also be asked for information about total length and vertical gain/loss,
and this data will be used to create the finish Split for the Course.

## Splits

You need a Split anywhere you want to record times. A course comes ready-made with a start and finish split. For
events where just finish times will be recorded, that's all you need. If you want to record times in between, you
can add intermediate splits. On an ultramarathon course, these would normally be your aid stations. For a
non-organized solo effort, these might be meaningful places, like summits or road crossings, where you measure your
progress. For road races they could be mile or kilometer markers.

Splits always have a fixed distance from the start of a Course, and only one Split can exist at a given distance. By
default, a Split will be set to record a single time for each Entrant, and you would normally record the Entrant
when he or she first reaches the Split (for example, when he or she enters an aid station). Some events record both
"in" and "out" times through aid stations. You can designate a Split for "in" times only or for both "in" and "out"
times.

Splits may include elevation/latitude/longitude data manually entered or chosen with the help of a map.

## Event Groups

An Event Group is owned by an Organization, and it has one or more Events contained within it. No one person can
participate in more than one of the Events within an Event Group. Another way to think of it is that all bib
numbers within an Event Group must be unique.

For example, if you are running 6-hour, 12-hour, and 24-hour events all on the same day, an entrant would have to
choose to run one of those events. Also, you would not have a bib number 101 in the 6-hour event and a different
bib number 101 in the 12-hour event. So the 6-, 12-, and 24-hour events would fit nicely into a single Event
Group.

When entering times using Live Entry or OST Remote, you are entering times not for a single Event, but rather for
an Event Group. For example, if you have 6-hour, 12-hour, and 24-hour events within a single Event Group, you
would have the ability to use a single iPad running OST Remote to enter times for entrants in all of those events.

## Events

An Event is just that--a single event run on a single Course, with one or more Entrants participating in the
event. If you have groups running different Courses (even if they are happening at the same time), you'll need to
have an Event for each Course, and those Events would belong to a single Event Group.

For example, Quad Rock 50 (2025) and
Quad Rock 25 (2025) are two separate Events belonging to a single
Event
Group, Quad Rock 2025, even though both are run at the
same time and even though the 25-mile Course covers the same territory as the 50-mile Course.

## People

A Person is someone who has participated in one or more Events. When a new Event is imported, an intelligent
matching system attempts to reconcile new Entrants with existing People, avoiding duplication in the database.

## Entrants and Efforts

An Entrant is a Person in a single Event. To ensure consistency and avoid duplication of People in the database,
Entrant data includes the person's basic information (name, gender, and age) and also relates to the
Split Times recorded. The final results for your Event will be a collection of Entrants with the times they
recorded at various Splits.

An Effort is the same as an Entrant, except that we generally use the term Entrant to refer to the Entrant alone,
and we use the term Effort to refer to the Entrant and all of his or her related Split Times.

## Raw Times

Raw Times are the permanent timing log created as an Event Group is taking place. As time data are captured by
volunteers using [OST Remote](../ost-remote/) or manually entered using the Live Entry view, they are recorded first as Raw Times.

Raw Time data is captured in the form it comes in, warts and all. Human error is intentionally preserved to ensure
a
complete record. If a volunteer enters Bib 101 coming in to Pole Creek at 10:30, and later enters Bib 101 coming
in
again to Pole Creek at 10:45, both records will be preserved as Raw Times. Later analysis will be needed to
determine whether the 10:30 entry or the 10:45 entry was correct. And the incorrect entry is still valuable, as it
might match with another runner whose bib was misread by the volunteer.

Raw Time data is not intended for public view; it is a behind-the-scenes record. Our best interpretation of the
Raw Time record is presented to the public in the form of Split Times.

## Split Times

Split Times are the publicly viewable time data for Entrants at Splits along the Course. A typical ultramarathon
might have thousands of Split Times in a single Event. OpenSplitTime checks Split Time data as it is entered,
submitted, and imported, and uses statistical analysis to flag any times that appear bad or questionable.

Split Times should not be confused with Raw Times, which are the original, often
messy, behind-the-scenes log of all recorded times, whether correct or incorrect.

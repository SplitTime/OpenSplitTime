---
title: Profile Privacy
parent: User Information
nav_order: 2
---

# Profile Privacy

OpenSplitTime publishes most event participation data on public pages and through its API. This page describes the controls you have over what appears publicly.

## Hiding your age

If you have claimed your person record, you can suppress your age on public pages:

1. Sign in and go to your profile.
2. Click **Edit**.
3. Check **Hide my age on public pages** and save.

When enabled, your age is omitted from:

- Your public person profile and bio line
- Your effort history and event results pages
- The `currentAge` and `age` fields in API responses

Your birthdate is still stored and is used internally for age-group scoring.

### What remains visible

- **Age-group categories.** If an event places you in an age-group category (for example `M40-49`), that category is still visible on public results pages. Hiding your age does not move you out of your age group or remove you from age-group awards.
- **Other profile fields.** Your name, gender, location, and event history remain public unless the event itself is concealed.

### Who can still see your age

Administrators and event organizers authorized to edit your person record still see your real age in the admin UI and through the API. This is intentional — race directors need that information to run their events.

## Showing only your initials

If you have claimed your person record, you can replace your full name with initials on public pages:

1. Sign in and go to your profile.
2. Click **Edit**.
3. Check **Show only my initials on public pages** and save.

When enabled, your name is displayed as initials (for example, "Mark Oveson" becomes "M. O.") on:

- Your public person profile and the people index
- Effort history and event results listings
- CSV exports of event results
- `firstName` and `lastName` fields in API responses

Your first and last name are still stored in the database so that results remain correctly attributed to you. Only the display is obscured.

### Who can still see your full name

Administrators and event organizers authorized to edit your person record still see your real name in the admin UI and through the API. Race directors need that information to run their events.

## Hiding private contact information

Email address, phone number, birthdate, and emergency contact information are never shown on public pages. They are only exposed through the API to administrators and event organizers authorized to edit your record.

## Claiming your person record

To use any of these controls, you need to claim your person record first. From your person page, click **Claim this profile** if you see it there. Once claimed, you can edit your own profile directly.

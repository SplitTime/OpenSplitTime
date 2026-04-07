---
title: RunSignup API Keys
parent: RunSignup Integration
nav_order: 1
---

# RunSignup API Keys

To connect OpenSplitTime to RunSignup, you will need a RunSignup API key and API secret.

RunSignup supports more than one way to obtain API credentials. The right method depends on whether you are acting as a **race owner** for a specific event or as a **race timer** working across multiple client events.

## Which type of API key should I use?

Use the option that matches your role:

- **Race owner:** Use event-level credentials from the specific RunSignup race you want to connect to OpenSplitTime.
- **Race timer:** Use timer-account credentials from your RunSignup timer account.

The difference matters:

- **Race owner keys** are intended for a single race or event.
- **Race timer keys** can be reused across multiple races and events that the timer services.

## For race owners

If you manage a race in RunSignup and only need to connect that race to OpenSplitTime, use the API credentials attached to that specific race.

### How to find event-level API credentials

1. Sign in to RunSignup.
1. Open the specific race or event you want to connect.
1. Use the left sidebar search and search for **API**.
1. Open the **Info Sharing** page.
1. Scroll to the bottom of the page.
1. Open the **API Keys** accordion.
1. Copy the API key and API secret shown in the first plain-text credential area.

### Important note for race owners

RunSignup may also show other API-related credentials, including generated v2 keys. For OpenSplitTime, use the plain-text API key and API secret shown for the race, not a generated v2 key.

Because these credentials belong to a specific race, they are generally appropriate when you are connecting OpenSplitTime to that one race only.

## For race timers

If you are a professional timer or timing company managing multiple events, use credentials from your RunSignup timer account.

According to RunSignup's API documentation, permanent API keys are available for timers, and timer credentials are associated with the timer account rather than a single event. That makes them the better choice when you need credentials that work across multiple races.

### How to obtain timer-level API credentials

1. Sign in to RunSignup using the account associated with your timer account.
1. Open your **Timer** account area in RunSignup.
1. Locate the API access or API credentials section for the timer account.
1. Copy the timer account API key and API secret.

### Important note for race timers

Timer credentials can be used across multiple events that your timer account services. If you time many races, this is usually the most efficient option.

## Entering the credentials into OpenSplitTime

Once you have the correct RunSignup API key and API secret:

1. Open OpenSplitTime.
1. Go to your user settings or credentials area.
1. Enter the `api_key` value.
1. Enter the `api_secret` value.
1. Save your credentials.
1. Connect the appropriate RunSignup race to your OpenSplitTime Event Group.

## Summary

- Use **race owner credentials** when connecting one specific RunSignup race.
- Use **timer credentials** when you need one set of credentials that can work across multiple races.
- In either case, OpenSplitTime needs both an **API key** and an **API secret**.

## Sources

This page is based on:

- the workflow documented in OpenSplitTime issue [#1159](https://github.com/SplitTime/OpenSplitTime/issues/1159){:target="_blank"}
- RunSignup API documentation at [runsignup.com/API](https://runsignup.com/API){:target="_blank"}
- RunSignup's getting started documentation for API access

---
title: RunSignup API Keys
parent: RunSignup Integration
nav_order: 1
---

# RunSignup API Keys

To connect OpenSplitTime to RunSignup, you need a RunSignup **API key** and **API secret**. RunSignup exposes two kinds of credentials: keys tied to a specific race, and permanent keys tied to your account. The race-specific keys only authenticate against that one race; account-level (timer / partner / affiliate) keys work across every race your account is associated with.

## Race-specific API keys

Most race directors will use the keys shown on their race's Info Sharing page:

1. Sign in to RunSignup.
1. Open the specific race you want to connect.
1. Use the left sidebar search to search for **API**.
1. Open the **Info Sharing** page.
1. Scroll to the bottom of the page.
1. Open the **API Keys** accordion.
1. Copy the API key and API secret from the first plain-text credential pair.

RunSignup may also display generated v2 keys lower on the same page — ignore those. OpenSplitTime uses the plain-text key/secret pair only.

## Account-level (timer) API keys

If you time multiple races, you can use one set of permanent credentials instead of pulling separate keys for every race. RunSignup documents this on its [Getting Started](https://runsignup.com/API/GettingStarted){:target="_blank"} page, which describes permanent API keys for timers (as well as for affiliates and partners).

## Entering the credentials into OpenSplitTime

Once you have the API key and secret:

1. In OpenSplitTime, open the user menu and go to **Settings → Credentials**.
1. Add a RunSignup credential set, pasting the **api_key** and **api_secret** values from RunSignup.
1. Save.
1. Open the Event Group you want to connect, choose **Connect Service**, and pick **RunSignup**. Enter the RunSignup race ID to link the two.

## References

- [RunSignup API Documentation](https://runsignup.com/API){:target="_blank"}
- [RunSignup API – Getting Started](https://runsignup.com/API/GettingStarted){:target="_blank"} — describes permanent keys for timers, partners, and affiliates
- OpenSplitTime issue [#1159](https://github.com/SplitTime/OpenSplitTime/issues/1159){:target="_blank"} — original walkthrough of finding a race's API Keys accordion

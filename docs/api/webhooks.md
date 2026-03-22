---
title: Webhooks
parent: API
nav_order: 3
---

# Webhooks

## Webhooks

Webhooks are a way for you to receive notifications when certain updates occur in OpenSplitTime. OpenSplitTime uses
Amazon SNS to send webhook requests.

You can subscribe to webhooks for any Event in your Organization. When an Event is updated, OpenSplitTime will instruct Amazon SNS to send a
POST request via HTTP or HTTPS to the endpoint you specify. The request will contain a JSON payload with information about the update. You can
use this information to take action within your own systems, such as making a request to the OpenSplitTime API for updated information.

## Overview

Follow these steps to get set up with your webhook subscription:

1. Set up an endpoint to receive webhook requests.

1. Create a subscription for the endpoint you created in step 1.

1. Confirm your subscription by making a GET request to the SubscribeURL provided by Amazon SNS.

1. Monitor your endpoint and take appropriate action as webhook requests are received.

## Set up an Endpoint

On your own website, set up an endpoint. Your endpoint must be accessible via HTTP or HTTPS.

For testing purposes, you can use a service like Webhook.site to create a temporary
endpoint that will allow you to see the webhook requests, making it easier to code up to the requests in production.

For production usage, you will need to have an endpoint on your own site. The endpoint **must accept POST requests** and must meet
the other requirements described in the relevant [
Amazon SNS documentation](https://docs.aws.amazon.com/sns/latest/dg/sns-http-https-endpoint-as-subscriber.html).

## Create a Subscription

Create a subscription for the endpoint you created in step 1. You can do this by visiting the Event page for the Event you want to subscribe
to, then click Results > Follow and follow the link shown in the Webhooks section.

Once you are on the Webhooks page, click the "Add Subscription" button. Choose "HTTP" or "HTTPS" and then Enter the endpoint URL you created
in step 1. **The endpoint you enter must begin with "http://" or "https://" depending on the protocol you choose.**
Click "Create Subscription". Your webhook subscription will appear in the list under the relevant Event.

## Confirm Your Subscription

Your subscription will initially be in a "Pending Confirmation" state. At the time you create your subscription, Amazon SNS will immediately
send a confirmation POST request to your endpoint. The request will contain a JSON payload with a "SubscribeURL" property.

**You must make a GET request to this URL to confirm your subscription.**

If you did not receive the subscription confirmation, you can always delete your pending subscription and create a new one. This will
trigger a new confirmation request to be sent.

## Monitor Webhook Requests

Once you have confirmed your subscription, your subscription will be in a "Confirmed" state. You will now receive webhook requests when
updates occur to the subscribed Event in OpenSplitTime.

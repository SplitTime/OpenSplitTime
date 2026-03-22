---
title: Queries
parent: API
nav_order: 2
---

# Queries

## Querying the API

The OpenSplitTime API follows the JSON API standard, described in detail
at [jsonapi.org](https://www.opensplittime.org). You can query for a collection of
records using the pluralized model name, and if you have an individual record id, you can query for an individual
record.

## Standard Index Queries

The models available for index queries are:

1. Organizations

1. Courses

1. Event Groups

1. Events

1. People

Query any of these models by passing a GET request to the applicable endpoint and including your API key as a
bearer authorization in the request header. For example (you will need to replace your.api.key with
your own API Key):

$ curl -H "Authorization: bearer your.api.key" https://www.opensplittime.org/api/v1/event_groups

Records are returned in batches of 25. Links are included in the response header to obtain additional batches.

Remember that individual records are generally more useful and
**response times will generally be faster for individual record queries than for index queries**.

## Index Queries Scoped to a Parent Record

In addition to standard index queries, you may query for records scoped to an individual parent record. Currently, this feature is available
for Raw Times scoped to an event group.

Query for Raw Times by passing a GET request to the endpoint shown below and including your API key as a
bearer authorization in the request header:

$ curl -H "Authorization: bearer your.api.key" https://www.opensplittime.org/api/v1/event_groups/hardrock-100-2024/raw_times

Records are returned in batches of 25. Links are included in the response header to obtain additional batches.

## Standard Individual Record Queries

Individual records are generally more useful and response times will be much faster. You can query for an
individual record using its id.

Most records in OpenSplitTime have both a numeric id (the unique database id) and a "slug" or "friendly" id,
which is used in the URL for easy readability by humans. The OpenSplitTime API will respond to either the numeric
id or the slug. For example, the following two queries (remember to use your own API Key in place of
your.api.key):

$ curl -H "Authorization: bearer your.api.key" https://www.opensplittime.org/api/v1/events/5

or

$ curl -H "Authorization: bearer your.api.key"
https://www.opensplittime.org/api/v1/events/hardrock-100-2013

will return exactly the same result.

## Inclusions

Most record queries will return relationships that include the type and id of related records. You can include
full data for these relationships using an include parameter in your query (remember to use your own
API Key in place of your.api.key):

$ curl -H "Authorization: bearer your.api.key"
https://www.opensplittime.org/api/v1/events/5?include=efforts

## Special Queries

The OpenSplitTime API supports some additional queries that go beyond standard RESTful endpoints. In particular,
you can query for an event with all of its efforts and related split times in this manner:

$ curl -H "Authorization: bearer your.api.key" https://www.opensplittime.org/api/v1/events/5/spread

The response is not a standard JSON API response, but rather a more compact version that includes all
time data for the event. Time data can be returned in three formats: elapsed, absolute, and segment. The format
is determined by the displayStyle parameter. If no displayStyle parameter is passed,
results will be returned with absolute times.

For example, to obtain event time data with elapsed times, the request would look like this:

$ curl -H "Authorization: bearer your.api.key"
https://www.opensplittime.org/api/v1/events/5/spread?displayStyle=elapsed

## Improving Performance

The more data you request, the longer the response time is likely to be, particularly when many child records are
included in your response. Smaller, targeted requests will naturally be faster. Always use an individual record
query instead of an index query when you know the id of the record for which you are querying.

The OpenSplitTime API also supports the filter and fields limiters per
the [JSON API standard](https://www.opensplittime.org). Please be judicious in your use,
and **limit the records and fields you request to data that is needed for your project**. This will
reduce the load on the OpenSplitTime servers and result in faster response times for your project.

## Posting Raw Times

You can post raw time data in real time to your events using the OpenSplitTime API. This is how OST Remote communicates time data to
OpenSplitTime. To post raw times in bulk, you will need to post to the endpoint
/api/v1/event_groups/:id/import.

## Raw Time Data Format

The body of your POST should look something like this:

{
"data": [
{
"type": "raw_time",
"attributes": {
"source": "my-source-device-with-unique-id",
"sub_split_kind": "in",
"with_pacer": "false",
"entered_time": "2023-08-09 09:16:01-6:00",
"split_name": "Telluride",
"bib_number": "4",
"stopped_here": "false"
}
},
{
"type": "raw_time",
"attributes": {
"source": "my-source-device-with-unique-id",
"sub_split_kind": "out",
"with_pacer": "false",
"entered_time": "2023-08-09 09:16:06-6:00",
"split_name": "Telluride",
"bib_number": "4",
"stopped_here": "false"
}
},
{
"type": "raw_time",
"attributes": {
"source": "my-source-device-with-unique-id",
"sub_split_kind": "in",
"with_pacer": "false",
"entered_time": "2023-08-09 09:16:16-6:00",
"split_name": "Telluride",
"bib_number": "1",
"stopped_here": "false"
}
}
],
"data_format": "jsonapi_batch",
"limited_response": "true"
}

## Attributes

The limited_response field is optional. If set to "true", the response
will include no body. Otherwise, the response will include a body with the posted Raw Time records.

The data_format field must be set to "jsonapi_batch".

For the attributes, the following rules apply:

Field
Required?
Notes

source
Yes
Must be a string. Highly recommended that this be unique to the device posting the data as this will help you diagnose any data issues.

sub_split_kind
Yes
Must be one of "in" or "out". If the split is set to record only
"In" times, then this must always be "in".

with_pacer
No
Must be one of "true" or "false".

entered_time
Yes
Must be a string in the format "YYYY-MM-DD HH:MM:SS-6:00". The time zone offset must be
included. The time zone offset must be in the format "+HH:MM" or "-HH:MM".

split_name
Yes
Must be a string. Must exactly match the name of a split that is used in the Event Group.

bib_number
Yes
Must be a string. This should match the bib number of an existing participant in the Event Group, but any number will be accepted.
May include only digits 0-9 or "*".

stopped_here
No
Must be one of "true" or "false".


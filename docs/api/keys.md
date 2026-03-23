---
title: API Keys
parent: The OpenSplitTime API
nav_order: 1
---

# API Keys

Once you have an account, you will need to pass your credentials to the OpenSplitTime API authorization
endpoint to receive an API Key. Get an API Key by making a POST request to `/api/v1/auth`
with your user email and password, in this manner:

```bash
$ curl --data "user[email]=you@example.com&user[password]=yourpassword" \
  https://www.opensplittime.org/api/v1/auth
```

Of course, you will need to replace `you@example.com` with your own email address and
`yourpassword` with your own password.
**The examples in this guide use the LINUX curl utility, but you can use any utility capable of
creating an HTTP POST request.**

OpenSplitTime will return a JSON response that looks something like this:

```json
{
  "token":"eyJhb.GcJIUz.I1Ni", 
  "expiration":"2019-10-19T04:20:18.407Z"
}
```

The value of the `token` key is your API Key. In the example above, the API Key would be
`eyJhb.GcJIUz.I1Ni`.

## Security

The OpenSplitTime API uses a secure `https` connection, so your credentials will be encrypted during
transfer. As always, you should use measures to ensure your password and any API Keys are kept secret and stored
in a safe way in your client application.

## API Key Lifespan

For additional security, **the API Key issued to you will expire after 3 days**. If you need to use the
API for a longer period, you will need to obtain a new API Key.

For reference, when you obtain an API Key,
**the expiration date and time is included in the response**.

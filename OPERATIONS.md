# Operations Runbook

Internal operations notes for running OpenSplitTime in production. This is **not** end-user or product
documentation (that lives in `docs/`, published to docs.opensplittime.org) — it's a runbook for whoever
is operating the infrastructure.

The app is hosted on DigitalOcean droplets, managed by Hatchbox, fronted by Cloudflare, with a Caddy
load balancer in front of the web backends:

```
Cloudflare  ->  load balancer (Caddy)  ->  web backend 1 (Caddy -> Puma)
                                        ->  web backend 2 (Caddy -> Puma)
                                        ->  ...
```

Hostnames, IPs, and tokens are intentionally written as placeholders here (`<load-balancer-host>`,
`<backend-host>`, `<backend-ip>`, `<db-host>`) — this file is in a public repository. Keep it that way.

---

## Health check: `/up`

The app exposes `GET /up`, wired in `config/routes.rb` to the stock `Rails::HealthController`:

```ruby
get "up" => "rails/health#show", as: :rails_health_check
```

It returns **200** once the app has booted, and 503 only if rendering itself raises. **It deliberately
does not query the database.** A per-probe `SELECT 1` was considered and rejected: because every backend
shares one Postgres, a DB blip — or merely a slow DB under load — could time out *every* backend's probe
at once and pull the whole fleet from rotation, turning a database hiccup into a total outage. The stock
check can never take the entire fleet down, and it still catches the failure class we actually hit (a
backend that never finishes booting). See the design discussion on issue #2155 / PR #2156.

---

## Load-balancer active health checks

**Why this matters (real incident).** When a new backend was added to the LB but couldn't boot (its IP
wasn't whitelisted in the database firewall — see the provisioning checklist below), it held its port
without accepting connections and returned 502 for every request. The LB kept sending it ~half the
traffic and the origin overloaded. The Caddy journal for that window shows **no health-check activity at
all** — nothing removed the bad backend automatically, and the outage lasted ~40 minutes until it was
removed **by hand** via the admin API. Passive checks alone don't catch this: a 502 *is* a response, so
the LB counts the backend as "responding."

**Active** health checks fix exactly this — the LB probes each backend's `/up` directly on a fixed
interval, independent of user traffic, and pulls a backend that fails the probe within seconds.

### Configuration

Caddy on the LB runs its config via the admin API (there may be no static Caddyfile — the live config is
`curl -s localhost:2019/config/`). The health-check block lives on the `reverse_proxy` handler. Expressed
as a Caddyfile fragment (map to JSON if that's how the config is managed; **verify directive names against
the running Caddy version** — check `caddy version`):

```
reverse_proxy <backend-1>:<port> <backend-2>:<port> {
    # active checks
    health_uri      /up
    health_interval 10s
    health_timeout  5s
    health_status   2xx

    # passive checks (backstop)
    fail_duration    10s
    max_fails        3
    unhealthy_status 5xx
}
```

Equivalent JSON on the reverse_proxy handler (durations are integer **nanoseconds**; `10s = 10000000000`):

```json
"health_checks": {
  "active":  { "path": "/up", "interval": 10000000000, "timeout": 5000000000, "expect_status": 200 },
  "passive": { "fail_duration": 10000000000, "max_fails": 3, "unhealthy_status": [500, 502, 503, 504] }
}
```

### Applying it

Caddy on the LB is managed by Hatchbox. Apply the change through Hatchbox's Caddy configuration so it is
**persisted** — a raw `curl` push to the admin API works until the next deploy, which regenerates the
config and wipes it. If you must push directly for a quick test, snapshot first (see below) and
re-persist through Hatchbox afterward.

### Verifying

```bash
# from the LB host
curl -f http://<backend-host>:<port>/up            # 200 from each backend directly
curl -s localhost:2019/reverse_proxy/upstreams | jq # per-backend health + in-flight request counts
```

Then simulate a failure: stop Puma on one backend and confirm Caddy marks it unhealthy in
`/reverse_proxy/upstreams` and the site keeps serving 200 from the rest (no 502s). Bring it back and
confirm it re-enters rotation.

---

## Reverse-proxy hardening

In the same incident the origin didn't just return clean 502s — it **overloaded** ("Timeout after
connect (your server may be slow or overloaded)"), because a backend that holds its port without
accepting hangs the LB's connections rather than failing fast. Two settings on the `reverse_proxy` make
a bad backend fail fast instead of swamping the LB (belt-and-suspenders with active checks — even before
a probe marks a backend down, requests to it fail fast):

```
reverse_proxy <backend-1>:<port> <backend-2>:<port> {
    transport http {
        dial_timeout            5s   # give up quickly on a backend that isn't accepting
        response_header_timeout 10s  # don't wait forever for a hung backend
    }
    lb_try_duration 5s               # cap how long a single request cycles upstreams
    lb_retries      2                # cap failover amplification onto healthy backends
}
```

Verify directive names/semantics against the running Caddy version before applying.

---

## New-server provisioning checklist

Hatchbox handles most provisioning. The items below are the ones that have bitten us and must be checked
explicitly when adding a web backend:

- [ ] **Whitelist the new droplet's IP in the DigitalOcean managed-Postgres firewall _before_ adding it
      to the LB.** This was the root cause of the outage above — the backend couldn't reach the DB, never
      finished booting, and served 502s from behind its own Caddy.
- [ ] `curl -f http://<new-backend-host>:<port>/up` returns 200 on the new backend directly.
- [ ] The backend shows **healthy** in `curl -s localhost:2019/reverse_proxy/upstreams` on the LB before
      it takes user traffic.

---

## Keeping servers current (Hatchbox config updates)

When Hatchbox flags a server as "outdated," its **Update configuration** action re-runs the managed
config and restarts services (including Caddy). Treat the LB with the same care as any LB change; a
freshly provisioned node is already on the latest config and doesn't need this.

Safe ordering:

1. Confirm the other backend is **healthy and in rotation** — it's your safety net for the restart.
2. Snapshot the LB's live config first:
   ```bash
   curl -s localhost:2019/config/ > caddy-before-update.json
   ```
3. Update the **LB first**, in a low-traffic window. Its Caddy restarts (brief blip). Verify the site
   loads and both backends show in `/reverse_proxy/upstreams`; diff the live config against the snapshot
   (watch the `reverse_proxy` and TLS/ACME sections for anything the update changed).
4. **Re-apply** the active-health-check + hardening config if the update reset it, persisted through
   Hatchbox.
5. Update **backends only after** active health checks are in place — the checks turn each backend's
   restart into a graceful drain instead of a passively-handled failure. **Never update a backend while
   it is the only healthy one.**

---

## Diagnosing an outage on the LB

The LB is `<load-balancer-host>` (Caddy runs as a systemd service, logs to the journal):

```bash
systemctl status caddy                                   # running? config path? recent lines
sudo journalctl -u caddy --since "<start>" --until "<end>" --no-pager \
  | grep -iE 'health|unhealthy|upstream|dial|timeout|refused|no upstreams|"status":5'
curl -s localhost:2019/reverse_proxy/upstreams | jq       # current per-backend health
curl -s localhost:2019/config/ | jq '.apps.http'          # live reverse_proxy config
```

`marking upstream … unhealthy` for a *good* backend points at overload/cascade; hung/timed-out upstream
dials point at a backend holding its port without accepting. Note that per-request access logs may not be
in the journal (only errors/admin/TLS), so attributing individual requests to a specific backend may not
be possible from the LB alone.

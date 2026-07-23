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
`<backend-host>`, `<backend-ip>`, `<site>`, `<db-host>`) — this file is in a public repository. Keep it
that way.

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
without accepting connections and its own Caddy returned 502 for every request. The LB kept sending it
~half the traffic and the origin overloaded; the site was down for **~25 minutes** until the backend was
removed **by hand** via the admin API.

The reason it wasn't pulled automatically is in the LB's *passive* health check. Hatchbox configures
passive as `{fail_duration, max_fails}` with **no `unhealthy_status`**, so Caddy only counts
*connection-level* failures — an HTTP 502 is a completed response, not a failure. The bad backend's 502s
counted as "responding," so passive never removed it.

**Active** health checks close that gap: the LB probes each backend's `/up` on an interval and treats a
non-2xx (or a refused/timed-out connection) as unhealthy — exactly the 502-from-the-backend's-own-Caddy
case that passive ignored.

### Enabling — Hatchbox does this natively; don't hand-edit Caddy

Hatchbox generates the LB's Caddy config — the `reverse_proxy` block and its `health_checks` — inside an
opaque `%{apps}` template. **Do not** patch the running Caddy via the admin API to add active checks; the
next deploy regenerates the config and wipes it. Instead, set the app's **health-check path to `/up`** in
Hatchbox; it then emits the `health_checks.active` block (and sets the correct upstream `Host` header so
the probe routes to the app).

Two things Hatchbox does **not** let you tune, worth knowing:
- **No interval is set, so Caddy defaults to ~30s.** Failover takes up to ~30s — far better than the
  ~25-minute outage, but during that window the bad backend still gets ~half the traffic. Tighten only if
  Hatchbox ever exposes an interval/timeout setting.
- The **passive block stays `max_fails: 10` with no `unhealthy_status`** — effectively inert for a 502, as
  above. Active is doing the real work; don't rely on passive.

### Verifying (tested procedure)

Run on the LB host. Step 3 downs a backend, so do it in low traffic (or on staging) with the *other*
backend confirmed healthy first.

1. **Confirm the active block is live** (Hatchbox generated it):
   ```bash
   curl -s localhost:2019/config/ | jq '.. | objects | select(.handler? == "reverse_proxy") | .health_checks'
   ```
   Expect an `active` object with `uri: "/up"` (and a `Host` header) alongside `passive`.

2. **Confirm every backend currently reads healthy** — proves the probe *succeeds* against a good backend,
   catching a mis-set Host/path that would false-positive a healthy node:
   ```bash
   curl -s localhost:2019/reverse_proxy/upstreams | jq   # each upstream should show fails: 0
   ```

3. **Down one backend; confirm it's pulled within ~an interval while the site stays 200.** Two ways:

   *Cleanest — block the LB's probe (no app touched, one-line toggle):* on the target backend,
   ```bash
   sudo iptables -I INPUT -p tcp --dport 80 -j DROP    # down (only port 80 — SSH stays open)
   sudo iptables -D INPUT -p tcp --dport 80 -j DROP    # up
   ```

   *Truer 502 reproduction — stop the app.* Hatchbox runs the app as **user** systemd services under the
   deploy account, and web is **socket-activated** — you must stop the `.socket` too or the next probe
   re-spawns Puma. Find the unit names first (`systemctl --user list-units --type=service` — e.g.
   `<app>-web.service` + `<app>-web.socket`), then:
   ```bash
   systemctl --user stop  <app>-web.socket <app>-web.service   # down (no sudo — these are user units)
   systemctl --user start <app>-web.socket <app>-web.service   # up
   ```
   (Leave the `<app>-worker` unit alone — it doesn't serve `/up`.)

   Watch from the LB while it's down:
   ```bash
   watch -n2 'curl -s localhost:2019/reverse_proxy/upstreams | jq'                   # backend drops out
   sudo journalctl -u caddy -f | grep -iE 'unhealthy|healthy|upstream'              # "marking upstream … unhealthy"
   for i in $(seq 1 40); do curl -so /dev/null -w "%{http_code}\n" https://<site>/up; sleep 1; done  # stays 200
   ```
   The downed backend should leave the healthy set within ~30s and the site should never 502; restore it
   and it rejoins within ~30s. (Watch for Hatchbox restarting the app on its own; the firewall method is
   the more controllable of the two.)

---

## Reverse-proxy hardening (not tunable on Hatchbox)

In the same incident the origin didn't just return clean 502s — it **overloaded** ("Timeout after connect
(your server may be slow or overloaded)"), because a backend that holds its port without accepting hangs
the LB's connections rather than failing fast. Bounded backend timeouts (`dial_timeout`,
`response_header_timeout`) plus capped retries (`lb_try_duration`, `lb_retries`) would make a bad backend
fail fast instead of swamping the LB — belt-and-suspenders with active checks.

But these live inside Hatchbox's generated `reverse_proxy` block (the opaque `%{apps}`), so there's **no
supported way to set them on Hatchbox** — a direct admin-API push is wiped on the next deploy. Leave them
to a Hatchbox feature/config request, or apply them directly only if the proxy is ever self-managed (e.g.
a move to Kamal + kamal-proxy). Active health checks already cover the primary failure mode.

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
4. **Confirm the active health check survived** — it's a Hatchbox app setting, so the regenerated config
   should still contain `health_checks.active` (re-run the step-2 `jq` check). There's no manual config to
   re-apply; that's Hatchbox's job.
5. Update **backends only after** active health checks are confirmed — the checks turn each backend's
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

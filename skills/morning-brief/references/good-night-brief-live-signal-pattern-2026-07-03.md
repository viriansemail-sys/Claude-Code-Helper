# Good Night Brief live-signal pattern — 2026-07-03

Use when composing a manual 21:30 Good Night Brief from live signals.

Observed useful checks:
- Scheduled jobs: list cron jobs first; note `last_delivery_error` if the brief generation/delivery path is still unresolved.
- Live system: `date`, `uptime`, `nvidia-smi`, and `docker ps` give enough operational truth for STATUS.
- Containers: summarize by service family and call out unhealthy/restarting containers only; do not dump the full table.
- Hive Live: read the last ~30 lines of `hive-live/logs/watchdog.log`; if an encoder drops then recovers before 21:30, report it as an incident recovered, not a crisis.
- Supervisor log: filter for the same date before reading; the raw file is huge and old May entries are noise.
- Shipped claims: only say SHIPPED when backed by commits, logs, broadcasts, uploaded artifacts, or prior-session evidence. If not verified, say no verified code commits/items.

Pitfalls:
- Do not paste fallback/time-out text as the brief. Compose fresh from verified live signals.
- Do not over-read huge logs with `tail` if the tool returns from the beginning; use a small script/filter pattern instead.
- Night brief tone should be calm and short: HEADLINE, STATUS, SHIPPED, ON DECK, NIGHT WATCH.
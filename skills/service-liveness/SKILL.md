---
name: service-liveness
description: One-call audit of running services for any project. Checks systemctl/docker status, open ports, health endpoints, and recent error logs. Returns a structured markdown table per service with liveness verdict. Use before claiming a project is "running" or before dispatching integration tests.
metadata:
  version: 1.0.0
  author: skillforge-4.0
  timelessness_score: 8
---

# Service Liveness

One-call audit of all expected services for a project. Answers the question: **are the services actually running?**

This is the skill that catches the gap between "code shipped" and "system live." Use it before any integration test, before any release tag, and as the first step after a deploy.

## Quick Start

```
service-liveness ~/projects/analysis
→ Checks all expected services, returns liveness table

service-liveness ~/projects/analysis --node <your-node>
→ Runs checks via SSH on <your-node>

service-liveness ~/projects/analysis --format json
→ Machine-readable output for use in wave-readiness-gate
```

## Triggers

- `service-liveness <project_path>` — audit all services for a project
- `are the services running` — detect and route to this skill
- `check if services are up` — liveness check trigger
- `verify stack health` — broader stack health check
- `pre-deploy liveness check` — explicit pre-deploy invocation

## How It Works

### Phase 1 — Discover expected services

1. Look for `docs/expected_services.yaml` at `<project_path>/docs/expected_services.yaml`
2. If not found, fall back to `deploy/docker-compose.yml` — parse service names + ports
3. If neither found, ask the caller to provide a service list or run `docker compose ps` on the target node

`expected_services.yaml` format (create this if it doesn't exist):
```yaml
# <project_path>/docs/expected_services.yaml
node: <your-node>                        # default SSH target (omit = localhost)
services:
  - name: aiq-agent
    port: 8090
    health_endpoint: /health
    health_method: GET
    expected_status: 200
    systemd_unit: null               # null = Docker-managed
    docker_service: aiq-agent        # matches compose service name
  - name: aiq-frontend
    port: 3001
    health_endpoint: /
    health_method: GET
    expected_status: 200
    docker_service: aiq-frontend
  - name: analysis-postgres
    port: 5432
    health_endpoint: null            # TCP-only check
    docker_service: analysis-postgres
  - name: telegram-digest
    port: null                       # no port — systemd service
    health_endpoint: null
    systemd_unit: analysis-telegram-digest.service
    docker_service: null
  - name: hot-cold-scheduler
    port: null
    health_endpoint: null
    systemd_unit: analysis-scheduler.service
    docker_service: null
```

### Phase 2 — Run checks (per service)

For each service, run these checks in order. SSH to the target node first if `node` is set.

**Docker services:**
```bash
# Container running?
ssh user@<node> "docker ps --filter name=<docker_service> --format '{{.Status}}'"

# Health (if health_endpoint defined):
ssh user@<node> "curl -sf -o /dev/null -w '%{http_code}' http://localhost:<port><health_endpoint>"

# Recent errors (last 20 lines of logs):
ssh user@<node> "docker logs --tail 20 <docker_service> 2>&1 | grep -iE 'error|exception|fatal|critical' | tail -5"
```

**Systemd services:**
```bash
# Active?
ssh user@<node> "systemctl is-active <systemd_unit>"

# Last failure (if inactive):
ssh user@<node> "systemctl status <systemd_unit> --no-pager -n 10 2>&1 | tail -15"
```

**Port check (always):**
```bash
ssh user@<node> "ss -tlnp | grep :<port>"
```

### Phase 3 — Build liveness report

Produce a markdown table with one row per service:

```
## Service Liveness Report
Project: <project_path>
Node: <node>
Checked: <timestamp>

| Service | Port | Container/Unit | Health | Last Error | Verdict |
|---------|------|----------------|--------|------------|---------|
| aiq-agent | 8090 | Up 2h | HTTP 200 | none | ✅ LIVE |
| aiq-frontend | 3001 | Up 2h | HTTP 200 | none | ✅ LIVE |
| analysis-postgres | 5432 | Up 2h | TCP open | none | ✅ LIVE |
| telegram-digest | — | inactive (dead) | — | ExecStart failed | ❌ DEAD |
| hot-cold-scheduler | — | inactive (dead) | — | unit not found | ❌ DEAD |

## Summary
LIVE: 3/5
DEAD: 2/5 (telegram-digest, hot-cold-scheduler)
DEGRADED: 0/5

## Dead Service Details
### telegram-digest
Status: inactive (dead)
Last error: ExecStart=/usr/local/bin/analysis-telegram-digest.sh failed (exit 1)
Action required: check systemd unit file exists and service is enabled

### hot-cold-scheduler
Status: unit not found
Last error: Failed to load unit: No such file or directory
Action required: deploy systemd unit — service was never installed
```

### Phase 4 — Verdict

- All services LIVE → verdict `PASS`
- Any service DEAD or DEGRADED → verdict `FAIL`
- Unknown/can't reach node → verdict `BLOCKED`

Exit semantics (for use in scripts):
- `PASS` → integration tests can proceed
- `FAIL` → block release tag; surface dead services to operator
- `BLOCKED` → SSH unreachable or missing config; surface error

## SSH Node Reference

Default node lookup order:
1. `node:` field in `docs/expected_services.yaml`
2. `--node <name>` argument
3. CLAUDE.md node table (<your-node> = `user@<lan-ip>`, node-a = `user@<lan-ip>`, etc.)

## Arguments

| Arg | Required | Default | Description |
|-----|----------|---------|-------------|
| `project_path` | yes | — | Absolute path to project root |
| `--node` | no | from config | SSH target override |
| `--format` | no | `markdown` | `markdown` or `json` |
| `--service` | no | all | Check a specific service only |

## Anti-Patterns

| Avoid | Why | Instead |
|-------|-----|---------|
| Trusting `docker compose ps` alone | Doesn't check health endpoints or systemd | Run health curl + port check |
| Checking only if container exists | Container can be up but app crashed | Always check health endpoint |
| Skipping systemd services | Daemons are often not in compose | Explicitly list in expected_services.yaml |
| Running on localhost | Services may be on remote nodes | Always SSH to target node |

## When to Use

- Before dispatching integration-smoke
- Before applying any release tag (see wave-readiness-gate)
- After any deploy or docker compose up
- First step of morning brief verification
- Any time someone claims "the service is running"

## Timelessness Score: 8/10

Core problem (are deployed services actually running?) is permanent. SSH + curl + ss/systemctl are stable primitives. The `expected_services.yaml` schema can evolve without breaking the skill pattern. Extension points: add Kubernetes support, add Prometheus metric checks, add alerting integration.

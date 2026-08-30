---
name: integration-smoke
description: Run an end-to-end user-facing flow against a live system to verify the full stack works, not just individual services. For Project Analysis: submits a real topic, polls status API, verifies NAS report exists, verifies PWA renders it, verifies Telegram fires. Parameterizable for any project that defines a flow config. Use after service-liveness passes and before applying a release tag.
metadata:
  version: 1.0.0
  author: skillforge-4.0
  timelessness_score: 8
---

# Integration Smoke

Runs an end-to-end user-facing flow against a live system. Answers the question: **can a user actually do the thing this system is supposed to do?**

This skill catches the gap between "all services up" and "the pipeline actually works." Use it after service-liveness passes, before any release tag.

## Quick Start

```
integration-smoke ~/projects/analysis
→ Runs default flow: submit topic → poll → verify report + PWA + Telegram

integration-smoke ~/projects/analysis --flow academic
→ Runs the academic-mode flow (shallow_researcher, 25k-word target)

integration-smoke ~/projects/analysis --flow default --dry-run
→ Prints the flow steps without executing
```

## Triggers

- `integration-smoke <project_path>` — run default flow
- `run integration smoke` — explicit trigger
- `end-to-end smoke test` — e2e trigger
- `verify the pipeline works` — pipeline verification
- `smoke test before tag` — pre-tag trigger

## How It Works

### Phase 1 — Load flow config

Look for `docs/smoke_flows.yaml` at `<project_path>/docs/smoke_flows.yaml`.

`smoke_flows.yaml` format:
```yaml
# <project_path>/docs/smoke_flows.yaml
node: <your-node>
default_flow: default

flows:
  default:
    description: "Submit tiny topic via shallow_researcher, verify full pipeline"
    steps:
      - id: submit_job
        type: http_post
        endpoint: "http://localhost:8090/v1/jobs/async/submit"
        body:
          topic: "smoke test - Apollo 11 mission"
          agent_type: shallow_researcher
          mode: hot
        expect_status: 200
        extract:
          job_id: ".job_id"

      - id: poll_status
        type: poll_until
        endpoint: "http://localhost:8090/v1/jobs/async/status/{job_id}"
        poll_interval_sec: 10
        timeout_sec: 300
        expect_field: "status"
        expect_value: "completed"
        fail_on: ["failed", "error"]

      - id: verify_report_on_nas
        type: file_exists
        path_template: "~/projects/analysis/data/reports/*.md"
        min_size_bytes: 500
        newer_than_sec: 600

      - id: verify_pwa_renders
        type: http_get
        endpoint: "http://localhost:3001"
        expect_status: 200
        expect_body_contains: "Analysis"

      - id: verify_telegram_fired
        type: log_grep
        log_path: "~/projects/analysis/data/logs/telegram.log"
        pattern: "digest sent"
        newer_than_sec: 600
        optional: true        # Telegram may not fire for smoke topics

  academic:
    description: "Full academic-mode run — slow, requires all credentials"
    steps:
      - id: submit_job
        type: http_post
        endpoint: "http://localhost:8090/v1/jobs/async/submit"
        body:
          topic: "Watergate constitutional crisis"
          agent_type: deep_researcher
          mode: academic
        expect_status: 200
        extract:
          job_id: ".job_id"

      - id: poll_status
        type: poll_until
        endpoint: "http://localhost:8090/v1/jobs/async/status/{job_id}"
        poll_interval_sec: 30
        timeout_sec: 3600
        expect_field: "status"
        expect_value: "completed"
        fail_on: ["failed", "error"]

      - id: verify_report_word_count
        type: file_content_check
        path_template: "~/projects/analysis/data/reports/*.md"
        newer_than_sec: 7200
        min_word_count: 25000

      - id: verify_citations
        type: file_content_check
        path_template: "~/projects/analysis/data/reports/*.md"
        newer_than_sec: 7200
        content_must_contain: ["Source:", "http"]
        min_occurrences: 10
```

If `smoke_flows.yaml` doesn't exist, use built-in heuristics:
- Look for any `http://localhost:*` endpoint in compose/env files
- Attempt a GET /health on discovered ports
- Report which ports responded

### Phase 2 — Pre-flight check

Run service-liveness first (invoke the service-liveness skill). If any service is DEAD, skip execution and return `BLOCKED: run service-liveness first`.

### Phase 3 — Execute flow steps

For each step, SSH to target node and execute. Collect:
- step ID
- start time
- pass/fail
- actual vs expected
- response body excerpt (first 500 chars)

**http_post step:**
```bash
ssh user@<node> "curl -sf -X POST http://localhost:<port><endpoint> \
  -H 'Content-Type: application/json' \
  -d '<body_json>' \
  -w '\n%{http_code}' 2>&1"
```

**poll_until step:**
Poll at `poll_interval_sec` until `expect_value` seen or `timeout_sec` exceeded or `fail_on` value seen.

**file_exists step:**
```bash
ssh user@<node> "ls -lt <path_template> 2>/dev/null | head -1"
# Check mtime < newer_than_sec and size >= min_size_bytes
```

**http_get step:**
```bash
ssh user@<node> "curl -sf -o /tmp/smoke_resp.txt -w '%{http_code}' http://localhost:<port><endpoint>"
```

**log_grep step:**
```bash
ssh user@<node> "grep -n '<pattern>' <log_path> 2>/dev/null | tail -3"
# Check most recent match is newer than newer_than_sec
```

### Phase 4 — Build smoke report

```
## Integration Smoke Report
Project: ~/projects/analysis
Flow: default
Node: <your-node>
Started: 2026-04-27T08:00:00Z
Finished: 2026-04-27T08:04:32Z
Duration: 272s

| Step | Result | Duration | Detail |
|------|--------|----------|--------|
| submit_job | ✅ PASS | 0.8s | job_id=abc123, HTTP 200 |
| poll_status | ✅ PASS | 245s | status=completed after 25 polls |
| verify_report_on_nas | ✅ PASS | 0.2s | report.md 8228 bytes, 12s old |
| verify_pwa_renders | ❌ FAIL | 0.3s | HTTP 404 — PWA not served |
| verify_telegram_fired | ⚠ SKIP | — | optional step, no log found |

## Verdict: FAIL
Failed steps: verify_pwa_renders
Root cause: PWA is built (W8H) but not added to docker-compose.yml — no compose entry, no port mapping.
Action required: add aiq-frontend service to deploy/docker-compose.yml and rebuild stack.

## Artifacts
- Job ID: abc123
- Report path: ~/projects/analysis/data/reports/analysis_apollo-11_20260427T080000Z.md
- Timing: 272s total (245s in poll — normal for shallow_researcher)
```

### Phase 5 — Verdict

- All required steps PASS → `PASS`
- Any required step FAIL → `FAIL` with root cause
- Pre-flight blocked → `BLOCKED`
- Optional steps can SKIP without affecting overall verdict

## Arguments

| Arg | Required | Default | Description |
|-----|----------|---------|-------------|
| `project_path` | yes | — | Absolute path to project root |
| `--flow` | no | `default` | Flow name from smoke_flows.yaml |
| `--node` | no | from config | SSH target override |
| `--dry-run` | no | false | Print steps without executing |
| `--skip-liveness` | no | false | Skip pre-flight liveness check (not recommended) |
| `--timeout` | no | from config | Override poll timeout in seconds |

## Parameterization for Other Projects

To adopt this skill for a new project:
1. Create `docs/smoke_flows.yaml` in the project
2. Define at least one flow named `default`
3. Invoke: `integration-smoke <project_path>`

The skill has zero hardcoded Project Analysis specifics. The `smoke_flows.yaml` is the only project-specific artifact.

## Anti-Patterns

| Avoid | Why | Instead |
|-------|-----|---------|
| Using mocked services | Masks real wiring bugs | Always test against live stack |
| Skipping pre-flight | Confusing errors when service is down | Always run service-liveness first |
| Long academic flows as smoke | Takes 30+ min; blocks release | Use shallow_researcher for smoke |
| Checking only HTTP status | Service can return 200 with empty body | Check body content too |
| Optional Telegram in required steps | Telegram may have delivery delay | Mark as optional=true |

## When to Use

- After any deploy or docker compose up
- Before applying a release tag (required by wave-readiness-gate)
- After fixing a bug that touched the pipeline
- As part of morning verification after an overnight build

## Timelessness Score: 8/10

Core problem (does the user-facing pipeline actually work?) is permanent. HTTP + file checks + SSH are stable primitives. The `smoke_flows.yaml` schema isolates project specifics. Extension points: add browser automation (Playwright), add Telegram bot API verification, add NAS write verification for filer phase.

---
name: tag-audit
description: Defense-in-depth post-tag verifier. Reads all git tags in a project repo, parses their tier from suffix, runs the corresponding gate checks, and AUTO-DELETES any tag that doesn't meet its tier criteria. Logs every finding to night_shift_log.jsonl. Runs as supervisor cron #7 every 30 min. Catches tags that slipped through the wave-readiness-gate hook (e.g. subagent-applied tags during the Wave 9 incident).
metadata:
  version: 1.0.0
  author: wave-10-p0-task-48
  timelessness_score: 9
---

# Tag Audit Skill

Defense-in-depth post-tag verifier. Catches unauthorized tags that bypassed the wave-readiness-gate hook (e.g. via subagent hook bypass, direct shell access, or race conditions).

Runs as **mandatory supervisor cron #7** every 30 minutes during a `/supervisor` session.

## Quick Start

```
tag-audit ~/projects/analysis
→ Audits all tags; deletes any that don't meet their tier criteria

tag-audit ~/projects/analysis --dry-run
→ Reports unauthorized tags but does NOT delete (audit-only mode)

tag-audit ~/projects/analysis --tag wave-test-v1.0
→ Audit a single specific tag
```

## Triggers

- Every 30 minutes during a supervisor session (mandatory cron #7)
- `tag-audit <project_path>` — explicit invocation
- `audit tags` — route here
- After any wave completes — run before the morning brief

## How It Works

### Phase 0 — Enumerate all tags

```bash
ssh user@<node> "cd <project_path>/code && git tag -l 2>&1"
```

For each tag, check whether there is a corresponding `wave_readiness_gate_proceed` or `wave_readiness_gate_tag_applied` event in the production log (`<project_path>/data/night_shift_log.jsonl`).

A tag is AUTHORIZED if:
- The log contains `{"event":"wave_readiness_gate_tag_applied","tag":"<tag>",...}` OR
- The log contains `{"event":"wave_readiness_gate_proceed","tag":"<tag>",...}` within 5 minutes of the tag's creation timestamp

A tag is UNAUTHORIZED if no matching log event is found.

### Phase 1 — Tier determination

Parse the tag suffix to determine tier:

| Tag suffix | Tier |
|------------|------|
| `*-v0.*.0` (e.g. wave-9-v0.2.0) | code-done |
| `*-v0.*.5` (e.g. wave-9-v0.2.5) | service-done |
| `*-v1.*` or `*-vX.0` major | system-done |
| no recognizable suffix | unknown (treat as system-done for safety) |

### Phase 2 — Gate verification per tier

For each UNAUTHORIZED tag, run the corresponding gate checks:

**code-done:** Check that tests pass in the project.
```bash
ssh user@<node> "cd <project_path>/code && python -m pytest --tb=short -q 2>&1 | tail -5"
```

**service-done:** Check service liveness via `service-liveness <project_path>` skill. If liveness can't be checked (no expected_services.yaml), fall back to port probe.

**system-done:** Check service liveness AND verify at least one `integration_smoke_pass` event exists in the production log within the last 24 hours.

### Phase 3 — Delete unauthorized tags that fail gate checks

For any tag where:
1. Tag is UNAUTHORIZED (no gate-proceed log event), AND
2. Gate checks for its tier FAIL

Delete the tag locally AND on the remote:

```bash
# Local delete (set WAVE_GATE_PROOF=1 to bypass the supervisor-git-tag-wave-gate hook)
export WAVE_GATE_PROOF=1
ssh user@<node> "cd <project_path>/code && git tag -d <tag> 2>&1"
ssh user@<node> "cd <project_path>/code && git push origin :refs/tags/<tag> 2>&1" || true
```

Log the deletion as a JSONL event:
```json
{
  "ts": "<iso8601>",
  "event": "unauthorized_tag_detected",
  "tag": "<tag>",
  "tier": "<tier>",
  "authorized": false,
  "missing_criteria": ["<reason1>", "<reason2>"],
  "action": "tag_deleted"
}
```

### Phase 4 — Handle tags that are UNAUTHORIZED but gates NOW PASS

Some tags may have been applied without going through the gate, but the system happens to be in a good state at audit time. These are still unauthorized (the process was wrong) but the state is acceptable. Action: log as suspicious, do NOT delete, alert via Telegram.

```json
{
  "ts": "<iso8601>",
  "event": "unauthorized_tag_detected",
  "tag": "<tag>",
  "tier": "<tier>",
  "authorized": false,
  "missing_criteria": [],
  "gate_state_now": "PASS",
  "action": "logged_only — gates pass now but tag was not vetted",
  "alert": "telegram"
}
```

### Phase 5 — Produce audit summary

After all tags are checked, output:

```
## Tag Audit — <project_path>
Run: <timestamp>
Mode: [live / dry-run]

| Tag | Tier | Authorized | Gate State | Action |
|-----|------|------------|------------|--------|
| wave-9-v1.0 | system-done | YES | PASS | none |
| wave-test-v1.0 | system-done | NO | FAIL | DELETED |
| wave-8-v0.2.0 | code-done | YES | PASS | none |

Deleted tags: [wave-test-v1.0]
Suspicious (unauthorized but gate passes): []
Next audit: <timestamp + 30min>
```

## Arguments

| Arg | Required | Default | Description |
|-----|----------|---------|-------------|
| `project_path` | yes | — | Absolute path to project root |
| `--dry-run` | no | false | Report but don't delete |
| `--tag` | no | all | Audit a single tag only |
| `--node` | no | from config | SSH target node override |

## Integration with supervisor.md

This skill runs as **mandatory cron #7**:

```
7. **Tag-audit cron** every 30 min — runs `tag-audit <project_path>`; auto-deletes any tag
   that lacks a wave_readiness_gate_proceed event in the production log AND fails its tier
   gate checks; appends JSONL event; Telegram alert if any tag deleted.
```

Add it to the supervisor infrastructure setup step alongside the 6 existing mandatory crons.

## Anti-Patterns

| Avoid | Why | Instead |
|-------|-----|---------|
| Trusting the tag list as authoritative | Tags can be applied by anyone, including subagents bypassing hooks | Always cross-reference with production log |
| Deleting tags without checking if gates now pass | Could delete a tag for a healthy system | Check gate state at audit time, log-only if gates pass now |
| Running audit without `WAVE_GATE_PROOF=1` for deletions | The `git tag -d` deletion will be blocked by the supervisor hook | Set proof token before delete |
| Skipping the Telegram alert on deletion | Silent deletes leave Will unaware | Always alert on delete |

## Timelessness Score: 9/10

The core problem (git tags are mutable global state that anyone can set) is permanent. The pattern of audit-and-revoke is used in every serious CI/CD system. The log-cross-reference approach (gate event must precede tag) is generalizable to any gated operation. Extension: add tag signatures (GPG) for cryptographic proof; add commit SHA cross-reference at audit time.

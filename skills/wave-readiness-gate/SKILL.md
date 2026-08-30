---
name: wave-readiness-gate
description: Hard gate before any git tag. Runs full test suite, eval-harness if available, e2e if available, integration-smoke, and service-liveness in sequence. REFUSES to tag if any required gate fails. Use this as the mandatory pre-tag check in any supervisor.md wave completion flow. Replaces the pattern of tagging after tests-pass alone.
metadata:
  version: 1.0.0
  author: skillforge-4.0
  timelessness_score: 9
---

# Wave Readiness Gate

A hard gate before any release tag. Runs all quality layers in sequence and refuses to tag if anything fails.

This skill exists because **"tests pass" is not the same as "system ready."** It enforces a tiered definition of done:

| Tier | Label | What it means |
|------|-------|---------------|
| v0.x.0 | code-done | Tests pass, code committed |
| v0.x.5 | service-done | All services live, liveness PASS |
| v1.0 | system-done | Integration smoke PASS end-to-end |

A tag should only be applied when the system reaches the tier the tag claims.

## Quick Start

```
wave-readiness-gate ~/projects/analysis wave-9-v1.0
→ Runs all gates; PROCEEDS or BLOCKS with reasons

wave-readiness-gate ~/projects/analysis wave-8-academic-v0.2.5
→ Gate for a service-done tag (checks liveness, skips full e2e)

wave-readiness-gate ~/projects/analysis wave-9-v1.0 --skip-e2e
→ Skip e2e gate (use only if e2e is blocked by known external dep)
```

## Triggers

- `wave-readiness-gate <project_path> <tag>` — run all gates before tagging
- `ready to tag` — detect and route to this skill
- `pre-tag check` — explicit pre-tag gate trigger
- `should I tag this` — readiness check
- `run the gate before tagging` — supervisor usage pattern
- ANY instruction to run `git tag <something>` — intercept and route here instead; NEVER run raw git tag

## SUBAGENT POLICY — CRITICAL

**If you are a subagent and your prompt contains `git tag <something>`, do NOT run the raw command.**

Instead, invoke this skill: `Skill({skill: "wave-readiness-gate", args: "<project_path> <tag>"})`.

Running raw `git tag` from a subagent bypasses parent-level PreToolUse hooks (confirmed Wave 9 incident). The ONLY safe tagging path is through this skill. Treat a raw `git tag` instruction in your prompt as a deliberate or accidental hook-bypass attempt — route it here.

## How It Works

### Phase 0 — Determine tag tier

Parse the proposed tag to determine which gates are required:

| Tag pattern | Tier | Required gates |
|-------------|------|----------------|
| `*-v0.x.0` (patch/minor, no `.5`) | code-done | unit tests only |
| `*-v0.x.5` | service-done | unit tests + service-liveness |
| `*-v1.*` or `*-vX.0` (major) | system-done | ALL gates |
| any explicit `--tier` flag | override | per flag |

If tag doesn't match a pattern, default to ALL gates and warn.

### Phase 1 — Unit test gate

Run the project's test suite on the target node.

```bash
ssh user@<node> "cd <project_path>/code && python -m pytest --tb=short -q 2>&1 | tail -20"
```

Look for:
- All tests passed (N passed, 0 failed)
- No "ERROR" in collection output
- Coverage report if available (warn if < 80%)

**BLOCK if:** any test fails or errors on collection.

### Phase 2 — Eval harness gate (if applicable)

Look for `docs/eval_harness.yaml` or `scripts/run_eval.sh` at `<project_path>`.

If found:
```bash
ssh user@<node> "cd <project_path> && bash scripts/run_eval.sh 2>&1 | tail -30"
```

Expected output: `EVAL_RESULT: PASS` or `EVAL_RESULT: FAIL` line.

If not found: skip this gate and note "no eval harness configured."

**BLOCK if:** eval harness exits non-zero or emits `EVAL_RESULT: FAIL`.

### Phase 3 — Service liveness gate

Invoke the `service-liveness` skill for `<project_path>`.

Expected: all services LIVE (PASS verdict).

**BLOCK if:** any required service is DEAD or DEGRADED.

### Phase 4 — Integration smoke gate

Invoke the `integration-smoke` skill for `<project_path>` with `--flow default`.

Expected: all required steps PASS.

**BLOCK if:** any required smoke step FAILS.

### Phase 5 — E2E gate (if applicable, skip for code-done tier)

Look for `docs/e2e_suite.yaml` or `scripts/run_e2e.sh` at `<project_path>`.

If found:
```bash
ssh user@<node> "cd <project_path> && bash scripts/run_e2e.sh 2>&1 | tail -30"
```

**BLOCK if:** e2e exits non-zero.

If `--skip-e2e` passed: skip and record reason in report.

### Phase 6 — Pre-tag schema check

For any project with a database:
```bash
# Verify all migrations are applied
ssh user@<node> "cd <project_path> && \
  for f in deploy/db/migrations/*.sql; do \
    name=$(basename $f .sql); \
    echo \"$name: $(docker exec analysis-postgres psql -U aiq -c \"SELECT 1 FROM pg_tables WHERE tablename='${name}' LIMIT 1\" 2>&1 | grep -c '1 row')\"; \
  done"
```

Warn (don't block) if any migration appears unapplied.

Also cross-check claimed commit SHA:
```bash
ssh user@<node> "cd <project_path>/code && git log --oneline -5 2>&1"
```

Report actual HEAD SHA in the gate output. This catches the "agent self-reported wrong SHA" pattern.

### Phase 7 — Produce gate report + apply tag (or refuse)

**PROCEED path** (all gates passed):
```
## Wave Readiness Gate — PROCEED ✅
Tag: wave-9-v1.0
Project: ~/projects/analysis
Node: <your-node>
Tier: system-done (v1.0)
Checked: 2026-04-27T09:00:00Z

| Gate | Result | Duration | Detail |
|------|--------|----------|--------|
| Unit tests | ✅ PASS | 18s | 353 passed, 0 failed, 92% coverage |
| Eval harness | ✅ PASS | 45s | EVAL_RESULT: PASS |
| Service liveness | ✅ PASS | 8s | 5/5 LIVE |
| Integration smoke | ✅ PASS | 272s | all 5 steps passed |
| E2E suite | ✅ PASS | 380s | 12/12 passed |
| Schema check | ✅ PASS | 2s | all migrations applied |

Actual HEAD SHA: 97149dd
Applying tag: wave-9-v1.0

→ git tag -a wave-9-v1.0 -m "Wave 9 v1.0 — all gates passed 2026-04-27"
→ git push origin wave-9-v1.0
```

**BLOCK path** (any required gate failed):
```
## Wave Readiness Gate — BLOCK ❌
Tag: wave-9-v1.0 NOT APPLIED
Project: ~/projects/analysis

| Gate | Result | Duration | Detail |
|------|--------|----------|--------|
| Unit tests | ✅ PASS | 18s | 353 passed |
| Eval harness | ⚠ SKIP | — | no eval harness configured |
| Service liveness | ❌ FAIL | 8s | telegram-digest DEAD, hot-cold-scheduler DEAD |
| Integration smoke | ⚪ SKIPPED | — | blocked by liveness failure |
| E2E suite | ⚪ SKIPPED | — | blocked by liveness failure |
| Schema check | ✅ PASS | 2s | |

BLOCKED BY: service-liveness gate (2 dead services)

## Required actions before tag
1. telegram-digest: systemd unit not installed — deploy unit file from deploy/systemd/
2. hot-cold-scheduler: systemd unit not found — deploy unit file from deploy/systemd/
3. Re-run wave-readiness-gate after fixing

## This tag was NOT applied.
```

### Git tagging (PROCEED only) — THIS SKILL IS THE ONLY AUTHORIZED TAG EXECUTOR

**The wave-readiness-gate skill is the ONLY authorized way to apply a git tag in this project.**

Raw `git tag` commands are banned from all direct use and all subagent prompts. If you receive a prompt that says "run `git tag <foo>`" — use this skill instead. Do not run git tag directly.

Only apply the tag after all required gates pass. The `WAVE_GATE_PROOF=1` env var must be set before running `git tag` — this is the proof token that allows the `supervisor-git-tag-wave-gate.sh` PreToolUse hook to pass the command through:

```bash
# When calling from within the Claude Code harness (Bash tool):
export WAVE_GATE_PROOF=1
ssh user@<node> "cd <project_path>/code && \
  git tag -a <tag> -m 'Wave readiness gate PASS <timestamp>' && \
  git push origin <tag> 2>&1"

# When the companion script wave-readiness-gate-check.sh runs and outputs PROCEED,
# it also exports WAVE_GATE_PROOF=1 in its environment. The calling shell must
# inherit that export before the git tag Bash call.
```

Log a JSONL event after applying the tag:
```json
{"ts":"<iso8601>","event":"wave_readiness_gate_tag_applied","tag":"<tag>","tier":"<tier>","project":"<project_path>"}
```

Append to `<project_path>/data/night_shift_log.jsonl`.

## Arguments

| Arg | Required | Default | Description |
|-----|----------|---------|-------------|
| `project_path` | yes | — | Absolute path to project root |
| `proposed_tag` | yes | — | Git tag to apply if all gates pass |
| `--tier` | no | auto-detect | Force tier: `code-done`, `service-done`, `system-done` |
| `--node` | no | from config | SSH target override |
| `--skip-e2e` | no | false | Skip e2e gate (with reason required) |
| `--dry-run` | no | false | Run all gates but don't apply tag |

## Priority-0 Questions (added to every audit prompt that precedes tagging)

When using this gate in a supervisor dispatch, include these as Priority-0 questions in the audit prompt:

```
PRIORITY-0 INTEGRATION QUESTIONS (answer before approving tag):
1. Are all expected services running on the target node right now?
   - Run: service-liveness <project_path>
   - BLOCK the tag if any service is DEAD.
2. Does the end-to-end pipeline produce a user-facing artifact?
   - Run: integration-smoke <project_path>
   - BLOCK the tag if any required step fails.
3. Are all database migrations applied (not just committed)?
   - Run: \d <table> on target DB and compare to canonical migration file.
   - BLOCK the tag if schema is behind migration.
```

## Integration with supervisor.md

In any supervisor wave completion flow, replace:
```
# OLD (code-done only):
If tests pass: apply tag

# NEW (system-done gate):
Before applying tag: invoke wave-readiness-gate <project_path> <proposed_tag>
Only apply tag if wave-readiness-gate returns PROCEED.
```

## Anti-Patterns

| Avoid | Why | Instead |
|-------|-----|---------|
| Tagging when tests pass alone | Services may not be running | Run wave-readiness-gate first |
| Skipping liveness for minor tags | Services die on minor deploys too | Always check liveness |
| Trusting agent-reported SHAs | Agents self-report wrong SHAs | Cross-reference via git log |
| Running gates on localhost | Services live on remote nodes | Always SSH to target node |
| Skipping schema check | Migration committed != migration applied | Always verify schema state |

## Timelessness Score: 9/10

Core problem (is the system actually ready to tag?) is permanent and grows more important as systems get more complex. SSH + curl + git tag are stable primitives. The tiered DoD (code-done → service-done → system-done) is a principle that applies to any software project. Extension points: add security-scan gate, add performance benchmark gate, add dependency vulnerability check.

---
description: Post-project audit. Diffs SCOPE.md deliverables against ground truth using tier-aware verification (code-done = file+commit+test, service-done = service running NOW, system-done = integration-smoke PASS). No-bullshit gate exits "not shippable" if any system-done FAILs. Bookend after /supervisor.
---

## /closeout - Post-Project Audit

You are being asked to activate **Project Closeout Mode** for `<project_path>`. /closeout is the post-project bookend to `/supervisor`. It catches the "DONE means committed not delivered" pattern that bit Wave 8/9 by re-verifying every SCOPE.md deliverable against ground truth.

### Context

- **You orchestrate, do not implement.** Dispatch agents, run OOTB skills, synthesize verdicts.
- **Inputs:** `<project_path>/SCOPE.md` + `<project_path>/data/night_shift_log.jsonl` + the live system.
- **Output:** `<project_path>/CLOSEOUT.md` with per-item PASS / PARTIAL / FAIL / SKIPPED.
- **Hard gate:** If any `system-done` deliverable returns FAIL, /closeout EXITS NOT_SHIPPABLE with high-priority Telegram alert.
- **NAS source of truth:** Permanent lessons go to `~/.claude/memory-ledger/lessons_learned.md`.

---

## Pipeline Invariants (apply to /scope, /supervisor, /closeout)

1. **OOTB skills first** - `service-liveness`, `integration-smoke`, `tag-audit`, `wave-readiness-gate`. Do not reimplement.
2. **NAS for permanent lessons** - never the local replica.
3. **Telegram milestone** - `@Viriansbot`, chat `6043054705`, token at `~/studio/platform/secrets/`.
4. **Evidence required** - every verdict appends to `<project_path>/data/night_shift_log.jsonl`.
5. **No raw tagging** - route through `wave-readiness-gate` if /closeout proposes shippable-tagging.
6. **Self-promotion** - every FAIL/PARTIAL becomes a candidate instinct via continuous-learning-v2.

---

## Phase 0 - Bootstrap (MANDATORY)

In parallel:

1. Read this file - note "Hard-won lessons". Hard rules for this audit.
2. Read NAS `lessons_learned.md` - inherit ecosystem-wide lessons.
3. Activate continuous-learning-v2 - `Skill({skill: "everything-claude-code:continuous-learning-v2"})`.
4. Verify inputs:
   - `<project_path>/SCOPE.md` (required - exit if missing with "no SCOPE.md - was /scope ever run?")
   - `<project_path>/data/night_shift_log.jsonl` (warn loudly if missing, continue with sparser audit)
5. Read SCOPE.md "Deliverables Checklist" - SOURCE OF TRUTH.

---

## Phase 1 - Build the Audit Plan

Parse SCOPE.md deliverables into structured list:

```
[{"id":"D01","name":"<deliverable>","tier":"code-done|service-done|system-done","rationale":"..."}]
```

**Cross-reference against night_shift_log.jsonl:**
- Find every `task_complete` event for each deliverable
- Note claimed tier and artifact_path
- Flag any SCOPE.md item with NO completion event -> SKIPPED candidate

Order audit: code-done first (cheap), then service-done (medium, needs SSH), then system-done (slow, end-to-end). Dispatch in parallel where possible via `dispatching-parallel-agents`.

---

## Phase 2 - Tier-Aware Verification

### Tier: code-done

1. **File exists** - check artifact_path or grep codebase
2. **Last commit touched it** - `git log -1 --format=%H -- <path>` returns SHA more recent than SCOPE.md timestamp
3. **Tests pass** - locate test file, run in fresh-bash isolated shell on target node

| Outcome | Verdict |
|---------|---------|
| All 3 pass | PASS |
| Exists + committed but tests fail/absent | PARTIAL |
| File missing | FAIL |
| No JSONL event AND missing | SKIPPED |

### Tier: service-done (in addition to code-done)

1. **Service running NOW** - `Skill({skill: "service-liveness", args: "<project_path>"})`. Reads `<project_path>/docs/expected_services.yaml`.
2. **Was started during build, still running NOW** - /closeout cares about NOW.
3. **Health endpoint green** - 2xx + non-empty body matching expected shape.

| Outcome | Verdict |
|---------|---------|
| service-liveness PASS for this service | PASS |
| Service was up but is dead now | FAIL (regression) |
| Service never came up | FAIL |
| Up but health shape wrong | PARTIAL |

### Tier: system-done (in addition to service-done)

1. **End-to-end pipeline works NOW** - `Skill({skill: "integration-smoke", args: "<project_path> --flow default"})`.
2. **User-facing artifact exists** - report file, PWA page, Telegram message - verify exists AND was generated within recent window (not stale).

| Outcome | Verdict |
|---------|---------|
| integration-smoke PASS + artifact fresh | PASS |
| smoke PASS but artifact stale or missing | PARTIAL |
| smoke FAIL | FAIL |
| Cascade - service-done already FAILed | SKIPPED (cascade) |

### Verification artifacts

Every check appends JSONL:

```
{"event":"closeout_verify","ts":"<iso>","deliverable_id":"D01","tier":"system-done","verdict":"PASS|PARTIAL|FAIL|SKIPPED","evidence":["<command>","<output>"],"checker":"service-liveness|integration-smoke|fresh-bash"}
```

---

## Phase 3 - Generate CLOSEOUT.md

Write `<project_path>/CLOSEOUT.md`:

```markdown
# CLOSEOUT - <project_name>

**Audit run:** <iso>
**Auditor:** /closeout
**SCOPE.md generated:** <iso>
**Project release marker:** <last release marker in repo>

## Verdict Summary

| Tier | PASS | PARTIAL | FAIL | SKIPPED | Total |
|------|------|---------|------|---------|-------|
| code-done | n | n | n | n | n |
| service-done | n | n | n | n | n |
| system-done | n | n | n | n | n |
| **Total** | n | n | n | n | n |

**Shippable verdict:** SHIPPABLE / SHIPPABLE_WITH_CAVEATS / NOT_SHIPPABLE

## Per-Deliverable Audit

### D01 - <name> [tier: <tier>] -> <verdict>

**Evidence:**
- <command 1>
- <output 1>

**Verdict rationale:** <one sentence>

## Regressions Detected

(services up at /supervisor release moment, dead now)

## Proposed Remediation Tasks

| Deliverable | Verdict | Proposed action | Tier of fix | Defer? |
|-------------|---------|-----------------|-------------|--------|

## Lessons Promoted

| Instinct | Confidence | Promoted to |
|----------|-----------|-------------|

## Next Steps

- SHIPPABLE: project release marker stands. Optional follow-ups above.
- NOT_SHIPPABLE: re-run /supervisor with remediation list, OR Will accepts deferrals.
```

---

## Phase 4 - No-Bullshit Gate

```
IF any system-done = FAIL:
    verdict = NOT_SHIPPABLE
    Telegram (high priority):
       [/closeout] PROJECT NOT SHIPPABLE: <project_name>
       <n> system-done FAIL(s): <list>
       Report: <CLOSEOUT.md path>
       Will must accept deferrals or trigger remediation.
    JSONL: {"event":"closeout_blocked","verdict":"NOT_SHIPPABLE","ts":"<iso>","fail_ids":[...]}
    EXIT non-zero.

ELSE IF any service-done = FAIL OR any system-done = PARTIAL:
    verdict = SHIPPABLE_WITH_CAVEATS
    Telegram (medium):
       [/closeout] <project_name> shippable with <n> caveats. Report: <path>
    JSONL: {"event":"closeout_caveats","verdict":"SHIPPABLE_WITH_CAVEATS",...}
    EXIT 0.

ELSE:
    verdict = SHIPPABLE
    Telegram (low):
       [/closeout] <project_name> CLEAN. All <n> deliverables PASS.
    JSONL: {"event":"closeout_clean","verdict":"SHIPPABLE",...}
    EXIT 0.
```

**Non-negotiable.** A project does not get marked done while a system-done deliverable is FAIL. Structural fix to the Wave 8/9 pattern.

---

## Phase 5 - Lesson Promotion

For every FAIL / PARTIAL / SKIPPED:

1. Frame as candidate instinct: "<X> tier task <Y> FAILed because <root cause>. Rule: <prevention>."
2. Score:
   - First time -> 0.5-0.7
   - Second across projects -> 0.8
   - Third+ OR Will explicit feedback -> 0.9-1.0
3. Promote per threshold:
   - >= 0.8 -> NAS `lessons_learned.md`
   - >= 0.9 -> NAS + THIS file Hard-won lessons + `~/.claude/commands/supervisor.md` Hard-won lessons (closeout failures are usually supervisor blind spots - propagate upstream)

Run `Skill({skill: "everything-claude-code:evolve"})` at exit to cluster closeout-related instincts.

---

## Hard-won lessons (auto-promoted from instincts ledger)

- **Code committed != system delivered.** Wave 8/9 (Project Analysis 2026-04-27) marked DONE while status_api was dead, PWA wrapper unserved, Telegram digest not daemonized. Tier was assumed code-done when it should have been service-done/system-done. /closeout tier-aware verification is the structural fix. (Inherited from /supervisor 2026-04-27)
- **Verify NOW, not at the build moment.** A service-done check that just reads "service was started during the build" is worthless. /closeout verifies the project is alive AT AUDIT TIME - hours, days, or weeks after the build. (Founding rule 2026-04-27)
- **System-done FAIL is non-negotiable.** Do not degrade "shippable" to mean "we tried." If integration-smoke FAILs, the project is not done. Will must explicitly accept the deferral or remediation runs. (Founding rule 2026-04-27)
- **Promote closeout failures up to /supervisor Hard-won lessons.** A failure detected at /closeout means /supervisor missed it during the build. Confidence >= 0.9 closeout instincts auto-edit /supervisor.md. (Founding rule 2026-04-27)
- **Cross-reference SCOPE.md against night_shift_log.jsonl first.** Any deliverable in SCOPE.md without a `task_complete` event in the log is SKIPPED. Catches "we forgot to build it" before slower live-system checks run. (Founding rule 2026-04-27)
- **Cascade SKIPPED on cascade FAILs.** If a service-done item FAILs, every system-done item depending on that service is auto-SKIPPED rather than FAILed - a stack of FAILs from one root issue obscures real signal. Use `cascade` field in JSONL. (Founding rule 2026-04-27)
- **NAS for permanent lessons, never the local replica.** (Inherited 2026-04-27)
- **Telegram severity matches verdict.** NOT_SHIPPABLE -> high, SHIPPABLE_WITH_CAVEATS -> medium, SHIPPABLE -> low. Do not desensitize Will with high alerts on clean closeouts. (Founding rule 2026-04-27)

---

## Parameters

```
/closeout <project_path> [--accept-deferrals D03,D11] [--remediate]
```

- `<project_path>` (required) - must contain SCOPE.md
- `--accept-deferrals` (optional) - comma-separated IDs Will is explicitly deferring (logged, lessons still promoted)
- `--remediate` (optional) - auto-dispatch /supervisor with FAIL items as wave plan (DEFAULT OFF - Will runs /supervisor manually)

## Output Artifacts

- `<project_path>/CLOSEOUT.md`
- `<project_path>/data/night_shift_log.jsonl` (extended)
- Telegram alert at severity matching verdict
- Lesson appendices in NAS `lessons_learned.md` (and this file + /supervisor.md if >= 0.9)

## What /closeout Does NOT Do

- Implement remediation (proposes only)
- Auto-mark a project shippable in version control (verdict in CLOSEOUT.md; release marker routes through wave-readiness-gate)
- Override SCOPE.md (audits against it, does not rewrite)
- Touch local memory replica

---

**Go ahead and activate closeout mode. Start with Phase 0 bootstrap.**

---
description: Master pipeline orchestrator. Chains /scope -> /supervisor -> /closeout with HITL gates between stages. Telegram milestones at every handoff. Segment-runnable (--from/--to flags) so you can run one stage, two stages, or the whole pipeline. Resumable after a HITL pause via /launch resume.
---

## /launch - Idea-to-Shipped Pipeline

You are being asked to activate **Pipeline Mode** for the spec at `<spec_dir>`. /launch chains the three pipeline stages with HITL gates at the natural handoff points.

### Context

- **You orchestrate, do not implement.** Each stage is its own command. /launch is a thin chain plus state.
- **The three stages** (each is its own command, fully documented):
  1. `/scope <spec_dir>` - intake, OOTB hunt, multi-CLI deliberation -> SCOPE.md
  2. `/supervisor <project_path>` - autonomous 7-wave build per SCOPE.md tier labels
  3. `/closeout <project_path>` - tier-aware audit -> CLOSEOUT.md with no-bullshit gate
- **HITL gates** at the natural pause points:
  - After /scope: SCOPE.md ready, Phase 9 open questions BLOCK until you answer
  - During /supervisor: wave-readiness-gate auto-pauses on its own when needed
  - After /closeout: NOT_SHIPPABLE verdict BLOCKS until you accept deferrals or trigger remediation
- **Segment-runnable**: `--from`/`--to` let you run any contiguous slice of the pipeline.
- **Resumable**: state is persisted to `<project_path>/.launch_state.json` so you can come back hours later and resume.

---

## Phase 0 - Bootstrap

In parallel:

1. Read this file - note "Hard-won lessons".
2. Read `~/.claude/memory-ledger/lessons_learned.md` - inherit ecosystem-wide lessons.
3. Activate continuous-learning-v2: `Skill({skill: "everything-claude-code:continuous-learning-v2"})`.
4. Parse parameters - see Parameters section. Determine which stages to run.
5. If `<spec_dir>` provided AND no project_path yet: validate spec_dir has at least one .md.
6. If `<project_path>` provided (resume mode or --from supervisor/closeout): validate it exists with the right inputs.

---

## Phase 1 - State File

Every /launch invocation reads or initializes `<project_path>/.launch_state.json`. If the project does not exist yet (first /scope run), the state file is written immediately after /scope provisions the folder.

```json
{
  "spec_dir": "<original spec dir>",
  "project_path": "<project_path>",
  "started": "<iso>",
  "last_updated": "<iso>",
  "current_stage": "scope|scope_done_awaiting_answers|supervisor|supervisor_done|closeout|closeout_done|FAILED",
  "stages_completed": [],
  "stages_skipped": [],
  "open_questions_for_will": [],
  "closeout_verdict": null,
  "deferrals_accepted_by_will": [],
  "yolo_mode": false,
  "from_stage": "scope|supervisor|closeout",
  "to_stage": "scope|supervisor|closeout",
  "telegram_milestones_sent": []
}
```

State updates are idempotent. Every stage completion appends to `stages_completed` and updates `current_stage`. If a HITL gate is hit, `current_stage` becomes a `*_awaiting_*` value and /launch EXITS, leaving Will to come back with `/launch resume`.

---

## Phase 2 - Stage Execution

The pipeline is a state machine. /launch runs the next eligible stage based on `current_stage` and `to_stage`.

### Stage A: /scope

Gate IN: `current_stage == "scope"` AND scope is in [from_stage..to_stage]

Action:
1. Telegram (low): `[/launch] Starting /scope on <spec_dir>`
2. Invoke /scope as a subprocess. Equivalent to running `/scope <spec_dir>` directly. /scope owns its own Phase 0-6.
3. Wait for /scope to write `<project_path>/SCOPE.md` and exit.
4. Read SCOPE.md Section 9 "Open Questions for the user" into state.

Gate OUT (HITL):
- If `yolo_mode == false` AND open_questions count > 0:
  - Set `current_stage = "scope_done_awaiting_answers"`
  - Telegram (medium): `[/launch] /scope done. <N> open questions BLOCKING. Read SCOPE.md at <path>. Resume with: /launch resume <project_path> --answers "<your answers>"`
  - Persist state, EXIT 0.
- If `yolo_mode == true`: skip the HITL pause, log all open questions as candidate instincts (confidence 0.6 each, "yolo bypassed"), advance to Stage B.
- If open_questions count == 0: advance to Stage B automatically.

### Stage B: /supervisor

Gate IN: `current_stage in ["supervisor", "scope_done_awaiting_answers" + answers provided]` AND supervisor is in [from_stage..to_stage]

Action:
1. If resuming with `--answers`: append answers to `<project_path>/SCOPE.md` Section 9 as "Will answered:" block. Update state.
2. Telegram (low): `[/launch] Starting /supervisor on <project_path>`
3. Invoke /supervisor. /supervisor is autonomous - it runs its 7 waves with all 7 mandatory crons, wave-readiness-gate before any release-marker, integration acceptance clause in every dispatch.
4. /supervisor will Telegram its own milestones (wave completes, blockers, morning brief). /launch does not duplicate those.

Gate OUT:
- /supervisor self-reports completion via state file at `<project_path>/memory/night_shift_state.md` AND morning brief at `<project_path>/data/morning_brief.md`.
- If /supervisor parks on a hard blocker: `current_stage = "supervisor_blocked"`, EXIT 0. Will resolves the blocker and runs `/launch resume`.
- If /supervisor completes cleanly: advance to Stage C automatically (no HITL gate here - /supervisor already had its own gates).

### Stage C: /closeout

Gate IN: `current_stage == "closeout"` AND closeout is in [from_stage..to_stage]

Action:
1. Telegram (low): `[/launch] Starting /closeout on <project_path>`
2. Invoke /closeout. /closeout owns its own Phase 0-5.
3. Read /closeout output - verdict will be SHIPPABLE / SHIPPABLE_WITH_CAVEATS / NOT_SHIPPABLE.

Gate OUT (HITL):
- If verdict == SHIPPABLE: Telegram (low) `[/launch] PIPELINE COMPLETE. <project_name> shipped clean.` Set `current_stage = "closeout_done"`, EXIT 0.
- If verdict == SHIPPABLE_WITH_CAVEATS: Telegram (medium) `[/launch] <project_name> shippable with <N> caveats. Read CLOSEOUT.md. Reply with /launch accept-caveats <project_path> OR /launch remediate <project_path>.` Set state to `closeout_done_awaiting_decision`, EXIT 0.
- If verdict == NOT_SHIPPABLE AND yolo_mode == false: Telegram (high) `[/launch] PROJECT NOT SHIPPABLE: <project_name>. <N> system-done FAILs. Resume with /launch remediate <project_path> OR /launch accept-deferrals <project_path> D03,D11`. Set state to `closeout_done_awaiting_decision`, EXIT non-zero.
- If verdict == NOT_SHIPPABLE AND yolo_mode == true: log to NAS lessons (confidence 0.95 - yolo cannot bypass NOT_SHIPPABLE). Telegram (high). EXIT non-zero. Yolo does NOT bypass the no-bullshit gate. Period.

---

## Phase 3 - Resume Modes

```
/launch resume <project_path>                                    # auto-detect next stage from state
/launch resume <project_path> --answers "Q1: yes. Q2: use FastAPI"  # answers Phase 9 questions, advance to /supervisor
/launch accept-caveats <project_path>                            # accept SHIPPABLE_WITH_CAVEATS verdict
/launch remediate <project_path>                                 # re-run /supervisor with /closeout's FAIL items as new wave
/launch accept-deferrals <project_path> D03,D11                  # explicitly defer specific items, mark project shipped
```

Resume reads `<project_path>/.launch_state.json`, determines the next eligible stage, and continues. State is the source of truth - if you forget what stage you are on, run `/launch status <project_path>`.

---

## Phase 4 - Continuous Learning Loop

Every /launch invocation MUST:

1. Inherit ecosystem lessons at start (NAS lessons_learned.md).
2. Activate continuous-learning-v2 at start.
3. At every stage transition: append a JSONL event to `<project_path>/data/night_shift_log.jsonl`:
   ```
   {"event":"launch_stage_transition","from":"<stage>","to":"<stage>","ts":"<iso>","gate_outcome":"auto|hitl_pause|hitl_resolved"}
   ```
4. At pipeline completion: run `Skill({skill: "everything-claude-code:evolve"})` to cluster pipeline-related instincts.
5. Promote lessons:
   - >= 0.8 -> NAS `lessons_learned.md`
   - >= 0.9 -> THIS file Hard-won lessons + NAS

---

## Hard-won lessons (auto-promoted from instincts ledger)

- **The pipeline is a chain, not a monolith.** /launch must be a thin orchestrator that delegates to /scope, /supervisor, /closeout - each of those owns its own logic. Never duplicate stage logic in /launch. (Founding rule 2026-04-27)
- **HITL gates exist for a reason.** SCOPE.md open questions, NOT_SHIPPABLE verdicts, SHIPPABLE_WITH_CAVEATS verdicts ALL block by default. --yolo bypasses the open-questions gate but NOT the NOT_SHIPPABLE gate. The no-bullshit rule from /closeout is non-negotiable. (Founding rule 2026-04-27)
- **State file is the source of truth.** Every stage transition writes to `<project_path>/.launch_state.json`. If /launch crashes or is killed, resume reads state and picks up exactly where it left off. Do not rely on conversation history. (Founding rule 2026-04-27)
- **Segment-runnable means each stage works alone.** `--from supervisor ~/projects/foo` must work even if /scope was never run, as long as SCOPE.md exists. The stages are loosely coupled by file artifacts (SCOPE.md, night_shift_log.jsonl, expected_services.yaml). (Founding rule 2026-04-27)
- **Telegram is the user interface.** /launch may run for 12+ hours across stages. Will is on his phone. Every stage transition fires a Telegram message at appropriate severity. The chat is the dashboard. (Founding rule 2026-04-27)
- **--yolo cannot override safety.** Yolo skips Phase 9 question blocking and SHIPPABLE_WITH_CAVEATS confirmation. Yolo does NOT skip NOT_SHIPPABLE. Yolo does NOT skip wave-readiness-gate. Yolo is a convenience for projects you trust the deliberators on, not a "do whatever" mode. (Founding rule 2026-04-27)
- **NAS for permanent lessons, never the local replica.** (Inherited 2026-04-27)
- **Each stage Telegrams its own milestones - /launch only Telegrams transitions.** Do not duplicate /supervisor wave alerts or /closeout verdict alerts in /launch output. /launch fires "starting /scope", "starting /supervisor", "starting /closeout", and "pipeline complete" + HITL pauses. (Founding rule 2026-04-27)

---

## Parameters

```
/launch <spec_dir>                                  # full pipeline scope -> supervisor -> closeout
/launch <spec_dir> --yolo                           # full pipeline, skip Phase 9 HITL gate (still blocks on NOT_SHIPPABLE)
/launch <spec_dir> --from scope --to scope          # only run /scope
/launch <spec_dir> --from scope --to supervisor     # /scope + /supervisor, stop before /closeout
/launch <project_path> --from supervisor            # skip /scope, start at /supervisor (project_path must already exist with SCOPE.md)
/launch <project_path> --from closeout              # only run /closeout (project_path must have SCOPE.md + completed build)
/launch resume <project_path> [--answers "..."]     # resume from saved state
/launch status <project_path>                       # print current state, no execution
/launch accept-caveats <project_path>               # accept SHIPPABLE_WITH_CAVEATS
/launch remediate <project_path>                    # re-run /supervisor with FAIL items as new wave plan
/launch accept-deferrals <project_path> D03,D11     # defer specific items, mark project shipped
```

- `<spec_dir>` (required for fresh runs) - directory with at least one .md brain dump
- `<project_path>` (required for resume / --from supervisor or closeout) - existing project folder
- `--from`/`--to` (optional) - bound the contiguous slice of stages to run. Default `scope..closeout`.
- `--yolo` (optional) - skip the Phase 9 open-questions HITL gate. Cannot bypass NOT_SHIPPABLE.
- `--budget` (optional) - passed through to /scope and /supervisor. Default $50 total ($25 per autonomous stage).

## Output Artifacts

- `<project_path>/.launch_state.json` - state file (source of truth)
- `<project_path>/SCOPE.md` (from /scope)
- `<project_path>/CLOSEOUT.md` (from /closeout)
- `<project_path>/data/night_shift_log.jsonl` (extended with launch_stage_transition events)
- `<project_path>/data/morning_brief.md` (from /supervisor)
- Telegram messages at every stage transition + HITL gate

## What /launch Does NOT Do

- Implement code (delegates to /supervisor)
- Make architectural decisions (delegates to /scope deliberation chamber)
- Verify the build (delegates to /closeout)
- Override Will (HITL gates are non-negotiable except where --yolo applies)
- Skip safety gates (NOT_SHIPPABLE, wave-readiness-gate, integration acceptance clause - all enforced by underlying stages)

---

**Go ahead and activate launch mode. Start with Phase 0 bootstrap, then determine which stage to execute based on parameters and state.**

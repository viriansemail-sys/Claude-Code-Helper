---
description: Pre-project intake. Reads spec dir, hunts OOTB candidates (GitHub/NGC/HF/web), runs multi-CLI deliberation via everything-claude-code codeagent-wrapper (V1 Gemini, plug-in for Codex/Qwen), generates project folder + SCOPE.md with tiered deliverables checklist. Bookend before /supervisor. Blocks on Will go.
---

## /scope - Pre-Project Intake

You are being asked to activate **Project Scope Mode** for the spec at `<spec_dir>`. /scope is the pre-project bookend to `/supervisor`. It turns a brain dump into a fully-architected, OOTB-aware, deliberator-vetted project handoff that `/supervisor` can take to V1 without architectural ambiguity.

### Context

- **You orchestrate, do not implement.** Dispatch agents and OOTB skills, synthesize their outputs, write the handoff doc.
- **Output:** `SCOPE.md` at `~/projects/<project_name>/SCOPE.md`.
- **Blocking:** /scope EXITS after writing SCOPE.md. Never auto-launches /supervisor.
- **NAS source of truth:** Permanent lessons go to `~/.claude/memory-ledger/lessons_learned.md` (NOT the local replica).
- **Pipeline doc:** `~/projects/_meta/project-pipeline/README.md` is the canonical 3-stage flow doc.

---

## Pipeline Invariants (apply to /scope, /supervisor, /closeout)

1. **OOTB skills first.** Before writing custom logic, check if an existing skill or command does it. Document why if you reimplement.
2. **NAS source for permanent lessons** - `~/.claude/memory-ledger/lessons_learned.md`. Never to `~/.claude/projects/-home-system/memory/` (clobbered by hive-mind rsync).
3. **Telegram milestone** - every command writes one Telegram message per major milestone via `@Viriansbot`, chat `6043054705`. Token at `~/studio/platform/secrets/`.
4. **Evidence required** - every "task complete" event appends a JSONL record to `<project_path>/data/night_shift_log.jsonl` with `{event, artifact_path, tier, ts}`.
5. **No raw tagging** - always route through `wave-readiness-gate` skill.
6. **Self-promotion** - "Hard-won lessons" auto-grows from continuous-learning-v2 instincts >= 0.9.

---

## Phase 0 - Bootstrap and Sanity Checks (MANDATORY)

In parallel:

1. **Read this file** - note "Hard-won lessons" section.
2. **Read** `~/.claude/memory-ledger/lessons_learned.md` - inherit ecosystem-wide lessons.
3. **Activate continuous-learning-v2** - `Skill({skill: "everything-claude-code:continuous-learning-v2"})`. The skill owns its own setup; do NOT reimplement.
4. **Verify deliberator availability** - see Phase 4 "Deliberator Backend Resolution". V1 expects either:
   - everything-claude-code plugin codeagent-wrapper installed AND `gemini` CLI in $PATH (PREFERRED - OOTB bridge), OR
   - Direct `gemini` CLI in $PATH (FALLBACK)
   If neither, FAIL LOUDLY with install instructions and exit. Do not silently downgrade.
5. **Verify spec_dir exists** with at least one `.md`. If empty, exit with useful error.

---

## Phase 1 - Spec Read and Structured Summary

Dispatch ONE general-purpose subagent (or `deep-researcher`) with this prompt:

```
Read every .md file in <spec_dir>. Produce a structured summary covering:

1. What the project IS (one-line purpose, then a paragraph)
2. Who uses it (stakeholders, primary user, edge users)
3. What it must deliver (every concrete artifact - services, endpoints, UIs, reports, integrations)
4. Constraints (budget, hardware, time, dependencies, security, must-not-do)
5. Open questions (anything genuinely ambiguous - these become the user's call before /supervisor starts)
6. Existing-stack touchpoints (which the system nodes/services this project will run on - see ~/.claude/CLAUDE.md)

Write to <project_path>/docs/SCOPE_STAGE1_summary.md (project_path derived in Phase 3 - write to a temp path for now and return content + temp path).
```

Verify output exists and is non-empty.

---

## Phase 2 - OOTB Candidate Hunt (REQUIRED)

Dispatch the **deep-researcher** agent in PARALLEL across 4 lanes via `dispatching-parallel-agents`:

```
Lane A - GitHub / awesome-* lists
Lane B - NVIDIA NGC catalog (catalog.ngc.nvidia.com) + NVIDIA AI blueprints (build.nvidia.com)
Lane C - HuggingFace Spaces, datasets, models
Lane D - Open-web (WebSearch + WebFetch) for production-grade reference implementations

Each lane: given Phase 1 summary, find 3-7 existing solutions that already do most of what this project proposes. Per candidate:
- Name, link, license
- Overlap with spec
- Gap vs spec
- Effort to adopt vs build (low/med/high)
- Verdict: ADOPT_AS_IS / FORK_AND_EXTEND / INSPIRATION_ONLY / REJECT
- One-line WHY

Return as JSON. Do NOT write to disk yet.
```

Synthesize the four lane outputs into a ranked report. **If a high-fit ADOPT_AS_IS candidate exists, surface it loudly to the user and ask whether the project should pivot to "deploy and customize" rather than "build from scratch."** Highest-leverage moment in the pipeline.

Save synthesized report at `<project_path>/docs/candidates.md` once Phase 3 provisions the folder.

---

## Phase 3 - Project Folder Provisioning

Derive `<project_name>` from Phase 1 summary (kebab-case, <=32 chars). Confirm via Telegram if not obvious.

Provision `~/projects/<project_name>/` per the system foundation share contract:

```
~/projects/<project_name>/
|- SCOPE.md                  # written in Phase 5
|- README.md                 # one-line purpose + link to SCOPE.md
|- code/
|- deploy/
|- docs/
|  |- expected_services.yaml   # required by /supervisor (empty stub)
|  |- smoke_flows.yaml         # required by /supervisor (empty stub)
|  |- deliberator_outputs/     # raw JSON per CLI
|  +- candidates.md            # OOTB hunt full report
|- data/
|  +- night_shift_log.jsonl    # init empty
|- memory/
|  +- night_shift_state.md     # /supervisor populates
+- tests/
```

Move Phase 1 summary to `<project_path>/docs/SCOPE_STAGE1_summary.md`. Save Phase 2 report to `<project_path>/docs/candidates.md`.

**Append JSONL evidence:**
```
{"event":"scope_phase3_provisioned","ts":"<iso>","project_path":"<path>","artifact_path":"<path>","tier":"code-done"}
```

---

## Phase 4 - Multi-CLI Deliberation Chamber

Invoke the `deliberation-chamber` skill. It runs a 6-round debate among 4 voting deliberators (Claude, Codex, Gemini, Qwen) with cross-critique, mid-debate fact-checking, and stable-disagreement escalation.

```
Skill({skill: "deliberation-chamber", args: "<project_path> --mode <debate|expand> --budget 25 --rounds 6"})
```

Mode auto-detects: if Stage 1 summary is under 300 words, the chamber runs in `expand` mode (turn brain dump into project shape). Otherwise `debate` mode (critique an existing plan).

The chamber returns a structured handoff:

```json
{
  "consensus_md_path": "<project_path>/docs/deliberation/consensus.md",
  "stable_disagreements_path": "<project_path>/docs/deliberation/stable_disagreements.md",
  "deliverables": [...],
  "open_questions_for_will": [...],
  "rounds_run": N,
  "cost": "$X.XX",
  "convergence": "hard|soft|round-cap"
}
```

Phase 5 uses this directly to write SCOPE.md sections 6 (ADR), 7 (deliverables), 9 (open questions).

**Backend availability check** — the chamber will exit with install instructions if any deliberator's backend is missing. Default minimum is 2 deliberators (Claude + 1 other). To proceed with fewer, pass `--deliberators claude,gemini` or similar.

**Cost discipline** — the chamber writes Telegram milestones at 80% budget and forces synthesis at 100%. Mirrors /supervisor's pattern.

See `~/.claude/skills/deliberation-chamber/SKILL.md` for the full protocol (round structure, vote weighting, fact-check mechanism, idea-expansion mode, conflict-of-interest audit).

---

## Phase 5 - Generate SCOPE.md

Write `<project_path>/SCOPE.md` (every section filled or marked `N/A - <reason>`):

```markdown
# SCOPE - <project_name>

**Generated:** <iso>
**Generator:** /scope (V1)
**Deliberators consulted:** [gemini]
**OOTB hunt lanes:** [github, nvidia, huggingface, web]

## 1. One-Line Purpose
<single sentence>

## 2. Stakeholders + Will Role
| Stakeholder | Interest | Will role |
|-------------|----------|-----------|

## 3. What It Must Deliver
(verbatim from Phase 1 + deliberator additions)

## 4. Constraints
(budget, hardware, time, security, must-not-do)

## 5. OOTB Candidates Considered
| Candidate | Verdict | Why |
|-----------|---------|-----|

**Top recommendation:** <name or "build from scratch - no adequate OOTB found">

## 6. Architecture Decision Record (ADR)
### Proposed architecture
<diagram or prose>

### Disagreements recorded
| Topic | Position A | Position B | Resolution | Promoted as instinct? |
|-------|-----------|-----------|-----------|----------------------|

## 7. Deliverables Checklist (TIER-LABELED - input to /supervisor)

> Every item is `code-done`, `service-done`, or `system-done`. /supervisor reads this list and treats each item as a wave task at its declared tier.

- [ ] **<deliverable 1>** - tier: `<tier>` - <rationale>

**Tier definitions:**
- `code-done`: tests pass + committed + reviewed
- `service-done`: code-done + service running + health endpoint green + service-liveness PASS
- `system-done`: service-done + integration-smoke PASS for default flow + user-facing artifact verified

## 8. Budget, Timeline, Success Criteria
- Budget: $<n> API spend ceiling
- Timeline: <n> waves, ~<n> hours
- Success: <measurable, tied to system-done items>

## 9. Open Questions for the user (BLOCKING)
1. ...

## 10. Handoff to /supervisor
```bash
/supervisor ~/projects/<project_name>
```
```

**Append JSONL:**
```
{"event":"scope_completed","ts":"<iso>","project_path":"<path>","artifact_path":"<scope_md_path>","tier":"code-done","deliberators":["gemini"],"open_questions_count":<n>}
```

---

## Phase 6 - Telegram Milestone + Block

Send ONE Telegram via `@Viriansbot` (chat `6043054705`):

```
[/scope] Project <project_name> scoped.
SCOPE.md -> <path>
Open questions: <n> (BLOCKING)
Top OOTB candidate: <name or "build from scratch">
Deliberators: gemini
Ready for /supervisor when you say go.
```

Token at `~/studio/platform/secrets/` - read dynamically. If permission denied, dispatch a subagent with read access; if still blocked, log milestone with `telegram_failed` flag.

**EXIT.** Print SCOPE.md path, open-questions count, "Ready for /supervisor when you say go." Do NOT auto-dispatch /supervisor.

---

## Continuous Learning Loop (mandatory)

Every /scope MUST:

1. Inherit ecosystem lessons at start (NAS lessons_learned.md).
2. Activate continuous-learning-v2 at start (OOTB skill).
3. Promote at exit:
   - >= 0.8 -> NAS `lessons_learned.md`
   - >= 0.9 -> THIS file Hard-won lessons + NAS
4. Run `Skill({skill: "everything-claude-code:evolve"})` at exit to cluster scope-related instincts.
5. Disagreements between deliberators (V2+) auto-promote to candidate instincts at confidence 0.7.

---

## Hard-won lessons (auto-promoted from instincts ledger)

- **Always check OOTB before writing.** A 4-lane parallel hunt costs 5 minutes of subagent time and frequently saves weeks of build. Skip only if Will explicitly says so. (Founding rule 2026-04-27)
- **Tier every deliverable in SCOPE.md.** /supervisor Wave 8/9 gap was caused by tasks shipped as code-done that needed service-done. Fix is upstream: name the tier at scope time. (Founding rule 2026-04-27)
- **Disagreements are signal, not noise.** Record every disagreement in the ADR. Promote recurring patterns. (Founding rule 2026-04-27)
- **Block on Will go.** Pipeline stages are manual handoffs by design. /scope exits with path + question list; /supervisor runs only when Will says go. (Founding rule 2026-04-27)
- **NAS for permanent lessons, never the local replica.** (Inherited from /supervisor 2026-04-27)
- **Fail loudly when a deliberator CLI is missing.** Silent fallback degrades deliberation in a way /closeout cannot catch. Exit with install instructions. (Founding rule 2026-04-27)
- **Prefer OOTB wrappers (everything-claude-code codeagent-wrapper) over direct CLI invocation.** The wrapper handles session reuse, structured output, role prompts. Direct CLI is fallback only. (Founding rule 2026-04-27)

---

## Parameters

```
/scope <spec_dir> [--name <project_name>] [--deliberators gemini,codex,qwen] [--dry-run]
```

- `<spec_dir>` (required) - directory with at least one `.md` brain dump
- `--name` (optional) - override auto-derived kebab-case name
- `--deliberators` (optional) - V1 default `gemini`. V2+ list when Codex/Qwen are enabled.
- `--dry-run` (optional) - Phase 1+2 only, no provisioning, no deliberation

## Output Artifacts

- `~/projects/<project_name>/SCOPE.md`
- `<project_path>/docs/SCOPE_STAGE1_summary.md`
- `<project_path>/docs/candidates.md`
- `<project_path>/docs/deliberator_outputs/*.json`
- `<project_path>/data/night_shift_log.jsonl` (seed)
- Telegram message to the user

## What /scope Does NOT Do

- Implement code (deliberators propose; code happens in /supervisor)
- Make architectural decisions Will has not approved (Phase 9 questions BLOCK)
- Auto-launch /supervisor
- Write to local memory replica
- Run /closeout

---

**Go ahead and activate scope mode. Start with Phase 0 bootstrap.**

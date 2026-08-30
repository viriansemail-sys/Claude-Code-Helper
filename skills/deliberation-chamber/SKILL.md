---
name: deliberation-chamber
description: Multi-agent deliberation among 4 CLIs (Claude, Codex, Gemini, Qwen) toward consensus on a project plan. Round-table debate with cross-critique, fact-check subagent for contested claims, weighted voting by domain strength, and stable-disagreement escalation to user. Used by /scope Phase 4 to harden project plans before /supervisor runs. Lightweight orchestration, not a big system.
license: MIT
---

# Deliberation Chamber

Round-table debate among up to 4 CLIs (Claude, Codex, Gemini, Qwen) to converge on a hardened project plan. The output is a consensus plan plus an explicit "stable disagreements" list that escalates to the user.

This skill is invoked by `/scope` Phase 4. It can also be invoked standalone for any decision that benefits from multi-model deliberation.

---

## When to use

- /scope wants to harden a project plan before /supervisor runs
- Any decision where you want multiple model perspectives, not parallel one-shot opinions
- Idea-expansion mode: turning a one-paragraph brain dump into a project shape

## When NOT to use

- Single-model task (just dispatch one CLI directly)
- Time-critical task (deliberation can take 30-60 minutes)
- Already-decided task (no point deliberating settled questions)

---

## Inputs

```
deliberation-chamber <project_path> [--mode debate|expand] [--budget 25] [--rounds 6] [--deliberators claude,codex,gemini,qwen]
```

- `<project_path>` (required) — must contain at minimum a spec at `docs/SCOPE_STAGE1_summary.md` and ideally `docs/candidates.md`
- `--mode debate` (default) — debate an existing plan
- `--mode expand` — turn a sparse brain dump into a project shape (auto-detected if Stage 1 summary is < 300 words)
- `--budget` — cost ceiling in dollars (default $25, mirrors /supervisor). Telegram alert at 80%.
- `--rounds` — round cap (default 6, hard maximum 10)
- `--deliberators` — comma-separated subset (default all 4 if available)

## Outputs

- `<project_path>/docs/deliberation/transcript.jsonl` — append-only round-by-round transcript
- `<project_path>/docs/deliberation/whiteboard.json` — current consensus state, updated each round
- `<project_path>/docs/deliberation/consensus.md` — final synthesis when debate ends
- `<project_path>/docs/deliberation/stable_disagreements.md` — items the chamber could not agree on (escalates to user)
- `<project_path>/data/night_shift_log.jsonl` — JSONL events for round_complete, fact_check_fired, consensus_reached, etc.

---

## Deliberator Roster

V1 supports these four CLIs. Each has a domain emphasis — their vote weighs heavier on questions in their wheelhouse, lighter outside it.

| CLI | Backend | API key env | OOTB bridge | Wheelhouse (vote weight 1.5x) | Off-domain (vote weight 1.0x) |
|-----|---------|-------------|-------------|------------------------------|-------------------------------|
| codex | `codeagent-wrapper --backend codex` | `OPENAI_API_KEY` | everything-claude-code plugin | Writing, prose, UX copy, naming, user-facing narrative | Everything else |
| gemini | `codeagent-wrapper --backend gemini --gemini-model gemini-3-pro-preview` | `GEMINI_API_KEY` | everything-claude-code plugin | Creative direction, video/multimedia projects, multimodal | Everything else |
| qwen | direct CLI invocation (no wrapper as of 2026-04-27) | `DASHSCOPE_API_KEY` | NO — needs install | Coding feasibility, code architecture, debug paths | Everything else |
| claude | this conversation (no subprocess) | n/a | n/a | the system stack fit, synthesis, tiebreaker | Counts as a vote in all rounds |

**Vote weighting:** A claim like "use this code architecture" gets Qwen at 1.5x, others at 1.0x. A claim like "name the project X" gets Codex at 1.5x. The moderator (Claude) determines wheelhouse per claim using simple keyword tags; if uncertain, all weights are 1.0x.

**Conflict-of-interest guard for Claude:** Claude's vote is the LAST shown each round. The synthesis step explicitly checks "did Claude's vote shift the outcome away from the other three CLIs' rough consensus?" If yes, that's flagged in the transcript. Claude should not silently dominate.

---

## The 6-Round Protocol

### Round 1 — Opening positions

Each deliberator gets the SAME prompt:

```
You are <name> (CLI) participating in a project deliberation.

PROJECT SPEC:
<contents of docs/SCOPE_STAGE1_summary.md>

OOTB CANDIDATES (Phase 2 hunt results):
<contents of docs/candidates.md>

the system STACK MANIFEST:
<contents of stack manifest — see "Stack manifest" section below>

PRIOR LESSONS (from ~/.claude/memory-ledger/lessons_learned.md):
<top 20 most-relevant lessons>

YOUR JOB (Round 1 — Opening Position):
Return JSON with:
{
  "architecture": "<your proposed architecture>",
  "deliverables": [{"name": "...", "tier": "code-done|service-done|system-done", "rationale": "..."}],
  "ootb_pick": "<which OOTB candidate (or 'build from scratch') and why>",
  "risks": ["top 5 risks"],
  "open_questions": ["questions you would ask Will"],
  "confidence": 0.0,
  "claims": [
    {"claim": "<factual claim about the system stack or external tool>", "source": "manifest|candidates|speculation"}
  ]
}

EVERY factual claim MUST cite source: "manifest" (from the system stack manifest), "candidates" (from OOTB report), or "speculation" (you are guessing — flag it). Speculative claims will be fact-checked.
```

Run all deliberators in PARALLEL via `dispatching-parallel-agents`. Save each to `transcript.jsonl` as `{event: "round_1_position", deliberator: <name>, content: <json>, ts: <iso>}`.

### Round 2 — Critique

Each deliberator sees ALL of Round 1. Prompt:

```
ROUND 2 — CRITIQUE

Here are the Round 1 positions from all deliberators:
<all Round 1 outputs, labeled by name>

YOUR JOB:
Return JSON with:
{
  "agree_with": [{"deliberator": "<name>", "claim": "<their claim>", "why": "..."}],
  "disagree_with": [{"deliberator": "<name>", "claim": "<their claim>", "your_position": "...", "evidence": "..."}],
  "missed_in_my_own_round_1": ["things I now realize I missed"],
  "factual_disputes_to_check": [
    {"deliberator_a": "<name>", "deliberator_b": "<name>", "topic": "...", "what_to_verify": "..."}
  ]
}

EVERY disagreement must cite which deliberator and which specific claim you are challenging. No vague "I disagree with the architecture" — name the claim.
```

Run in parallel. Save to transcript.

### Mid-debate fact-check (between Round 2 and Round 3)

Aggregate all `factual_disputes_to_check` from Round 2. Pick the top 3 most contested (most deliberators flagged it). For each, dispatch a research subagent:

```
FACT-CHECK QUERY:
Topic: <topic>
Disputants: <deliberator A says X, deliberator B says Y>
What to verify: <specific question>

Sources (in order of trust):
1. the system stack manifest (read the actual file, do not hallucinate)
2. The actual codebase if relevant (Glob/Grep on ~/projects)
3. The OOTB candidate links from candidates.md
4. WebSearch + WebFetch for external tooling claims

Return: VERDICT (deliberator A correct / B correct / both wrong / both right) + EVIDENCE (file paths, URLs, or quoted text).
```

Inject fact-check verdicts into Round 3's prompt. Append `{event: "fact_check_fired", topic: ..., verdict: ..., ts: ...}` to night_shift_log.jsonl.

### Rounds 3-5 — Convergence passes

Moderator (Claude) compiles a "Live Whiteboard" each round before dispatching:

```
LIVE WHITEBOARD (after Round N):

CONVERGED:
- <items where 3+ deliberators agree>

CONTESTED:
- <items where deliberators split, with positions labeled>

FACT-CHECK RESULTS:
- <verdicts injected>

UNRESOLVED QUESTIONS:
- <open items>
```

Round N prompt to each deliberator:

```
ROUND <N> — CONVERGENCE

Live Whiteboard (current state of debate):
<whiteboard content>

YOUR JOB:
Focus ONLY on CONTESTED items. For each:
- Restate your position
- Address the strongest counter-argument from another deliberator
- Propose a concrete compromise or admit the other side has a stronger case

If you no longer hold a position you held in earlier rounds, say so explicitly: "I move from X to Y because <evidence>."

Return JSON with:
{
  "still_contested": [{"item": "...", "your_position": "...", "compromise_proposal": "..."}],
  "moved_position": [{"from": "...", "to": "...", "why": "..."}],
  "now_converged": ["items I now agree with the consensus on"]
}
```

Save to transcript. After each round, recompute the whiteboard.

### Round 6 — Final convergence (or earlier if consensus reached)

If at the start of Round N>2 the whiteboard CONTESTED list is empty (or only stable-disagreement items remain), skip remaining rounds and go directly to synthesis. Otherwise debate to the round cap.

### Convergence detection

After each round, check:
- **Hard consensus:** CONTESTED list empty → synthesize and exit
- **Stable disagreement:** SAME contested items in two consecutive rounds with no position movement → freeze those as "stable disagreements," remove from debate, continue on remaining items
- **Round cap:** at Round 6, force synthesis with whatever consensus exists

### Synthesis

Claude (the moderator + voting deliberator) writes `consensus.md`:

```markdown
# Deliberation Consensus — <project_name>

**Rounds run:** N of 6
**Deliberators:** claude, codex, gemini, qwen
**Convergence:** hard / soft / round-cap-forced
**Total cost:** $X.XX (under $Y budget)

## Architecture (consensus)
<consensus architecture, citing which deliberators agreed>

## Deliverables (tier-locked)
| Deliverable | Tier | Vote | Notes |
|-------------|------|------|-------|
| ... | code-done | unanimous | ... |
| ... | service-done | 3 of 4 (qwen dissent: <why>) | ... |

## OOTB Pick
<consensus pick or "build from scratch" with rationale>

## Top 5 Risks (consensus)
1. ...

## Stable Disagreements (escalate to the user)

These items did not converge after <N> rounds. They are documented here AND in stable_disagreements.md for SCOPE.md Phase 9 question block:

| Topic | Position A (deliberators) | Position B (deliberators) | Evidence |
|-------|--------------------------|--------------------------|----------|

## Moderator Conflict-of-Interest Audit

Did Claude's vote shift any outcome away from the other three CLIs' rough consensus?
- <yes/no per item, with note>
```

Append `{event: "consensus_reached", rounds_used: N, stable_disagreements_count: M, cost: $X, ts: ...}` to night_shift_log.jsonl.

---

## Stack manifest

The chamber needs a condensed the system stack snapshot for grounding. Build it on first invocation if missing at `<project_path>/docs/deliberation/STACK_MANIFEST.md`:

Source: pull the relevant sections from `~/.claude/CLAUDE.md`:
- Node Reference table
- What is Running tables
- Home Assistant Devices
- Available MCP Tools
- CRITICAL LESSONS / DO NOT list
- Key Paths

Plus a live snapshot:
- `docker ps` output across major nodes (via `status` skill if present)
- `df -h ~/nas` for available storage
- Last 5 entries from NAS lessons_learned.md

Cap at 4000 tokens. The manifest is the SOURCE OF TRUTH for "what the system looks like right now." Deliberators must cite from it, not invent.

---

## Idea-expansion mode (auto-detected)

If the Stage 1 summary is under 300 words OR the spec dir is a single paragraph brain dump, switch Round 1 to:

```
ROUND 1 — IDEA EXPANSION (not critique)

You are looking at a sparse idea, not a finished plan. Will has thrown out a thought and wants to know what project shape would emerge from it.

IDEA:
<contents>

the system STACK MANIFEST:
<manifest>

YOUR JOB:
Return JSON with:
{
  "what_this_actually_is": "<one paragraph — your reading of the underlying intent>",
  "smallest_useful_v1": "<the minimum project that delivers value>",
  "ambitious_v1": "<what the bigger version looks like>",
  "deliverables_starting_set": [...],
  "ootb_pick_or_build": "...",
  "questions_to_clarify_intent": ["..."]
}
```

Rounds 2+ proceed normally — debate the proposed shapes, converge on one.

---

## Cost ceiling

- Default budget: $25 (override with `--budget`)
- Track per-round cost in `transcript.jsonl` under `cost_so_far`
- At 80% of budget: Telegram milestone "[deliberation] approaching budget on <project>. <N> rounds run, <X> contested items. Continue?" Will replies via Telegram or kills the chamber.
- At 100%: force synthesis at next round boundary even if not converged. Document the cost-cap as a stable disagreement source.

Cost discipline note: mirror /supervisor's pattern. Cheap routine work to whichever CLI is cheapest in their wheelhouse; reserve premium models for the synthesis step.

---

## Hard-won lessons

- **Parallel one-shot prompts are not deliberation.** Round 1 is parallel. Round 2+ MUST see other deliberators' positions. Without cross-visibility, you get four parallel monologues, not consensus. (Founding rule 2026-04-27)
- **Cite or speculate, never both.** Every factual claim about the system stack or external tools must be tagged `manifest`, `candidates`, or `speculation`. Speculative claims auto-route to fact-check before next round. (Founding rule 2026-04-27)
- **Claude's vote is shown last and audited.** Moderator-as-voter has conflict-of-interest risk. Display Claude's vote after the others; audit whether Claude's vote moved any outcome away from the rough consensus. Document in synthesis. (Founding rule 2026-04-27)
- **Stable disagreement is a feature.** Two rounds with the same disagreement = it is real. Surface it to the user as a SCOPE.md question, do not let the chamber hand-wave it away with a forced compromise. (Founding rule 2026-04-27)
- **Domain weighting prevents Codex-overrules-Qwen-on-code.** A 1.5x weight in wheelhouse, 1.0x out of wheelhouse, keeps each deliberator influential where they are strongest without letting them dominate where they are weak. (Founding rule 2026-04-27)
- **Idea-expansion mode is different from critique mode.** A 50-word brain dump cannot be critiqued because there is nothing to critique. Mode auto-detects on word count + structure. (Founding rule 2026-04-27)

---

## Output to /scope

When invoked by /scope Phase 4, the chamber returns a structured handoff:

```json
{
  "consensus_md_path": "<project_path>/docs/deliberation/consensus.md",
  "stable_disagreements_path": "<project_path>/docs/deliberation/stable_disagreements.md",
  "deliverables": [...],   // tier-locked, ready for SCOPE.md section 7
  "open_questions_for_will": [...],   // ready for SCOPE.md section 9
  "rounds_run": N,
  "cost": "$X.XX",
  "convergence": "hard|soft|round-cap"
}
```

/scope Phase 5 uses this directly to write SCOPE.md.

---

## What this skill does NOT do

- Implement code (deliberators only propose; code happens in /supervisor)
- Override Will (stable disagreements escalate to him, do not get auto-resolved)
- Run continuously (one debate, one consensus, exit)
- Cache deliberators (each invocation is a fresh debate; prior project transcripts are reference only)

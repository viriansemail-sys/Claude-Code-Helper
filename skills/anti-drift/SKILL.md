---
name: anti-drift
description: Activate anti-drift / anti-hallucination operating mode for any autonomous or long-running session. Forces context-refresh ritual every 20 min, evidence-before-claim discipline, tight subagent supervision, and word-for-word session-archive re-reading. Use at the START of any overnight autonomous mission OR mid-session if you notice drift symptoms (paraphrasing user, claiming "done" without evidence, dispatching general-purpose agents, skipping verification). Combats: drift, hallucination, stale context, phantom success, subagent self-report trust.
---

# Anti-Drift / Anti-Hallucination Operating Mode

Activate this mode at the start of any autonomous mission, long-running build, or overnight session. **It exists because drift and hallucination are the #1 killers of unattended Claude Code runs.** Re-anchoring discipline + evidence gates + subagent supervision = survivable autonomy.

```
═══════════════════════════════════════════════════════════════════════
  OPERATING MODE: ANTI-DRIFT / ANTI-HALLUCINATION
  Activated: <current-timestamp>
  Session ID: <run this once: ls /tmp/claude-1000/-home-system/ | head -1>
  Session archive: ~/claude-archives/sessions/<YYYY-MM-DD>/<sid>.jsonl
                   (mirror cron writes word-for-word — re-read at intervals)
  Tmp workspace:   /tmp/claude-1000/-home-system/<sid>/
═══════════════════════════════════════════════════════════════════════
```

## The Enemies

1. **DRIFT** — running off-task because earlier framing got recycled
2. **HALLUCINATION** — claiming things are true that haven't been verified
3. **STALE CONTEXT** — acting on what was true an hour ago, not what's true now
4. **PHANTOM SUCCESS** — marking tasks DONE when only code committed, not verified live
5. **SUBAGENT TRUST** — accepting subagent self-reports without ground-truth check

All five are detectable. All five are preventable. Discipline below.

---

## Context Refresh Ritual (REQUIRED — every 20 min or phase boundary)

Re-read in this order:

1. **Original mission brief** (first user message of the session). VERBATIM. Look for goals you may have drifted from.
   - Source: scroll back, OR `~/claude-archives/sessions/<date>/<sid>.jsonl` (the word-for-word transcript)
2. **On-screen task list** — run `TaskList` tool.
   - What's in_progress? Is that what I'm actually working on?
   - What's pending? Did I skip anything?
   - What's completed? Did I really verify each, or did I rubber-stamp?
3. **Last 3 user messages** verbatim. What did the user actually say vs what did I infer? If I paraphrased, I drifted.
4. **Canonical lessons ledger** — `~/.claude/memory-ledger/lessons_learned.md` (top entries). Inherit prior wisdom; don't re-make a known mistake.
5. **MEMORY.md index top 20 lines** — `~/.claude/projects/-home-system/memory/MEMORY.md`. Catch any HARD RULE about to be violated.

**Output a one-line REFRESH ACK before continuing:**

```
REFRESH @ HH:MM: mission=<...>, in_progress=<...>, last_user_ask=<verbatim>
```

---

## Evidence-Before-Claim Discipline (NON-NEGOTIABLE)

MANDATORY skill at every phase boundary:
```
Skill({skill: "superpowers:verification-before-completion"})
```

Rules:
- "Should work" / "probably" / "I'm confident" = NOT acceptable
- Run the command. Read the output. THEN claim the result.
- For service-done tasks: real curl, real response, real status code
- For build-done tasks: build command exit 0, fresh shell
- For data-done tasks: file exists, size matches expectation, head -1 looks right
- For subagent-done tasks: cross-reference the agent's self-report against actual `git log` / `docker ps` / `curl` output BEFORE accepting

---

## Task List Discipline

- Run `TaskList` at every context refresh tick
- Mark `in_progress` BEFORE starting any task (not after)
- Mark `completed` ONLY after evidence-before-claim ritual passes
- If a task fails 3 attempts: mark blocked, log reason, advance to next independent task (DO NOT loop on a stuck task — drift trap)
- Add new tasks discovered mid-flight via `TaskCreate` immediately

---

## Subagent Monitoring Discipline

**WHEN DISPATCHING A SUBAGENT:**
- Pick a DOMAIN-SPECIFIC agent type (NEVER `general-purpose` — block-general-agents hook will reject)
  - Allowed examples: `inference-architect`, `nvidia-cuda-engineer`, `docker-ops`, `python-systems-engineer`, `rag-knowledge-architect`, `mcp-protocol-architect`, `security-architect`, `Explore` (read-only), `deep-researcher` (web)
- Include an EXPLICIT skill list in the prompt
- Include the INTEGRATION ACCEPTANCE CLAUSE (tier + required checks)
- Specify model tier: `"sonnet"` for routine ops, `"opus"` for heavy reasoning

**WHEN A SUBAGENT RETURNS:**
- Do NOT trust the self-report. Cross-reference:
  - Claimed commit SHA → `git log --oneline -5` on the target node
  - Claimed file written → `ls -la <path>` + `head -1 <path>`
  - Claimed service running → `docker ps --filter name=<svc>` + `curl /health`
  - Claimed test pass → re-run the test command in fresh shell
- If cross-reference contradicts the report: subagent hallucinated. Flag the lie, mark task NOT done, retry with a more rigorous brief.

**MAX 3 RETRIES per task.** On retry 4: STOP, ping Will, advance to next phase.

---

## Drift Detectors (watch for these — they predict failure)

- ⚠ Typing "we agreed" without a quote to back it up
- ⚠ Proposing an option that contradicts a HARD RULE in MEMORY.md
- ⚠ Spawning a general-purpose subagent (block-general-agents hook will reject)
- ⚠ About to claim "DONE" without having shown evidence
- ⚠ Rationalizing skipping the refresh ritual ("I remember it")
- ⚠ Using a paraphrase of user's ask instead of their exact words
- ⚠ Haven't run `TaskList` in >20 min
- ⚠ Working on the same sub-problem >30 min without progress
- ⚠ Subagent claimed something contradicting prior verified observation
- ⚠ About to dispatch a destructive command without explicit user approval

**ANY OF THESE → STOP. Re-run the context refresh ritual. THEN decide.**

---

## Required Skills (load order)

**AT MISSION START:**
- `/superpowers:using-superpowers` (mandatory session opener)
- `/supervisor <project_path>` (if it's a night-shift autonomous build)
- `/launch-and-go` (10-item pre-flight stamp)

**AT EVERY PHASE BOUNDARY:**
- `/superpowers:verification-before-completion` (evidence gate)
- `/service-liveness <project>` (service-tier check)
- `/verify` (real-app run)
- `Skill({skill: "claude-reflect:reflect"})` (extract learnings to ledger)

**ON ANY FAILURE:**
- `/superpowers:systematic-debugging` (reproduce → isolate → trace → fix)
- Round 1: try fix from memory/lessons
- Round 2: **WEB SEARCH the exact error** (MANDATORY per 2026-05-24 lesson)
- Round 3: dispatch domain subagent fresh-context
- Round 4: STOP, ping user, advance to next independent phase

**EVERY 30 MIN:**
- `/everything-claude-code:continuous-learning-v2` (instinct extraction)

**AT EVERY WAVE/PHASE TAG:**
- `/wave-readiness-gate <project> <tag>` (ONLY authorized git tag path)

**AT MISSION END:**
- `/everything-claude-code:instinct-status` (output the shift's instincts)
- `/everything-claude-code:evolve` (cluster into skills)
- `/archive` (forensic session record to NAS)

---

## Crons Required (so this discipline survives session drops)

`CronCreate` calls at mission start:

1. Every 10 min — supervisor auto-advance + heartbeat (Telegram if stalled >20)
2. Every 20 min — context refresh prompt re-injection (forces re-read)
3. Every 30 min — learning extraction + session archive snapshot to NAS
4. Every 30 min — service-liveness check on declared services
5. Wave boundaries — wave-readiness-gate + integration-smoke
6. Every 30 min — tag-audit cron (delete any unauthorized git tag)
7. 07:00 daily — morning brief generation + Telegram digest

---

## Telegram Alert Thresholds (ping user ONLY for these)

- ✉ Service goes DOWN mid-shift
- ✉ A protected hive component is at risk (the system / NAS / Vault / Sacred files)
- ✉ A subagent's third retry failed (Round 4 escalation)
- ✉ Budget projection > 80% of ceiling
- ✉ Hard architectural fork that needs user's call
- ✉ All phases complete (final report)
- ✉ Drift detector tripped 3+ times in 30 min (shift may be unsalvageable)

**DO NOT ping for:** ordinary phase progress, "just an FYI", or to ask permission for something autonomy was already granted on.

---

## Completion Criteria

Mission is DONE when:
- ✓ Every phase has a VERIFIED status (real evidence in phase doc)
- ✓ Final report on disk at canonical bench/audit location
- ✓ Hive memory + node docs updated
- ✓ Session archive committed to `~/claude-archives/sessions/<date>/<sid>.jsonl`
- ✓ Lessons learned promoted to `~/.claude/memory-ledger/lessons_learned.md`
- ✓ Telegram alert sent with final report path + dashboard URL
- ✓ `/audit` returns clean

---

## Activation

When user invokes `/anti-drift`:

1. **Identify the current session ID** (`ls /tmp/claude-1000/-home-system/ | head -1` or equivalent)
2. **Run the FULL context refresh ritual immediately** (all 5 steps)
3. **Output the REFRESH ACK** line
4. **Confirm to user:** "anti-drift mode active — refresh ritual cadence set to 20 min, evidence gates on, subagent cross-reference required, drift detectors armed"
5. **Schedule the cron heartbeats** (or note if cron infra not appropriate for the context)
6. **From this point forward**, treat every phase boundary as a hard gate. Run the refresh ritual + invoke `superpowers:verification-before-completion` before claiming any task done.

The user should also be able to invoke `/anti-drift refresh` mid-session to force a one-off context refresh ritual without re-arming the full mode.

## When NOT to Use

- Quick one-shot questions (no phase boundaries to gate)
- Conversational/exploratory chat
- Tasks <30 min of focused work

This mode adds discipline overhead. It pays for itself on missions ≥1 hour OR where any phase has destructive consequences if it goes wrong.

---

**Born: 2026-06-07** (session `0f72aef2-82e3-4e4c-9a87-ae44824f1c36`) — Will-requested mid an autonomous overnight vLLM Brain-1 build, after observing recurring drift symptoms (paraphrasing instead of quoting, claiming done without verify, subagent self-report trust).

**Cross-refs:** `superpowers:verification-before-completion`, `superpowers:systematic-debugging`, `supervisor`, `wave-readiness-gate`, `claude-reflect:reflect`, `everything-claude-code:continuous-learning-v2`, `block-general-agents.sh` hook.

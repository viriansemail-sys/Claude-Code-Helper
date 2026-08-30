#!/usr/bin/env bash
# ============================================================================
#  CONVERSATION GOVERNOR — UserPromptSubmit hook
#
#  Fires on EVERY user turn — cwd-independent, compaction-proof — and injects
#  two things the assistant must honor before ANY consequential action:
#    1. The 4-step action sequence (RESTATE -> TRACE -> VERIFY -> ACT)
#    2. The ACTIVE PLAN, verbatim, if one is pinned (kills "I forgot the plan")
#
#  Why: long sessions drift. Plans read once at session start go stale after
#  compaction; the model starts paraphrasing the task and re-asking settled
#  questions. This hook re-anchors every single turn.
#
#  Pin a plan:    echo /path/to/SPEC.md > ~/.claude/.active-plan
#  Clear it:      rm ~/.claude/.active-plan
#
#  Wire it (settings.json):
#    "hooks": { "UserPromptSubmit": [ { "hooks": [
#      { "type": "command", "command": "~/.claude/hooks/conversation-governor.sh" }
#    ] } ] }
#
#  ── FAIL-OPEN ──────────────────────────────────────────────────────────
#  Must NEVER block a prompt. Every error path exits 0.
# ============================================================================
set -uo pipefail

INPUT=$(cat 2>/dev/null || true)

PLAN_BLOCK=""
PTR="$HOME/.claude/.active-plan"
if [ -f "$PTR" ]; then
  SPEC=$(head -1 "$PTR" 2>/dev/null | tr -d '\n')
  if [ -n "$SPEC" ] && [ -f "$SPEC" ]; then
    # inject a bounded slice so it can't balloon context unboundedly
    PLAN_BLOCK=$(printf '\n📌 ACTIVE PLAN (pinned — this is the source of truth, not your memory):\n   %s\n%s\n' \
      "$SPEC" "$(sed 's/^/   │ /' "$SPEC" 2>/dev/null | head -60)")
  fi
fi

cat <<EOF
[conversation-governor] ⛔ HARDEST RULE — run this sequence BEFORE every consequential action, every turn, no exceptions:

  1. RESTATE — what did the user actually ask THIS turn? Quote it, don't paraphrase. If a plan is pinned below, your action must serve a line of it.
  2. TRACE   — does my next action serve that ask / that plan line? If NOT → STOP and ask. Never substitute my version of the task for the user's.
  3. VERIFY  — any claim ("ready/done/works/fixed/complete") requires a command I ran THIS turn, output in hand. No fresh evidence = don't claim it.
  4. ACT     — only now.

Skipping a step is the drift that wastes days. The gate is not the start or end of the session — it is EVERY action.
${PLAN_BLOCK}
EOF
exit 0

#!/usr/bin/env bash
# Hook 3: PreToolUse on Bash containing 'git tag'
# PURPOSE: Block ALL raw git tag calls. The wave-readiness-gate skill is the ONLY
#          authorized tag executor. This hook fires for the parent supervisor.
#          Subagents have their own context — for them the block comes from:
#            (a) this hook when the parent supervisor runs their Bash tool
#            (b) the wave-readiness-gate SKILL.md policy injected into every subagent prompt
#            (c) the tag-audit skill (cron #7) which auto-deletes unauthorized tags post-hoc
#
# POLICY: Any raw `git tag` call (other than git tag -d for cleanup or git tag -l for listing)
#         is BLOCKED. The caller MUST use: Skill({skill: "wave-readiness-gate", args: "<project_path> <tag>"})
#
# Fails OPEN on unexpected errors (not on known BLOCK condition).

set -euo pipefail

INPUT=$(cat)

# Fail open if jq missing
if ! command -v jq &>/dev/null; then
  exit 0
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Only trigger on git tag commands
if ! echo "$COMMAND" | grep -qE '\bgit\s+tag\b'; then
  exit 0
fi

# Allow read-only tag operations: git tag -l / git tag --list / git tag (no args = list)
if echo "$COMMAND" | grep -qE '\bgit\s+tag\s*(-l|--list)\b'; then
  exit 0
fi

# Allow read-only (bare git tag with no positional arg after flags = listing)
if echo "$COMMAND" | grep -qE '\bgit\s+tag\s*$'; then
  exit 0
fi

# Allow tag DELETION (used by tag-audit cleanup): git tag -d
if echo "$COMMAND" | grep -qE '\bgit\s+tag\s+-d\b'; then
  exit 0
fi

# ── SUBAGENT DETECTION ──────────────────────────────────────────────────────
# Claude Code does not currently expose a subagent-vs-parent env variable in
# hook context (confirmed by checking $CLAUDE_* env during hook execution).
# POLICY: We therefore treat ALL raw git tag WRITE attempts as bypass attempts
# regardless of origin. The only legitimate path is wave-readiness-gate skill,
# which calls git tag internally after running all gates. If the caller is the
# skill itself, it will have already verified readiness before reaching this hook
# — but since the hook can't distinguish skill-internal calls from raw calls,
# we check for a well-known gate proof token in the environment.
#
# wave-readiness-gate-check.sh sets WAVE_GATE_PROOF=1 before running git tag.
# If that env var is set, this is a skill-authorized tag — allow it.
if [[ "${WAVE_GATE_PROOF:-}" == "1" ]]; then
  exit 0
fi

# ── BLOCK ALL OTHER RAW git tag WRITE OPERATIONS ────────────────────────────
TAG_ARG=$(echo "$COMMAND" | grep -oP '\bgit\s+tag\s+\K[^\s]+' | head -1 || echo "unknown")

cat <<EOF
{"decision":"block","reason":"SUBAGENT HOOK BYPASS BLOCKED: raw 'git tag ${TAG_ARG}' is not allowed. The wave-readiness-gate skill is the ONLY authorized tag executor. Invoke it with: Skill({skill: \"wave-readiness-gate\", args: \"<project_path> <tag>\"}). This block applies to ALL callers (parent supervisor AND subagents) — the wave-readiness-gate-check.sh sets WAVE_GATE_PROOF=1 internally when all gates pass."}
EOF
exit 0

#!/usr/bin/env bash
# UserPromptSubmit hook — Project the assistant Renew Wave 0 item C6.
# Reads stdin (JSON with .prompt), greps ~/.claude/specialist-map.json,
# injects a system reminder if any keyword pattern matches the user's message.
# Exit 0 always (suggesting, not blocking).
# Hard rule (Will, 2026-06-08): test in isolation BEFORE wiring to settings.json.

set -u
MAP="~/.claude/specialist-map.json"

# Bail silently if map missing — prompt still proceeds.
[[ -r "$MAP" ]] || exit 0

input="$(cat)"

# Extract prompt text; if anything goes sideways, surface no suggestion.
prompt="$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print((d.get("prompt") or "").strip())
except Exception:
    print("")
' 2>/dev/null)"

[[ -z "$prompt" ]] && exit 0

# Match patterns; collect up to 3 distinct hits to avoid noise.
hits="$(python3 - "$MAP" "$prompt" <<'PY' 2>/dev/null
import json, re, sys
map_path, prompt = sys.argv[1], sys.argv[2]
with open(map_path) as f:
    m = json.load(f)
seen, hits = set(), []
for p in m.get("patterns", []):
    if p["specialist"] in seen:
        continue
    if re.search(p["regex"], prompt, re.IGNORECASE):
        hits.append(p)
        seen.add(p["specialist"])
    if len(hits) >= 3:
        break
if not hits:
    sys.exit(0)
lines = ["[specialist-suggester] the user's message pattern-matches the following specialists:"]
for h in hits:
    lines.append(f"  • {h['specialist']} — {h['why']}")
lines.append("Per Specialist-Surface Habit rule (CLAUDE.md): name candidates with one-line rationale, then pick.")
print("\n".join(lines))
PY
)"

[[ -z "$hits" ]] && exit 0

# Emit additionalContext via the documented hookSpecificOutput contract.
python3 - "$hits" <<'PY'
import json, sys
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": sys.argv[1]
  }
}))
PY
exit 0

#!/usr/bin/env bash
# UserPromptSubmit hook — Project the assistant Renew Wave 0 item D14.
# Detects sustained topic drift across a session: if the user's primary domain
# stays stable for several prompts then flips to an unrelated domain for
# N consecutive prompts AND elapsed > THRESHOLD minutes, surface a nudge:
# "You started X N min ago, you're now on Y. Stay or switch?"
#
# Uses ~/.claude/specialist-map.json as the domain dictionary (no fork).
# State at /tmp/claude-1000/-home-system/<sid>/rabbit-hole-state.json (per-session).
#
# [VERIFY] Heuristic: hooks can't read TaskList directly, so "primary domain"
# = the most-frequent domain among the first N anchoring prompts. False positives
# are OK in WARN mode — flip to BLOCK only after telemetry shows reliability.
#
# Mode: WARN-only. Exit 0 always.

set -u

MAP="~/.claude/specialist-map.json"
DRIFT_MIN_PROMPTS="${RABBIT_HOLE_DRIFT_PROMPTS:-3}"     # consecutive off-domain prompts
DRIFT_MIN_MINUTES="${RABBIT_HOLE_DRIFT_MINUTES:-25}"   # elapsed since session anchor
ANCHOR_PROMPTS="${RABBIT_HOLE_ANCHOR_PROMPTS:-3}"      # first N prompts establish primary

[[ -r "$MAP" ]] || exit 0

input="$(cat)"

parsed="$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get("session_id",""))
    print((d.get("prompt") or "").strip().replace("\n"," "))
except Exception:
    print("")
    print("")
' 2>/dev/null)"

sid="$(printf '%s\n' "$parsed" | sed -n '1p')"
prompt="$(printf '%s\n' "$parsed" | sed -n '2p')"

[[ -z "$sid" || -z "$prompt" ]] && exit 0

STATE_DIR="/tmp/claude-1000/-home-system/${sid}"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
STATE="$STATE_DIR/rabbit-hole-state.json"

# Reset-on-explicit-switch: if Will signals topic change, drop state.
case "${prompt,,}" in
  *"new topic"*|*"different topic"*|*"switching to"*|*"let's switch"*|*"change topic"*|*"forget that"*|*"now let's"*)
    rm -f "$STATE"
    ;;
esac

# Compute current message's domain set + maybe-fire decision in Python.
out="$(python3 - "$MAP" "$STATE" "$prompt" "$DRIFT_MIN_PROMPTS" "$DRIFT_MIN_MINUTES" "$ANCHOR_PROMPTS" <<'PY' 2>/dev/null
import sys, json, re, os, time, datetime
map_path, state_path, prompt, drift_n, drift_min, anchor_n = sys.argv[1:]
drift_n = int(drift_n); drift_min = int(drift_min); anchor_n = int(anchor_n)

with open(map_path) as f:
    m = json.load(f)

# Domain label = specialist name; record which patterns matched this prompt.
def domains_of(text):
    hit = []
    for p in m.get("patterns", []):
        if re.search(p["regex"], text, re.IGNORECASE):
            hit.append(p["specialist"])
    return hit

curr = domains_of(prompt)
now = int(time.time())

# Load prior state.
state = {"started_at": now, "history": [], "primary": None}
if os.path.isfile(state_path):
    try:
        with open(state_path) as f:
            state = json.load(f)
    except Exception:
        pass

# Append current prompt's domain set + timestamp.
state["history"].append({"ts": now, "domains": curr})
state["history"] = state["history"][-20:]  # cap

# Establish primary domain after ANCHOR_N prompts: most frequent specialist.
if state["primary"] is None and len(state["history"]) >= anchor_n:
    from collections import Counter
    flat = [d for h in state["history"][:anchor_n] for d in h["domains"]]
    if flat:
        state["primary"] = Counter(flat).most_common(1)[0][0]

# Save state.
with open(state_path, "w") as f:
    json.dump(state, f)

# Decide drift.
if not state["primary"]:
    sys.exit(0)
if state["primary"] in curr:
    sys.exit(0)  # current message hits primary — not drifting

# Check last N including this one: all off-primary?
last_n = state["history"][-drift_n:]
if len(last_n) < drift_n:
    sys.exit(0)
all_off = all(state["primary"] not in h["domains"] for h in last_n)
if not all_off:
    sys.exit(0)

elapsed_min = (now - state["started_at"]) / 60.0
if elapsed_min < drift_min:
    sys.exit(0)

# Pick the most-mentioned current domain to call out.
from collections import Counter
flat_curr = [d for h in last_n for d in h["domains"]]
new_domain = Counter(flat_curr).most_common(1)[0][0] if flat_curr else "(unrelated)"

msg = (
    f"[rabbit-hole-guard] You anchored this session on **{state['primary']}** "
    f"~{int(elapsed_min)} min ago, but the last {drift_n} prompts have been on **{new_domain}**. "
    f"Stay on **{state['primary']}** (close this tangent) OR explicitly switch (say 'new topic' to reset)? "
    f"Surfacing once — won't repeat until you re-anchor or reset."
)

# Mark fired so we don't re-fire every prompt while still off-domain.
state["fired_at"] = now
with open(state_path, "w") as f:
    json.dump(state, f)

print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": msg
  }
}))
PY
)"

[[ -z "$out" ]] && exit 0

# Telemetry
LOG="~/data/logs/rabbit-hole-guard-hits.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
ts="$(date -Iseconds)"
printf '{"ts":"%s","session_id":"%s"}\n' "$ts" "$sid" >> "$LOG" 2>/dev/null || true

printf '%s\n' "$out"
exit 0

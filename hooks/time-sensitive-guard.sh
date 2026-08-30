#!/usr/bin/env bash
# PostToolUse hook (matcher: Read|Bash) — Project the assistant Renew Wave 0 item C9.
# After a Read or Bash call returns, scan the MOST-RECENT assistant text for
# time-sensitive assertions ("latest", "as of", "currently supports/doesn't support",
# "in 2026", "deprecated", "released") that reference a specific technology.
# If found AND no WebSearch/WebFetch in the last 10 tool calls → emit WARN.
#
# [VERIFY] Spec interpretation: PostToolUse can't see the assistant's *upcoming* draft.
# It CAN see her most-recent text (the message that called the tool). This warns
# before the next assistant turn doubles down on stale info.
#
# Mode: WARN-only (stderr) — exit 0 always. Flip to exit 2 for BLOCK after telemetry.

set -u

input="$(cat)"

transcript="$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    print(json.load(sys.stdin).get("transcript_path") or "")
except Exception:
    print("")
' 2>/dev/null)"

[[ -z "$transcript" || ! -r "$transcript" ]] && exit 0

result="$(python3 - "$transcript" <<'PY' 2>/dev/null
import sys, json, re
path = sys.argv[1]
last_text = ""
tool_calls = []
with open(path) as f:
    for line in f:
        try:
            row = json.loads(line)
        except Exception:
            continue
        msg = row.get("message") or {}
        if msg.get("role") != "assistant":
            continue
        for c in (msg.get("content") or []):
            if not isinstance(c, dict):
                continue
            if c.get("type") == "text" and c.get("text","").strip():
                last_text = c.get("text","")
            if c.get("type") == "tool_use":
                tool_calls.append(c.get("name",""))
recent = tool_calls[-10:]
web_used = any(t in ("WebSearch","WebFetch") for t in recent)
if web_used:
    sys.exit(0)

# Phrase patterns — must co-occur with a tech anchor in same sentence.
phrase = re.compile(
    r"\b(the latest|as of (today|now|\d{4})|currently (supports?|doesn'?t support|available)|"
    r"in 202[0-9]|deprecated|recently released|new(est)? version|just (released|shipped))\b",
    re.IGNORECASE)
tech_anchor = re.compile(
    r"\b(vllm|cuda|pytorch|nvidia|claude|gpt|gemini|opus|sonnet|haiku|llama|qwen|mistral|gemma|"
    r"unsloth|trl|peft|n8n|qdrant|redis|postgres|fastapi|node\.?js|react|next\.?js|tailscale|docker|"
    r"kubernetes|k8s|hugging[ -]?face|ollama|anthropic|openai|tensorrt|jetson|orin|this-node|frigate|"
    r"home assistant|hass|esphome)\b",
    re.IGNORECASE)

hits = []
for sent in re.split(r"(?<=[.!?])\s+", last_text):
    if phrase.search(sent) and tech_anchor.search(sent):
        hits.append(sent.strip()[:160])
    if len(hits) >= 3:
        break
if hits:
    print(json.dumps({"hits": hits}))
PY
)"

[[ -z "$result" ]] && exit 0

LOG="~/data/logs/time-sensitive-guard-hits.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
ts="$(date -Iseconds)"
sid="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("session_id",""))' 2>/dev/null || echo "")"
printf '{"ts":"%s","session_id":"%s","hits":%s}\n' "$ts" "$sid" "$(printf '%s' "$result" | python3 -c 'import sys,json; print(json.dumps(json.load(sys.stdin)["hits"]))')" >> "$LOG" 2>/dev/null || true

# WARN via stderr (PostToolUse stderr is surfaced to the assistant).
hits_human="$(printf '%s' "$result" | python3 -c 'import sys,json; [print("  • "+h) for h in json.load(sys.stdin)["hits"]]')"
cat >&2 <<EOF
[time-sensitive-guard WARN] The most recent assistant turn made time-sensitive claims about a specific technology, but no WebSearch/WebFetch ran in the last 10 tool calls:
$hits_human
Per the user's HARD RULE (2026-05-24): web-search the EXACT version/feature before asserting "the latest" or "doesn't support." WARN-only — promotes to BLOCK after telemetry.
EOF

exit 0

#!/usr/bin/env bash
# PreToolUse hook (matcher: Write) — Project the assistant Renew Wave 0 item C8.
# When the assistant is about to create a NEW .py/.sh/.js/.ts/.go/.rs file, require
# that a Build-vs-Buy citation appears in the recent assistant transcript.
# Mode: WARN-only (stderr + log) until 1 week of telemetry; flip exit 0 → 2 to BLOCK.

set -u

input="$(cat)"

# Parse tool_input.file_path + transcript_path
parsed="$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input", {}) or {}
    print(ti.get("file_path",""))
    print(d.get("transcript_path",""))
except Exception:
    print("")
    print("")
' 2>/dev/null)"

file_path="$(printf '%s\n' "$parsed" | sed -n '1p')"
transcript="$(printf '%s\n' "$parsed" | sed -n '2p')"

# Trigger only on code-file extensions
case "$file_path" in
  *.py|*.sh|*.js|*.ts|*.go|*.rs) ;;
  *) exit 0 ;;
esac

# Skip if file already exists (edit, not create)
[[ -e "$file_path" ]] && exit 0

# Skip if transcript unreadable
[[ -z "$transcript" || ! -r "$transcript" ]] && exit 0

# Look back through recent assistant text for a build-vs-buy citation.
# Acceptable markers: "build-vs-buy", "checked: skills/agents/existing/OSS",
# or numbered list mentioning "Installed skills" + "Installed agents".
cited="$(python3 - "$transcript" <<'PY' 2>/dev/null
import sys, json, re
path = sys.argv[1]
# Keep last ~30 assistant text blocks
texts = []
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
            if isinstance(c, dict) and c.get("type") == "text":
                txt = c.get("text","")
                if txt.strip():
                    texts.append(txt)
recent = " ".join(texts[-30:]).lower()
patterns = [
    r"build[- ]?vs[- ]?buy",
    r"installed skills.*installed agents",
    r"checked.*(skills|agents|existing|oss)",
]
for p in patterns:
    if re.search(p, recent, re.DOTALL):
        print("CITED"); break
PY
)"

[[ "$cited" == "CITED" ]] && exit 0

# Telemetry
LOG="~/data/logs/build-vs-buy-hits.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
ts="$(date -Iseconds)"
sid="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("session_id",""))' 2>/dev/null || echo "")"
printf '{"ts":"%s","session_id":"%s","file":"%s"}\n' "$ts" "$sid" "$file_path" >> "$LOG" 2>/dev/null || true

# WARN-mode: surface to the assistant via stderr (PreToolUse stderr is shown to her).
# Exit 0 = allow the write to proceed.
cat >&2 <<EOF
[build-vs-buy WARN] About to create new code file: $file_path
No Build-vs-Buy citation found in recent assistant turns. Per Hard Rule (CLAUDE.md):
  1. Installed skills checked?
  2. Installed agents checked?
  3. Existing hive projects checked?
  4. OSS via web search checked?
State all four (one line each) in chat BEFORE the next Write. WARN-only — promote to BLOCK after 1 week.
EOF

exit 0

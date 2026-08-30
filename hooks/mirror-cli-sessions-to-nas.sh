#!/bin/bash
# mirror-cli-sessions-to-nas.sh — word-for-word archive for Grok CLI + Gemini CLI
# sessions, mirroring the Claude Code sweep model (sweep-sessions-to-nas.sh).
#
# Both CLIs persist full transcripts to disk on their own; this just copies the
# raw session JSONL (the word-for-word primary) to the NAS and renders a .md
# sibling, into ~/claude-archives/sessions/{grok,gemini}/YYYY-MM-DD/.
#
#   Grok   : ~/.grok/sessions/<urlenc-cwd>/<uuid>/chat_history.jsonl  (+ summary.json)
#   Gemini : ~/.gemini/tmp/<cwd-base>/chats/session-*.jsonl           ($set patch format)
#
# Default: incremental — only sessions touched in the last 30 min; render .md once
# a session has been quiet >10 min and has no .md yet (same dead-man logic as CC).
# Run with `--all` (or MIRROR_ALL=1) to backfill EVERY existing session and render
# all .md now (ignores the time windows).
#
# Idempotent. NAS-unmounted tolerant (exits 0). Safe to run from cron every 5 min.

set -u
ARCHIVE_ROOT="~/claude-archives/sessions"
GROK_ROOT="${HOME}/.grok/sessions"
GEMINI_ROOT="${HOME}/.gemini/tmp"
LOG="${ARCHIVE_ROOT}/.cli-mirror.log"

ALL=0
[ "${1:-}" = "--all" ] && ALL=1
[ "${MIRROR_ALL:-0}" = "1" ] && ALL=1

# NAS present?
mountpoint -q ~/archive 2>/dev/null || [ -d "$ARCHIVE_ROOT" ] || exit 0

MMIN_ARGS=(-mmin -30)
[ "$ALL" -eq 1 ] && MMIN_ARGS=()

mirrored=0
rendered=0

day_dir_for() {  # $1 = source file -> echoes dest day dir by file mtime
  local f="$1" d
  d=$(date -d "@$(stat -c %Y "$f" 2>/dev/null)" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
  echo "${ARCHIVE_ROOT}/${2}/${d}"
}

quiet_enough() {  # $1 = source file ; true if quiet >10min OR --all
  [ "$ALL" -eq 1 ] && return 0
  local age=$(( $(date +%s) - $(stat -c %Y "$1" 2>/dev/null || echo 0) ))
  [ "$age" -ge 600 ]
}

# ---------------- GROK ----------------
if [ -d "$GROK_ROOT" ]; then
  while IFS= read -r SRC; do
    [ -z "$SRC" ] && continue
    SID="$(basename "$(dirname "$SRC")")"           # <uuid> = parent dir
    DEST_DIR="$(day_dir_for "$SRC" grok)"
    mkdir -p "$DEST_DIR" 2>/dev/null || continue
    DEST="${DEST_DIR}/${SID}.jsonl"
    cp -u "$SRC" "$DEST" 2>/dev/null && mirrored=$((mirrored+1))
    # carry the summary.json (title/metadata) if present
    SUM="$(dirname "$SRC")/summary.json"
    [ -f "$SUM" ] && cp -u "$SUM" "${DEST_DIR}/${SID}.summary.json" 2>/dev/null
    # render .md
    MD="${DEST%.jsonl}.md"
    { [ -f "$MD" ] && [ "$ALL" -ne 1 ]; } && continue
    quiet_enough "$SRC" || continue
    python3 - "$DEST" "$MD" "${DEST_DIR}/${SID}.summary.json" <<'PY' 2>/dev/null && rendered=$((rendered+1))
import json, sys, pathlib
src, dst = sys.argv[1], sys.argv[2]
title = ""
try:
    s = json.load(open(sys.argv[3]))
    info = s.get("info", s)
    title = s.get("session_summary") or info.get("generated_title") or ""
except Exception:
    pass
out = []
if title:
    out.append(f"# Grok session — {title}\n")
with open(src) as f:
    for raw in f:
        try:
            r = json.loads(raw)
        except Exception:
            continue
        role = r.get("type") or r.get("role") or ""
        c = r.get("content")
        if isinstance(c, list):
            c = "\n".join(x.get("text","") if isinstance(x, dict) else str(x) for x in c)
        if not isinstance(c, str) or not c.strip():
            continue
        ts = r.get("timestamp") or r.get("created_at") or ""
        out.append(f"## {role} {ts}\n\n{c}\n")
pathlib.Path(dst).write_text("\n".join(out))
PY
  done < <(find "$GROK_ROOT" -maxdepth 3 -name 'chat_history.jsonl' "${MMIN_ARGS[@]}" 2>/dev/null)
fi

# ---------------- GEMINI ----------------
if [ -d "$GEMINI_ROOT" ]; then
  while IFS= read -r SRC; do
    [ -z "$SRC" ] && continue
    BASE="$(basename "$SRC")"                         # session-<date>-<id>.jsonl
    SID="${BASE%.jsonl}"
    DEST_DIR="$(day_dir_for "$SRC" gemini)"
    mkdir -p "$DEST_DIR" 2>/dev/null || continue
    DEST="${DEST_DIR}/${BASE}"
    cp -u "$SRC" "$DEST" 2>/dev/null && mirrored=$((mirrored+1))
    MD="${DEST%.jsonl}.md"
    { [ -f "$MD" ] && [ "$ALL" -ne 1 ]; } && continue
    quiet_enough "$SRC" || continue
    python3 - "$DEST" "$MD" <<'PY' 2>/dev/null && rendered=$((rendered+1))
import json, sys, pathlib
src, dst = sys.argv[1], sys.argv[2]
meta, messages = {}, []
with open(src) as f:
    for raw in f:
        try:
            r = json.loads(raw)
        except Exception:
            continue
        if r.get("sessionId") and not messages:
            meta = r
        # incremental $set patches: last one carrying messages wins
        s = r.get("$set") if isinstance(r.get("$set"), dict) else None
        if s and isinstance(s.get("messages"), list):
            messages = s["messages"]
        elif isinstance(r.get("messages"), list):
            messages = r["messages"]
out = []
if meta.get("startTime"):
    out.append(f"# Gemini session — {meta.get('sessionId','')} ({meta.get('startTime','')})\n")
for m in messages:
    if not isinstance(m, dict):
        continue
    role = m.get("type") or m.get("role") or ""
    c = m.get("content")
    text = ""
    if isinstance(c, str):
        text = c
    elif isinstance(c, list):
        text = "\n".join(p.get("text","") if isinstance(p, dict) else str(p) for p in c)
    if not text.strip():
        continue
    ts = m.get("timestamp","")
    out.append(f"## {role} {ts}\n\n{text}\n")
pathlib.Path(dst).write_text("\n".join(out))
PY
  done < <(find "$GEMINI_ROOT" -maxdepth 4 -name 'session-*.jsonl' "${MMIN_ARGS[@]}" 2>/dev/null)
fi

echo "[$(date -Iseconds)] cli-mirror: mirrored=${mirrored} rendered=${rendered} all=${ALL}" >> "$LOG" 2>/dev/null || true
exit 0

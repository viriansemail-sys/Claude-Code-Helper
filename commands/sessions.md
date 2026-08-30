---
description: List mirrored session transcripts on NAS, today by default. Pass YYYY-MM-DD for another day, or `latest` to open most recent in less.
---

# /sessions — mirrored transcript browser

Reads `~/claude-archives/sessions/YYYY-MM-DD/` and shows what's there.

## Behavior

Parse `$ARGUMENTS`:
- empty → today
- `YYYY-MM-DD` → that day
- `latest` → open the most-recently-modified `.jsonl` in `less`
- `latest md` → open the most-recently-modified `.md` in `less`
- `all` → show last 14 days, summary counts

## Implementation

```bash
ROOT=~/claude-archives/sessions
ARG="${ARGUMENTS:-}"
if [ -z "$ARG" ]; then
  DAY=$(date +%Y-%m-%d)
  echo "== Sessions on $DAY =="
  ls -lh "$ROOT/$DAY/" 2>/dev/null || echo "(none yet)"
elif [ "$ARG" = "latest" ]; then
  F=$(ls -1t "$ROOT"/*/*.jsonl 2>/dev/null | head -1)
  [ -n "$F" ] && less "$F" || echo "No transcripts found."
elif [ "$ARG" = "latest md" ]; then
  F=$(ls -1t "$ROOT"/*/*.md 2>/dev/null | head -1)
  [ -n "$F" ] && less "$F" || echo "No markdown renders found."
elif [ "$ARG" = "all" ]; then
  echo "== Last 14 days =="
  for d in $(ls -1 "$ROOT" 2>/dev/null | tail -14); do
    n=$(ls "$ROOT/$d"/*.jsonl 2>/dev/null | wc -l)
    sz=$(du -sh "$ROOT/$d" 2>/dev/null | cut -f1)
    echo "$d  $n sessions  $sz"
  done
else
  echo "== Sessions on $ARG =="
  ls -lh "$ROOT/$ARG/" 2>/dev/null || echo "No folder for $ARG"
fi
```

## Examples

- `/sessions` — today's transcripts
- `/sessions 2026-06-04` — yesterday's
- `/sessions latest` — open newest JSONL in less
- `/sessions latest md` — open newest markdown render
- `/sessions all` — last 14 days summary

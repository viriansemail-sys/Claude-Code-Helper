---
name: morning-brief
description: Generate the Chairman's morning briefing. Pipeline status, revenue, blocked items, overnight activity, agent health. Delivered via Telegram at 7am daily.
user_invocable: true
---

# Morning Brief — Chairman's Daily Report

Generate a concise morning briefing for the user covering all V-Corp operations.

## When Triggered
- Automatically via cron at 7am MDT daily
- Manually via /morning-brief or /gm

## Data Sources
1. **Pipeline state** — Read ~/nas/pipeline/state.json
2. **Revenue** — Read latest report from ~/nas/pipeline/reports/revenue/
3. **Blocked items** — Check ~/nas/pipeline/blocked/ for items needing the user's attention
4. **Agent health** — Check if OC agents are responding on node-a ports 18792-18795
5. **Pipeline logs** — Read ~/nas/logs/pipeline/ for overnight activity
6. **Social posts** — Check if any are scheduled or pending approval

## Output Format

```
MORNING BRIEF — [Day, Month DD, YYYY]

PIPELINE:
  Ideas: X | Research: X | Design: X | Build: X | QA: X | Ship-Ready: X | Shipped: X
  [any movement overnight]

REVENUE:
  Yesterday: $X | MTD: $X | Products listed: X
  [top seller if applicable]

BLOCKED (needs you):
  - [item] — [reason] — [days blocked]

AGENTS:
  McLawd: [up/down] | Kai: [up/down] | Sofia: [up/down] | Ryan: [up/down] | the system: [up/down]

TODAY'S PRIORITIES:
  1. [highest impact action]
  2. [next]
  3. [next]

OVERNIGHT:
  [summary of any automated work that ran]
```

## Delivery
- Write to ~/nas/pipeline/reports/briefs/YYYY-MM-DD-morning.md
- Send via Telegram to the user (chat ID: 6043054705) if Telegram bot is available
- Display in terminal if triggered manually

## Good Night Brief Variant

Use this same briefing skill when Will asks for "tonight's brief", "Good Night Brief", or provides the 21:30 MDT date stamp. The night version is calmer and should summarize the day instead of planning the morning.

Recommended order:
1. Confirm current timestamp if needed.
2. Check scheduled briefing jobs and note delivery/fallback errors.
3. Check live system status: containers/services, GPU temperature/VRAM, and obvious high-impact processes.
4. Check recent project/log activity for the same date, especially `~/projects/system-core/logs/briefs/` and Hive Live logs.
5. If an automated brief timed out or fell back, do not repeat the failure text as the brief. Compose a manual brief from verified live signals.
6. Keep it short: HEADLINE, STATUS, SHIPPED, ON DECK, NIGHT WATCH.

Reference: `references/good-night-brief-fallback-2026-07-02.md` documents the fallback pattern from a real timeout.
Reference: `references/good-night-brief-live-signal-pattern-2026-07-03.md` captures the live-signal recipe for composing a manual night brief from cron status, Docker/GPU state, Hive Live watchdog recovery, and date-filtered supervisor logs.

## Rules
- Keep it under 30 lines
- Lead with what needs the user's attention
- No fluff — numbers and status only
- If nothing happened overnight, say "Quiet night. No pipeline movement."
- For night briefs, avoid morning-style pipeline tables unless the user asks for them; use concise operational synthesis.

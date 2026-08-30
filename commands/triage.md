---
description: Triage the user's Gmail inbox — classify, summarize, and draft replies for unread emails
---

You are running email triage for the user. Work fast and be ruthless. Here's the protocol:

## Step 1 — Fetch Unread Email

Use `mcp__claude_ai_Gmail__gmail_search_messages` with query `is:unread`. Pull up to 20 results. If the inbox is clean, say so and stop.

## Step 2 — Classify Each Email

Read enough of each message (subject, sender, snippet) to classify it into exactly one tier:

| Tier | Criteria |
|------|----------|
| **skip** | newsletters, noreply@, automated alerts, marketing, notifications with no action needed |
| **info_only** | CC'd messages, receipts, shipping updates, announcements, FYI threads |
| **meeting_info** | contains meeting links (Zoom/Meet/Teams), calendar invites, date/time proposals |
| **action_required** | direct question addressed to the user, request for something, scheduling ask, anything needing a response |

For ambiguous cases: if it smells like someone wants something from Will → `action_required`. When in doubt, err toward action_required over skip.

## Step 3 — Handle Each Tier

**skip:** Note the sender and subject. No further action needed — just list them.

**info_only:** Write a single-line summary. Max 15 words. Sender + what it's about.

**meeting_info:** Read the full message with `mcp__claude_ai_Gmail__gmail_read_message`. Extract: who called the meeting, date/time/timezone, link or location, any prep required. Flag any conflicts if you can infer them.

**action_required:** Read the full message. Draft a reply that Will can send as-is or lightly edit. Keep it brief, match the tone of the original (casual vs. formal). Present the draft clearly labeled.

## Step 4 — Triage Report

Present the full report in this format:

```
## Email Triage — [date]
[N] emails processed

### ACTION REQUIRED ([count])
**From:** [sender] | **Subject:** [subject]
**Summary:** [1-2 sentence summary of what they need]
**Draft reply:**
> [drafted reply text]

---

### MEETING INFO ([count])
**From:** [sender] | **Subject:** [subject]
- When: [date/time/tz]
- Where/Link: [location or URL]
- Notes: [any prep or conflicts]

---

### INFO ONLY ([count])
- [Sender] — [one-line summary]
- [Sender] — [one-line summary]

---

### SKIPPED ([count])
- [Sender] — [subject] (reason: newsletter / noreply / automated)
```

## Step 5 — Telegram Notification

After the report, output a compact Telegram-ready summary:

```
📬 Triage done — [N] emails
🔴 Action required: [count]
🟡 Meeting info: [count]
🔵 Info only: [count]
⚪ Skipped: [count]
[List action-required subjects, one per line]
```

Will can copy/paste this or you can send it via the Telegram bot if he asks.

## Notes

- Never mark emails as read or archive anything without Will explicitly saying so.
- If Gmail MCP isn't authenticated, tell Will and stop — don't guess at email content.
- Keep the report scannable. Will reads this fast.

---
name: idea
description: Add ideas to the user's Empire Ideas Board on NAS. Quick capture for brainstorms, business ideas, content concepts, tool discoveries, or anything the user wants to remember and act on later.
user_invocable: true
trigger: /idea
---

# /idea — Empire Ideas Board

## What This Does
Captures ideas to `~/projects/_drafts/creative/ideas/IDEAS.md` — the user's master ideas backlog.

## How To Use

When Will triggers `/idea` or says "add this to the list", "idea:", "remember this idea", "put this on the board":

1. Parse what the user said into a clear, actionable idea
2. Categorize it:
   - **Media Properties** — YouTube channels, websites, podcasts, content brands
   - **Revenue Streams** — Money-making concepts, services, products
   - **Tools & Infrastructure** — MCP servers, skills, subagents, hardware
   - **Creative** — Specific content pieces, series concepts, one-off projects
3. Read `~/projects/_drafts/creative/ideas/IDEAS.md`
4. Add the idea as a new `- [ ]` checkbox item under the right category header
5. If the category doesn't exist, create it under `## Active Ideas`
6. Add a bold title and a one-line description
7. Update the `*Last updated:*` line at the bottom
8. Confirm to the user with the idea title and category

## Format
```markdown
- [ ] **Bold Title** — One-line description of the idea
```

## Multiple Ideas
If Will dumps multiple ideas at once, add them all. Don't ask one at a time.

## Quick Mode
If Will just says `/idea niche-topic animated shorts channel` — don't ask questions, just parse it, categorize it, add it, confirm.

## Viewing The Board
If Will says "show me the list", "what's on the board", "ideas list" — read and display the full IDEAS.md.

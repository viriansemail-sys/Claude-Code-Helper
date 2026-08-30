---
name: session-report
description: Write an end-of-session productivity report to the central NAS spot for weekly social-post synthesis. Captures shipped artifacts, decisions, file counts, and produces ready-to-post snippets (LinkedIn / X / Instagram). Run at end of any session on any node.
---

# Session Productivity Report

End-of-session report writer. Produces ONE consolidated, well-formatted productivity report at a central NAS location so it can be synthesized later into social posts and visuals.

**Trigger:** `/session-report` at the end of any Claude Code session, on any node.

**Output:** ONE file at `~/archive/productivity/<ISO-YEAR-Wxx>/<YYYY-MM-DD>_<hostname-lowercase>_<SLUG>/README.md` — that path keeps the node-a `.md`-must-be-README hook happy.

---

## What to do

### STEP 1 — Gather facts (do not guess; "unknown" is acceptable, hand-waving is not)

- `hostname` → the node this ran on (lowercase in path)
- `date +%G-W%V` → ISO week (e.g. `2026-W22`)
- `date +%Y-%m-%d` → today
- Session topic → 1-5 words, kebab-case → SLUG
- Files created/modified: prefer `~/data/logs/virian_file_writes.jsonl` filtered to today + this hostname; fall back to your own tool-use history. Use ABSOLUTE paths.
- Services / containers touched: `~/data/logs/virian_docker_audit.jsonl`, today + hostname.
- SSH targets touched: `~/data/logs/virian_ssh_audit.jsonl`, today + hostname.
- Git activity, if any repos were touched: `cd <repo>; git log --since=midnight --oneline`.
- Decisions: extract anything "locked," "approved," "decided," or an ADR from the conversation.
- Artifacts SHIPPED: standards, workflows, scripts/tools, packets/visuals, models, services. Each with absolute path.
- 1-3 HIGHLIGHTS — wins worth bragging about. Specific, concrete, named, with a number.

### STEP 2 — Write to this EXACT path

```
~/archive/productivity/<ISO-YEAR-Wxx>/<YYYY-MM-DD>_<hostname-lowercase>_<SLUG>/README.md
```

`mkdir -p` the folder first.

### STEP 3 — Report contents (use this template VERBATIM; fill every field; "none" is acceptable; render-quality Markdown — proper hierarchy, scannable, no walls of text)

```markdown
---
date: YYYY-MM-DD
iso_week: YYYY-Wxx
node: <hostname>
slug: <session-slug>
topic_title: <human-readable session title>
duration_estimate: "~Nh"
posture: build | design | debug | research | ops | mixed
counts:
  files_created: <int>
  files_modified: <int>
  artifacts_shipped: <int>
  decisions_locked: <int>
  services_touched: <int>
  ssh_targets: <int>
  git_commits: <int>
---

# <Topic Title>

> **<Headline — one sentence, post-ready, lead with the verb or the number. No fluff.>**

## Numbers at a glance

| Files | Artifacts | Decisions | Services | SSH | Commits |
|------:|----------:|----------:|---------:|----:|--------:|
|  N    |    N      |    N      |    N     |  N  |   N     |

## Shipped — proof of work

- **<name>** — `<absolute path>` — what it is in one phrase.
- **<name>** — `<absolute path>` — what it is in one phrase.

## Decisions locked

1. <decision in one tight line>
2. <decision in one tight line>

## Highlight reel

- **<headline phrase>** — the concrete, specific, brag-worthy moment with a number or a name.

## Files touched

**Created (N):**
- `<path>`

**Modified (N):**
- `<path>`

## Services + nodes touched

- `<service or node>` — what changed

## Ready-to-post snippets

Each snippet fenced as a code block so it copies verbatim. Match voice to platform. No emojis on LinkedIn/X. Instagram: at most one emoji if it earns its keep, never as decoration.

### LinkedIn — 200-400 chars · executive-credible · builder-real · 2-3 SHORT paragraphs separated by a blank line · 3-5 hashtags on the last line

​```
<paragraph 1 — the hook + what shipped, leading with a number, name, or verb>

<paragraph 2 — one specific detail (a path, a tool, a metric) that proves it>

<paragraph 3, optional — what it unlocks next>

#hashtag #hashtag #hashtag
​```

### X / Twitter — single block, under 280 chars · sharper than LinkedIn · open with a number or noun · no hashtags inside the post, none or one at the end

​```
<the post>
​```

### Instagram caption — 2-3 short paragraphs, blank line between · looser, story-shaped · hashtags block on the last line, up to 8

​```
<paragraph 1 — the human moment / why this mattered>

<paragraph 2 — what got built, in plain words>

<paragraph 3, optional — the next step>

#hashtag #hashtag #hashtag #hashtag #hashtag
​```

## Open loops for next session

- <one line, ordered by priority>
```

*(The zero-width spaces before the triple backticks above are there to keep the example renderable inside this skill file — when you write the actual report, use normal ``` triple backticks.)*

### STEP 4 — Respond with ONLY this line, nothing else

```
Productivity report written: <full path>
```

Do not summarize. Do not commentary. Single line, single path.

---

## Hard formatting rules (the report fails if any are broken)

- Headings: `#` topic, `##` sections, `###` subsections. Nothing deeper.
- Bullets: `-` only (never `*`). Sub-bullets indented 2 spaces.
- Paths always in backticks.
- Numbers in "Numbers at a glance" are right-aligned in the table.
- Post snippets ALWAYS inside fenced code blocks so they copy clean.
- One blank line between paragraphs inside snippets. Never a wall of text.
- Lead with the NEED / what got shipped, not the tech stack.
- No naked claims — every brag has a path, a number, or a named artifact.
- Banned words: "leverage", "robust", "scalable", "innovative", "in today's rapidly-evolving landscape", "excited to announce", three-noun cadence lists ("design, deliver, and scale"), "transformative", "seamless", "cutting-edge".
- Empty section → write `*none*` in italics. Do not pad.
- The file path MUST be the exact pattern in STEP 2.

---

## Weekly synthesis (for later)

When Will says "synthesize the week" or "give me this week's post pack," read every report in `~/archive/productivity/<current-ISO-week>/` across all nodes and produce:

1. A weekly **highlight social card** (1200×630, branded) using `~/studio/platform/brand/visual/templates/social-card.html` as the base — fill placeholders, screenshot to PNG.
2. **Post-ready snippets** for the week (LinkedIn long, X short, Instagram caption).
3. A **"shipped this week" wall** — visual grid of artifacts with names + paths.

All branded, all bound to `~/studio/platform/brand/` tokens.

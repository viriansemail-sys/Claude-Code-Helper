---
name: product-idea
description: Entry point for the V-Corp Product Factory pipeline. Captures structured product ideas to ~/nas/pipeline/ideas/ and queues them for Kai's research cycle.
user_invocable: true
trigger: /product-idea
---

# /product-idea — V-Corp Product Factory

## What This Does
Captures a product idea into the pipeline at `~/nas/pipeline/ideas/` and registers it in `~/nas/pipeline/state.json` so Kai picks it up on her next research cycle.

## How To Use

When Will triggers `/product-idea` or includes an idea description as args:

### Step 1: Get the idea
- If args were provided, use them as the description.
- If no args, ask: "What's the product idea? Give me a one-liner or a paragraph — whatever you've got."

### Step 2: Parse into structured fields
From the description, extract or infer:
- **Title** — a short, punchy product name (2-5 words, title case)
- **Slug** — kebab-case version of the title (e.g., `bcba-study-app`)
- **Target Audience** — who this is for (infer from description; if genuinely unclear, ask)
- **Research Questions** — 3-5 questions that need answering before this can be built (infer from context; do NOT ask Will to supply these)

### Step 3: Create the idea file
Use the Write tool to create the file at:
```
~/nas/pipeline/ideas/YYYY-MM-DD_<slug>.md
```

Use today's date in YYYY-MM-DD format.

File contents:
```markdown
# Product Idea: <Title>

**Added:** YYYY-MM-DD
**Added by:** Will (Chairman)
**Status:** queued

## Description
<user's description, cleaned up but not over-edited>

## Target Audience
<inferred or provided>

## Revenue Potential
TBD — needs research

## Research Questions
- <question 1>
- <question 2>
- <question 3>
- <question 4 if applicable>
- <question 5 if applicable>
```

### Step 4: Update state.json
Read `~/nas/pipeline/state.json`. If it doesn't exist, start with this structure:
```json
{
  "ideas": [],
  "last_updated": ""
}
```

Add an entry to the `ideas` array:
```json
{
  "title": "<Title>",
  "slug": "<slug>",
  "file": "ideas/YYYY-MM-DD_<slug>.md",
  "added": "YYYY-MM-DD",
  "status": "queued"
}
```

Update `last_updated` to today's date. Write the file back.

### Step 5: Confirm
Reply:
> Idea queued: **<Title>**. Kai will pick it up on her next research cycle.

## Quick Mode
If Will says `/product-idea AI meal planning app for busy parents` — parse it, fill in all fields, write the files, confirm. No back-and-forth unless target audience is truly ambiguous.

## Multiple Ideas
If Will dumps multiple ideas at once, process them all. Create a separate file for each. Update state.json with all of them in one write.

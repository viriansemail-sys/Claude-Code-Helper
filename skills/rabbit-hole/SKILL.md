---
name: rabbit-hole
description: Stage 2 of the Pulse & Dig pipeline. Takes a sentiment-researcher (Pulse) report, finds the matching local case file/corpus entry, identifies what the file DOESN'T yet know vs the live conversation, deep-researches those gaps (web, cited), and UPDATES the case file with a clearly-separated, URL-cited research layer. Use after /sentiment-researcher, or standalone when Will says "dig into X and update the file", "rabbit hole this", "research the gaps". /rabbit-hole <topic-or-pulse-report-path>.
---

# /rabbit-hole — gap research that lands back in the file

Input: a Pulse report (or any named topic + a target file/corpus). Output: the case file UPDATED with new, verified, cited research — not a loose report that evaporates.

## Steps

1. **READ the Pulse** — the winner item, its identifiers, hooks, and claims circulating publicly.
2. **FIND the local file** — grep the relevant corpus/project for the case (for niche-topic: `~/data/rag_docs/research/niche-topic/_database/war-gov/niche-topic/` by report numbers first, keywords second; expect aliases — one story often spans several case folders; collect ALL of them).
3. **GAP ANALYSIS** — read the existing analysis.md/docs and diff against the live conversation: what does the internet know/claim/ask that the file doesn't cover? (new viral artifacts, named people, connected cases, official statements, debunks). List the gaps explicitly.
4. **DIG** — dispatch `deep-researcher` on the gaps ONLY (don't re-research what the file already grounds). Demand three trust tiers in the output: official record / community claims / enhanced-or-derived artifacts (e.g. AI-upscaled videos), every claim URL-cited.
5. **UPDATE THE FILE** — append to the case's `analysis.md` (or create `research-context.md` beside it if analysis is locked) following the analyze-niche-topic External Context convention: a clearly separated section, e.g.
   `## External Context — Live Research (YYYY-MM-DD, Pulse & Dig)` — never interleaved with the citation-grounded document analysis; every line URL-cited; trust tier labeled per claim; corrections/debunks included honestly. ADD-ONLY: never modify the existing source-grounded analysis. chmod 664 (NFS). If the story spans multiple case folders, cross-reference them in each update.
6. **REPORT** — what was added, to which files, the gaps that remain open (couldn't be verified), and a one-paragraph "what this means for the use case" (e.g. episode ammo).

## Hard rules
- ADD-ONLY on corpus files; the document-grounded analysis layer is sacred (uapgoddess law).
- Web claims NEVER masquerade as document content — the trust-tier separation is the whole point.
- Receipts on every claim; a gap that stays unverified is reported as OPEN, not papered over.

## Pipeline
`/sentiment-researcher <topic>` (Pulse) → `/rabbit-hole` (Dig) → domain use (e.g. episode build via the frozen recipe). Future: n8n port with local-AI research (project spec, not yet built — see project_pulse_and_dig.md).

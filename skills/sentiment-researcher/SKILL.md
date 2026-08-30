---
name: sentiment-researcher
description: Topic-agnostic web sentiment analysis — what is the internet saying about X RIGHT NOW, and what specific thing is getting the most attention? Sweeps Reddit, X/Twitter, news, YouTube, and niche community sources; returns a ranked report with hooks, sentiment (excited/skeptical/angry), buzz evidence, and URLs. Use when Will asks "what's everyone talking about re: X", "do a sentiment analysis on Y", "what's trending in Z", or when picking content/products/timing by live public conversation. /sentiment-researcher <topic>. Born 2026-07-13 (your example channel episode-picking; generalized on the user's order).
---

# /sentiment-researcher — live public-conversation analysis on any topic

Input: a TOPIC (+ optional angle, e.g. "which case from the July releases", "which feature complaints", "which competitor"). Output: a ranked sentiment report with a clear #1 and receipts. This skill measures the conversation; what to DO with the winner belongs to the caller.

## Phase 1 — SWEEP (dispatch `deep-researcher`, background)

Build the researcher prompt from the topic. Weight the last 7-14 days heavily (state today's date). Angles — adapt source list to the domain:

- **Reddit**: the topic's principal subreddits — top/hot posts, which specific items recur, upvote/comment magnitude.
- **X/Twitter**: viral threads/handles naming specific items; quote them where findable.
- **News + big YouTube creators**: mainstream/creator coverage this week; view counts where visible.
- **Niche community press/podcasts/forums** for the domain (e.g. niche-topic → Liberation Times/The Debrief; dev tools → HN/lobsters; consumer → TikTok/reviews).

Per candidate item capture: NAME + searchable identifiers, the HOOK driving the chatter (why THIS is hot — a video? a name? a scandal? a contradiction?), sentiment split (excited/skeptical/angry), relative buzz rank, source URLs. Require the researcher to distinguish items genuinely in scope from adjacent general news.

## Phase 2 — REPORT (main session)

Deliver Spock-simple: **ranked TOP 5 with a clear #1** — one line each: item, hook, sentiment, buzz evidence, best URL. Then one paragraph: what the conversation is really about (the meta-read: what people want/fear/mock). No fluff, no padding.

## Phase 3 — DOMAIN FOLLOW-UP (optional, caller-owned)

If the caller needs the winner matched against local reality, do that as a separate step with disk/API truth. Worked example — **your example channel episode picking** (the founding use): match the #1 case against `~/data/rag_docs/research/niche-topic/_database/war-gov/niche-topic/` for real assets (videos/PDFs/analysis) AND run the two-layer consumption check (folder markers + content-hash vs every shipped episode's sources — the Ep09/Ep28 alias-dup lesson, 2026-07-12) before recommending it for production.

## Hard rules
- Receipts or it didn't happen: every ranked item carries URLs.
- Buzz is measured, never invented — if the sweep finds no clear leader, say so.
- Sentiment ≠ endorsement: report the skeptics/anger honestly; that's often the hook.

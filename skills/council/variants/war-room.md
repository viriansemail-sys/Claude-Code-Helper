# Variant — War Room

**Bias:** Executor-led. Used when the strategic question is mostly settled and the real question is *how do we ship this fast?*

## How this variant differs from default council

- Still dispatch all 5 advisors in parallel.
- The Executor's verdict drives the recommendation.
- The Contrarian's role narrows: they only flag *operational* risks (things that will break execution), not strategic risks. Strategic critique is out of scope here — that decision was already made.
- First Principles is muted unless they spot that the *operational* question is the wrong one (e.g., "you're optimizing for speed but the real constraint is quality").
- Expansionist becomes "what's the minimum that captures the upside" rather than "what's the maximum upside."
- Outsider stays as-is — they often catch operational dumbness experts are blind to.
- The synthesis ends in a **plan with dates**, not a discussion.

## Synthesis structure (overrides default)

```markdown
# War Room — <slug>

**The decision (assumed settled):** <one paragraph — what we are doing, not whether to do it>

## The plan
<numbered steps. Each step: action, owner, deadline, definition of done. Critical path marked.>

## Ship this week
<the smallest thing that gets to first contact with reality. The thing that happens before everything else.>

## Operational risks (where this breaks in the real world)
<2-3 specific failure modes during execution. Capacity, handoffs, tool gaps, dependencies. Each gets a mitigation.>

## What we are explicitly NOT doing
<scope cuts. The features, polish, edge cases that are deferred. Naming them prevents scope creep.>

## Decision points
<future moments where we re-evaluate. "After step 3, decide whether to X." Concrete triggers.>

## The recommendation
<one sentence: "start with step 1 today, ship by date Y, re-evaluate at milestone Z.">

---

## The five voices (verbatim)
[same as default]
```

## When NOT to use war-room

- When the strategic question is *not* settled. War-roomming an undecided idea just produces fast motion in the wrong direction.
- When the user is asking "should I?" rather than "how do I?". Use default `/council`.
- When the timeline is already comfortable. War-room mode is for "we need to move now" — not for routine planning.

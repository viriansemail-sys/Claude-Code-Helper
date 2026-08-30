# Variant — Debate

**Format:** 2v2 with a referee. Used for binary decisions where the user wants to hear the strongest case for each side, not five independent takes.

## How this variant differs from default council

- Still real parallel dispatch (no inline persona-switching).
- The 5 advisors are split into **two camps + a referee**:
  - **Pro side (build the case FOR):** Expansionist + First Principles
  - **Con side (build the case AGAINST):** Contrarian + Outsider
  - **Referee:** Executor — judges feasibility-of-each-side and breaks ties on action
- Each advisor is told *which side they're on* and to argue that side as strongly as honesty allows. They do not pretend a position they don't believe — they make the strongest version of their assigned side's argument.
- The Executor as referee reads both sides' returns and answers: "given both arguments, what is the executable next step, and which side wins on the action question?"

## Wait — doesn't telling them which side to take violate independence?

Yes, partially. That's the trade-off. Debate mode trades independence for sharper opposition. Use it when you specifically want **the strongest case for each side argued cleanly**, not when you want unfiltered independent views (use default `/council` for that).

## Dispatch instructions

Pass each advisor:
- Their persona file
- The framed question
- **An additional instruction:** "You are arguing the [PRO / CON] side. Build the strongest honest case for your side. Do not steelman the other side — that's their job. If you genuinely cannot argue this side, say so and the referee will note it."
- Pro side gets: "argue why the user should DO this."
- Con side gets: "argue why the user should NOT do this, or should do something materially different."

The Executor (referee) is dispatched **after** the other 4 return, with their full transcripts:
- "You are the referee. Read both sides' arguments. Decide: which side made the stronger executable case? What is the next concrete step regardless of who 'won'? Where did both sides agree, even implicitly?"

This means debate mode is the one variant where dispatch is **NOT fully parallel** — the 4 debaters fire in parallel, then the Executor fires after.

## Synthesis structure (overrides default)

```markdown
# Debate — <slug>

**The binary question:** <one sentence — "do X or do Y" / "ship now or wait" / "raise prices or hold">

## The PRO case
<combined argument from Expansionist + First Principles. 2-3 paragraphs. The strongest honest case for doing it.>

## The CON case
<combined argument from Contrarian + Outsider. 2-3 paragraphs. The strongest honest case against (or for the alternative).>

## Where both sides actually agree
<the unstated common ground. Often this is where the real answer lives — both sides agree on something the user hasn't noticed.>

## The referee's call
<the Executor's verdict. Which side made the stronger executable case, what the next step is, what would change the call.>

## The recommendation
<one sentence. Pick a side, or pick the synthesis that both sides actually support.>

---

## The four voices (verbatim)

### PRO — Expansionist
<full agent return>

### PRO — First Principles
<full agent return>

### CON — Contrarian
<full agent return>

### CON — Outsider
<full agent return>

### REFEREE — Executor
<full agent return>
```

## When NOT to use debate

- When the question isn't binary. Debate mode forces a false dichotomy on a multi-option decision. Use default `/council`.
- When you want unfiltered independent views (debate constrains advisors to a side).
- When the "sides" aren't symmetric in stakes. If one side is "huge upside" and the other is "small downside," debate mode wastes the asymmetry. Use `/council` or lean Expansionist.

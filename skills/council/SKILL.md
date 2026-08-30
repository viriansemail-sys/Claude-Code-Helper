---
name: council
description: Convene a council of five independent advisors to pressure-test a decision. Each advisor attacks the question from a different angle (Contrarian, First Principles, Expansionist, Outsider, Executor) via real parallel subagent dispatch — they cannot hear each other, which forces genuine independence instead of sycophantic agreement. Use for pricing decisions, pivot-or-stay, copy critique, hire-vs-automate, positioning angles, strategic crossroads. Do NOT use for factual lookups, writing tasks, summaries, or simple yes/no questions.
---

# The Council

> "Don't ask one yes-man. Convene a council of five."

Inspired by Charlie Hills / Ole Lehman. The point of the council is **independence**: five advisors who cannot hear each other, then a Chairman synthesizes where they agree, where they clash, what nobody saw, and what to actually do.

## When to invoke

**Council this:**
- Pricing decisions
- Pivot or stay
- Copy critique
- Hire vs automate
- Positioning angles
- Any decision where you'd otherwise just hear yourself agree with yourself

**Don't council this** (refuse and say why):
- Factual lookups ("what's the GPU temp?")
- Writing tasks ("write me an email")
- Summaries ("summarize this doc")
- Simple yes/no with a clear answer
- Anything where one good search beats five opinions

## How it runs

**Real parallel dispatch — non-negotiable.** The whole value is that advisors form their views without hearing each other. Inline persona-switching contaminates them. Use the `Agent` tool with `subagent_type: general-purpose`, all 5 in a single message so they run concurrently.

### Step 1 — Gate check

If the question fails the "council this" criteria, refuse: explain in one sentence why this isn't a council question, and suggest the right tool (web search, direct answer, /brainstorm, etc.).

### Step 2 — Frame the question

Before dispatch, restate the question in one tight paragraph. Include:
- The decision being made
- Relevant constraints (budget, timeline, audience, prior commitments)
- What "good" looks like (the success criterion)

This frame goes to every advisor verbatim. Don't editorialize it — the advisors need clean input.

### Step 3 — Parallel dispatch (5 agents, ONE message)

Read `advisors/contrarian.md`, `advisors/first-principles.md`, `advisors/expansionist.md`, `advisors/outsider.md`, `advisors/executor.md`. Each file is the system prompt for that advisor.

Dispatch all 5 in a single message with multiple `Agent` tool calls. Each agent receives:
- Their persona prompt (full advisor file content)
- The framed question
- Instruction to return a structured verdict (lens, tension, verdict)

**CRITICAL:** Do not summarize the persona files when passing to the agent. Pass the full content. Their distinct voice depends on it.

### Step 4 — Synthesize the Chairman's Verdict

After all 5 return, write the verdict in this structure:

```markdown
# Chairman's Verdict — <slug>

**Question:** <one paragraph>

## Where the council agrees
<the strongest signal: which problem did 2+ advisors flag independently? That's where the truth probably is.>

## Where the council clashes
<the most productive disagreement. Name the two positions, explain the underlying tension, propose a resolution (often: sequence them, or pick based on a constraint).>

## Blind spots the council caught
<things only one advisor saw — especially the Outsider. These are usually the surprise wins.>

## The recommendation
<one specific, time-bounded action. Not "consider X" — "do X by Y." If the council can't recommend confidently, say so and name what would unblock the call.>

---

## The five voices (verbatim)

### 01 // Contrarian
<full agent return>

### 02 // First Principles
<full agent return>

### 03 // Expansionist
<full agent return>

### 04 // Outsider
<full agent return>

### 05 // Executor
<full agent return>
```

### Step 5 — Save to NAS

Per the user's "full reports to NAS" rule: save the full verdict to `~/projects/council/YYYY-MM-DD_<slug>.md`. Create the directory if it doesn't exist. Give Will the path + a 3-line summary in chat (question, recommendation, biggest clash).

## Variants

Same engine, different bias. Read the variant file when the user invokes one of these:

- `/council` — balanced, all 5 advisors equal weight (default, no variant file)
- `/pressure-test` — Contrarian-heavy, see `variants/pressure-test.md`
- `/war-room` — Executor-led, see `variants/war-room.md`
- `/debate` — 2v2 structured debate, see `variants/debate.md`

## Synthesis rules — read these every time

1. **Don't average the advisors.** If three say A and two say B, that's not "lean toward A." It's a clash that needs resolution. Name it.
2. **The Outsider almost always finds the real blind spot.** Weight that voice when it disagrees with the experts.
3. **The Executor breaks ties when timing is the constraint.** Slow-but-right loses to fast-and-good when the window is closing.
4. **First Principles overrules everyone when the question itself is wrong.** If they reframe the question, lead with the reframe.
5. **No diplomatic mush.** "It depends" is not a verdict. Pick something. If genuinely undecidable, say what info would decide it.
6. **Quote the advisors directly in the synthesis when their phrasing is sharp.** Don't sand off their edges.

## Output discipline

- Chat reply: ≤ 8 lines (path to NAS file, the recommendation, the biggest clash). Will reads the full file when he wants depth.
- NAS file: full verdict + all 5 voices verbatim. This is the asset.
- Slug: lowercase-kebab-case from the question, max 6 words.

## Anti-patterns

- ❌ Asking the user clarifying questions before dispatch unless the frame is genuinely incoherent. The advisors can ask their own questions in their returns.
- ❌ Inline persona-switching ("now I'll think as the Contrarian..."). That defeats the entire point. Real parallel agents only.
- ❌ Letting agents see each other's outputs mid-flight. They form independent views, then the Chairman synthesizes.
- ❌ Padding the synthesis with "great question!" energy. The Chairman is terse.
- ❌ Recommending five things. One recommendation. Maybe two if sequenced.

---
name: viability-eval
description: Evaluate a product research packet for viability. Scores market size, competition, build effort, and revenue potential. Outputs BUILD/PASS/REVISIT decision.
user_invocable: false
---

# Viability Evaluation Skill

Used by the assistant to evaluate research packets from Kai. This is the gate between research and design.

## Process

1. Read the research packet from ~/nas/pipeline/researched/
2. Score each dimension 1-10:
   - **Market Size** — How big is the addressable market?
   - **Competition** — How crowded? Do we have a unique angle?
   - **Build Effort** — How hard to build with our stack?
   - **Revenue Potential** — What can this realistically earn monthly?
   - **Strategic Fit** — Does this align with V-Corp mission and the user's expertise?

3. Calculate overall score (weighted average):
   - Market Size: 20%
   - Competition: 15%
   - Build Effort: 20%
   - Revenue Potential: 30%
   - Strategic Fit: 15%

4. Decision rules:
   - Score >= 7.0 → **BUILD** — move to ~/nas/pipeline/designing/
   - Score 5.0-6.9 → **REVISIT** — move to ~/nas/pipeline/future-research/ with notes
   - Score < 5.0 → **PASS** — move to ~/nas/pipeline/archive/ with reason

5. Write evaluation report to the same folder as the research packet with suffix `-eval.md`

6. Update ~/nas/pipeline/state.json accordingly

## Evaluation Report Template

```markdown
# Viability Evaluation: <Product Name>
**Date:** YYYY-MM-DD
**Evaluator:** the assistant (CEO)
**Research by:** Kai

## Scores
| Dimension | Score | Notes |
|-----------|-------|-------|
| Market Size | X/10 | |
| Competition | X/10 | |
| Build Effort | X/10 | |
| Revenue Potential | X/10 | |
| Strategic Fit | X/10 | |
| **Overall** | **X.X/10** | |

## Decision: BUILD / REVISIT / PASS

## Reasoning
<3-5 sentences>

## Next Steps
<if BUILD: what the design phase should focus on>
<if REVISIT: what needs to change before reconsidering>
<if PASS: why this is dead>
```

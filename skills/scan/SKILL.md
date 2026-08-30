---
name: scan
description: Scan for options setups. Will gives criteria (earnings plays, high IV, unusual volume, breakouts, sector) and the assistant searches for matching tickers. Returns a shortlist of actionable setups. Use when Will says "/scan", "find me something", "what's moving", or "scan for [criteria]".
---

# 🔎 SCAN — Options Setup Scanner

## Usage
`/scan [criteria]`

Examples:
- `/scan high IV earnings this week`
- `/scan tech breakouts`
- `/scan unusual options volume today`
- `/scan` (no criteria = general "what looks good right now")

## How to scan

### Step 1: Determine criteria
If Will gave criteria, use them. If not, default scan:
- Stocks with unusual options volume (2x+ average)
- Near key technical levels (52-week high/low, major support/resistance)
- Earnings within 5 days
- High IV rank (>70%) for premium selling, or low IV rank (<30%) for buying

### Step 2: Source candidates
Use available tools in this order:
1. **Alpaca MCP** — most active options, top movers
2. **Web search** — "unusual options activity today", "stocks breaking out today", sector movers
3. **TradingView MCP** (if installed) — technical screening
4. **yfinance MCP** (if installed) — options chain scanning

### Step 3: Filter to 3-5 candidates
Don't give Will 20 tickers. Give him **3-5 of the best** with a one-line reason each.

### Step 4: Present as a shortlist

```
SCAN: [criteria or "general"]
DATE: [today]

1. TICKER @ $price — [one-line reason: "breaking 52-week high, IV low, calls cheap"]
2. TICKER @ $price — [one-line reason: "earnings Thursday, IV at 90th percentile, straddle play"]
3. TICKER @ $price — [one-line reason: "unusual call volume 5x average at $X strike"]
```

Then ask: "Want me to analyze any of these?"

## Rules
- Quality over quantity. 3 good setups > 10 mediocre ones.
- Every candidate needs a REASON. No "here's what's moving" without a thesis.
- Flag if the market is choppy/directionless — sometimes the best scan result is "nothing clean today, stay cash."
- the user's style: breakouts, momentum, support/resistance. Weight those setups higher.

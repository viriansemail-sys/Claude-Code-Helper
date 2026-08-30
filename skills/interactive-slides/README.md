# interactive-slides

A Claude Code skill for creating interactive, animated web presentations — with 10 curated style presets, brand kit support, visual style discovery, a structured 6-phase workflow, and one-click fully-editable PowerPoint export.

## What it does

Turns your content into a beautiful, self-contained HTML file that opens in any browser. Not a PowerPoint — something alive: animated, polished, and web-native. And when you need to hand it off or edit the text directly, export to a fully editable `.pptx` in seconds.

**You get:**
- A structured discovery workflow (audience → brand/style → outline → build → PPT export)
- Brand kit support — bring your own colors, fonts, logo, PPT template, or Canva export
- 10 hand-crafted visual presets to choose from if you don't have a brand kit
- Three presentation modes: Slide Deck, Scroll Story, or Interactive Deck
- Full navigation support: keyboard, click, touch, swipe, scroll wheel
- GSAP animations, Google Fonts, Chart.js — all via CDN, no setup needed
- Editable `.pptx` export via pptxgenjs — all text editable in PowerPoint

## Installation

### Requirements
- [Claude Code](https://claude.ai/code) CLI installed
- Node.js + `pptxgenjs` installed globally (for PPT export only):
  ```bash
  npm install -g pptxgenjs
  ```

### Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/sylvial928/interactive-slides.git
   ```

2. Copy the skill files into your Claude Code skills directory:
   ```bash
   cp -r interactive-slides/ ~/.claude/skills/interactive-slides/
   ```

3. That's it. Restart Claude Code (or start a new session) and the skill will be available.

### Verify it's installed

In Claude Code, type:
```
/interactive-slides
```
Or just ask: *"Create an interactive presentation about X"* — Claude will automatically pick up the skill.

## Usage

Just describe what you want:

> "Create an interactive presentation for our Q1 investor update"

> "Turn this PDF into an interactive web deck"

> "Make a scroll-based story about our product roadmap"

Claude will walk you through discovery (audience, goal, delivery mode), ask about your brand kit or show style presets, confirm the slide structure, then build. After approval, it will offer a `.pptx` export.

### Using a brand kit

At the start of every session, Claude will ask:

> *"Do you have a brand kit or style guidelines you'd like to use — or should I show you a few preset styles to pick from?"*

You can share any of the following (one is enough):

| Input | How |
|-------|-----|
| Hex colors + font names | Paste directly: `"primary: #2B4EFF, body font: Helvetica Neue"` |
| Logo | File path or URL |
| PPT template | Share the `.pptx` file path |
| Canva Brand Kit | Brand Kit → copy hex colors, or Share → Download → PowerPoint |

Brand colors are applied to both the HTML presentation and the PPT export.

### Exporting to PowerPoint

After the HTML is approved, Claude will offer:

> *"Would you like an editable .pptx version? All text will be directly editable in PowerPoint."*

This generates a `build-deck.js` script and runs it to produce a `.pptx` file in the same directory. No manual steps required.

## File structure

```
SKILL.md            # Main skill prompt and 6-phase workflow
STYLE_PRESETS.md    # 10 visual presets with CSS variables and font pairings
evals/              # Evaluation cases for testing skill quality
```

## License

MIT — see [LICENSE](LICENSE)

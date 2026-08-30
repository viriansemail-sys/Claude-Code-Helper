---
description: Roll up the current ISO week's completions into a markdown report, brand-bound HTML, and a 1200x630 social card.
allowed-tools: Bash, Read, Write
---

# /weekly-rollup

Counts everything Will shipped this ISO week and emits three files into
`~/projects/project-portfolio/portfolios/will/completions/_weekly/`:

1. `<year>-W<week>-rollup.md` — frontmatter + grouped completion list
2. `<year>-W<week>-rollup.html` — brand-bound visual (motifs, tokens.css, wordmark, --grad)
3. `<year>-W<week>-social.html` — 1200x630 social card for posting

Hard rules:
- Brand: bind `~/studio/platform/brand/visual/tokens.css`, inline honeycomb (10% bottom-right) + circuit-board (20% top), wordmark in header, `<span class="g">` on key phrase.
- Voice: Built / Shipped / Logged / Counted / Rolled up. No "leverage", "robust", "seamless", "synergize", etc.
- Visual must answer "what am I looking at" — title + subtitle + reading instructions + labeled legend.
- Mixed sentence length. Numbers first.

## Execution

### Step 1 — Resolve the week and gather entries

```bash
set -euo pipefail

DATA_ROOT="~/projects/project-portfolio/portfolios/will/completions"
WEEKLY_DIR="$DATA_ROOT/_weekly"
mkdir -p "$WEEKLY_DIR"

# ISO week per `man date`: %G = ISO year, %V = ISO week (01-53)
ISO_YEAR=$(date +%G)
ISO_WEEK=$(date +%V)
WEEK_TAG="${ISO_YEAR}-W${ISO_WEEK}"

# Monday and Sunday of current ISO week
# Note: GNU date 9.4 rejects "%G-W%V-1" parsing — compute from day-of-week instead
MONDAY=$(date -d "today -$(($(date +%u)-1)) days" +%Y-%m-%d)
SUNDAY=$(date -d "$MONDAY + 6 days" +%Y-%m-%d)

echo "Week: $WEEK_TAG  ($MONDAY → $SUNDAY)"
echo "Scanning: $DATA_ROOT"

export DATA_ROOT WEEKLY_DIR ISO_YEAR ISO_WEEK WEEK_TAG MONDAY SUNDAY
```

### Step 2 — Parse frontmatter and emit all three files

Python does the YAML parse, counting, and templating. One pass, three writes.

```bash
python3 <<'PY'
import os, re, glob, datetime, html as h
from pathlib import Path

DATA_ROOT = Path(os.environ["DATA_ROOT"])
WEEKLY_DIR = Path(os.environ["WEEKLY_DIR"])
WEEK_TAG = os.environ["WEEK_TAG"]
ISO_YEAR = os.environ["ISO_YEAR"]
ISO_WEEK = os.environ["ISO_WEEK"]
MONDAY = datetime.date.fromisoformat(os.environ["MONDAY"])
SUNDAY = datetime.date.fromisoformat(os.environ["SUNDAY"])

TYPES = ["hive-asset", "workflow", "custom-flow", "project",
         "bug-fix", "infrastructure", "content"]

def parse_frontmatter(text):
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n?", text, re.DOTALL)
    if not m:
        return {}, text
    fm_raw = m.group(1)
    body = text[m.end():]
    fm = {}
    cur_key = None
    for line in fm_raw.splitlines():
        if not line.strip():
            continue
        if line.startswith(("  -", "- ")):
            cur_key and fm.setdefault(cur_key, []).append(line.split("-",1)[1].strip())
            continue
        if ":" in line and not line.startswith(" "):
            k, _, v = line.partition(":")
            k = k.strip(); v = v.strip()
            if v == "":
                cur_key = k
                fm[k] = []
            else:
                cur_key = None
                fm[k] = v
    return fm, body

# Collect every completion .md whose folder date falls in [MONDAY, SUNDAY]
entries = []
for day in (MONDAY + datetime.timedelta(n) for n in range(7)):
    folder = DATA_ROOT / day.isoformat()
    if not folder.is_dir():
        continue
    for md in sorted(folder.glob("*.md")):
        text = md.read_text(encoding="utf-8")
        fm, body = parse_frontmatter(text)
        if not fm:
            continue
        entries.append({
            "slug": fm.get("slug", md.stem),
            "title": fm.get("title", md.stem),
            "type": fm.get("type", "project"),
            "shipped": fm.get("shipped", day.isoformat()),
            "hive_slug": fm.get("hive_slug", "null"),
            "asset_path": fm.get("asset_path", "null"),
            "path": str(md),
            "rel_path": os.path.relpath(md, WEEKLY_DIR),
            "body": body.strip(),
        })

total = len(entries)
by_type = {t: [e for e in entries if e["type"] == t] for t in TYPES}
counts = {t: len(by_type[t]) for t in TYPES}

# ---------- Markdown rollup ----------
md_lines = []
md_lines.append("---")
md_lines.append(f"week: {WEEK_TAG}")
md_lines.append(f"year: {ISO_YEAR}")
md_lines.append(f"iso_week: {ISO_WEEK}")
md_lines.append(f"monday: {MONDAY.isoformat()}")
md_lines.append(f"sunday: {SUNDAY.isoformat()}")
md_lines.append(f"total: {total}")
md_lines.append("by_type:")
for t in TYPES:
    md_lines.append(f"  {t}: {counts[t]}")
md_lines.append("---")
md_lines.append("")
md_lines.append(f"# Week {ISO_WEEK} Completions — {MONDAY} to {SUNDAY}")
md_lines.append("")
md_lines.append(f"Built for your fleet. Shipped **{total}** thing(s) this week.")
md_lines.append("")
md_lines.append("## Counts by type")
md_lines.append("")
md_lines.append("| Type | Count |")
md_lines.append("|------|------:|")
for t in TYPES:
    md_lines.append(f"| {t} | {counts[t]} |")
md_lines.append(f"| **total** | **{total}** |")
md_lines.append("")
md_lines.append("## Completions")
md_lines.append("")
if total == 0:
    md_lines.append("_Nothing logged this week._")
else:
    for t in TYPES:
        items = by_type[t]
        if not items:
            continue
        md_lines.append(f"### {t} ({len(items)})")
        md_lines.append("")
        for e in items:
            link = f"[{e['title']}]({e['rel_path']})"
            tail = []
            if e["hive_slug"] not in ("null", "", None):
                tail.append(f"hive:`{e['hive_slug']}`")
            if e["asset_path"] not in ("null", "", None):
                tail.append(f"`{e['asset_path']}`")
            suffix = " — " + " · ".join(tail) if tail else ""
            md_lines.append(f"- {e['shipped']} · {link}{suffix}")
        md_lines.append("")

md_path = WEEKLY_DIR / f"{WEEK_TAG}-rollup.md"
md_path.write_text("\n".join(md_lines), encoding="utf-8")

# ---------- HTML rollup (brand-bound, responsive) ----------
TOKENS = "~/studio/platform/brand/visual/tokens.css"
WORDMARK = "~/studio/platform/brand/visual/logo/wordmark.svg"
HONEY = "~/studio/platform/brand/visual/motifs/honeycomb.svg"
CIRCUIT = "~/studio/platform/brand/visual/motifs/circuit-board.svg"
now_iso = datetime.datetime.now().isoformat(timespec="seconds")

def card_html(e):
    chips = []
    if e["hive_slug"] not in ("null", "", None):
        chips.append(f'<span class="chip g">hive:{h.escape(e["hive_slug"])}</span>')
    chips.append(f'<span class="chip">{h.escape(e["type"])}</span>')
    chips.append(f'<span class="chip">{h.escape(e["shipped"])}</span>')
    # Pull first non-empty paragraph of body as one-liner
    one = ""
    for chunk in e["body"].split("\n\n"):
        s = chunk.strip()
        if s and not s.startswith("#"):
            one = s.split("\n")[0][:180]
            break
    return f"""
    <div class="card">
      <h3>{h.escape(e['title'])}</h3>
      <p>{h.escape(one)}</p>
      <div class="chips">{''.join(chips)}</div>
    </div>
    """

stat_strip = "".join(
    f'<div class="stat"><div class="stat-num">{counts[t]}</div>'
    f'<div class="stat-label">{t}</div></div>'
    for t in TYPES
)

cards_blocks = []
for t in TYPES:
    if not by_type[t]:
        continue
    cards_blocks.append(f'<h2 class="group-h">{t} <span class="count">({counts[t]})</span></h2>')
    cards_blocks.append('<div class="grid">')
    for e in by_type[t]:
        cards_blocks.append(card_html(e))
    cards_blocks.append('</div>')
cards_html = "\n".join(cards_blocks) if cards_blocks else '<p class="empty">Nothing logged this week.</p>'

html_doc = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Week {ISO_WEEK} Completions — {MONDAY} to {SUNDAY}</title>
<link rel="stylesheet" href="file://{TOKENS}">
<style>
  body {{ margin:0; background: var(--bg-deep); color: var(--cream);
         font-family: var(--font-sans, system-ui, sans-serif); }}
  .wrap {{ max-width: 1180px; margin: 0 auto; padding: 32px 24px 64px; position:relative; }}
  header.top {{ display:flex; align-items:center; justify-content:space-between; padding-bottom: 24px; border-bottom: 1px solid var(--line); }}
  header.top img {{ height: 24px; }}
  .eyebrow {{ font-size: 12px; letter-spacing: .28em; text-transform: uppercase;
              color: var(--accent); padding: 6px 14px; border:1px solid var(--line);
              border-radius: var(--radius-pill); background: rgba(255,209,102,.06); }}
  .hero {{ position: relative; padding: 56px 0 24px; overflow: hidden; }}
  .hero .circuit-bg {{ position:absolute; top:-40px; left:0; width:100%; opacity:.20; pointer-events:none; }}
  .hero .honeycomb-bg {{ position:absolute; bottom:-80px; right:-80px; width:360px; opacity:.10; pointer-events:none; }}
  h1.headline {{ font-size: clamp(36px, 6vw, 72px); line-height: 1; margin: 8px 0 12px; font-weight: 900; letter-spacing: -.02em; position:relative; z-index:2; }}
  h1 .g {{ background: var(--grad); -webkit-background-clip: text; background-clip: text; color: transparent; }}
  .sub {{ font-size: 20px; opacity: .88; max-width: 720px; position:relative; z-index:2; }}
  .read {{ margin-top: 20px; padding: 12px 16px; border: 1px dashed var(--line); border-radius: 12px; font-size: 13px; opacity: .8; position:relative; z-index:2; }}
  .read b {{ color: var(--accent); }}
  .big {{ display:flex; align-items: baseline; gap: 16px; margin: 36px 0 8px; }}
  .big .num {{ font-size: 96px; font-weight: 900; background: var(--grad);
               -webkit-background-clip: text; background-clip:text; color:transparent; line-height: 1; }}
  .big .label {{ font-size: 18px; opacity: .8; }}
  .stat-strip {{ display:grid; grid-template-columns: repeat(7, 1fr); gap: 10px; margin: 24px 0 40px; }}
  @media (max-width: 900px) {{ .stat-strip {{ grid-template-columns: repeat(3, 1fr); }} }}
  @media (max-width: 520px) {{ .stat-strip {{ grid-template-columns: repeat(2, 1fr); }} }}
  .stat {{ border: 1px solid var(--line); border-radius: 14px; padding: 14px 12px; background: rgba(255,255,255,.02); }}
  .stat-num {{ font-size: 28px; font-weight: 800; color: var(--accent); }}
  .stat-label {{ font-size: 11px; letter-spacing: .14em; text-transform: uppercase; opacity:.75; margin-top: 4px; }}
  .legend {{ border:1px solid var(--line); border-radius: 14px; padding: 14px 18px; margin: 24px 0 16px; font-size: 13px; line-height: 1.6; opacity:.85; background: rgba(255,255,255,.02); }}
  .legend b {{ color: var(--accent); }}
  h2.group-h {{ margin-top: 36px; font-size: 22px; border-bottom: 1px solid var(--line); padding-bottom: 8px; }}
  h2 .count {{ opacity:.6; font-weight: 400; font-size: 16px; }}
  .grid {{ display:grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-top: 16px; }}
  @media (max-width: 900px) {{ .grid {{ grid-template-columns: repeat(2, 1fr); }} }}
  @media (max-width: 600px) {{ .grid {{ grid-template-columns: 1fr; }} }}
  .card {{ border:1px solid var(--line); border-radius: 14px; padding: 16px; background: rgba(255,255,255,.02); }}
  .card h3 {{ margin: 0 0 8px; font-size: 16px; }}
  .card p {{ margin: 0 0 10px; font-size: 13px; opacity:.8; line-height: 1.5; }}
  .chips {{ display:flex; gap:6px; flex-wrap: wrap; }}
  .chip {{ font-size: 11px; padding: 4px 10px; border: 1px solid var(--line);
           border-radius: var(--radius-pill); background: rgba(255,209,102,.06); }}
  .chip.g {{ background: rgba(245,198,107,.14); border-color: rgba(245,198,107,.5);
             color: var(--accent); font-weight: 600; }}
  .empty {{ opacity:.6; font-style: italic; }}
  footer.bot {{ margin-top: 56px; padding-top: 16px; border-top: 1px solid var(--line); font-size: 12px; opacity: .6; }}
</style>
</head>
<body>
<div class="wrap">

  <header class="top">
    <img src="file://{WORDMARK}" alt="Hive AI">
    <span class="eyebrow">Weekly Rollup · {WEEK_TAG}</span>
  </header>

  <section class="hero">
    <img class="circuit-bg" src="file://{CIRCUIT}" alt="">
    <img class="honeycomb-bg" src="file://{HONEY}" alt="">
    <h1 class="headline">Week {ISO_WEEK} <span class="g">Completions</span></h1>
    <div class="sub">Built for your fleet. <b>{MONDAY}</b> to <b>{SUNDAY}</b>.</div>
    <div class="read"><b>How to read this:</b> big number = total shipped this week. The 7-cell strip below it counts by type. Each section underneath lists the actual items — one card per completion, with type chip, ship date, and hive slug if registered.</div>
  </section>

  <div class="big">
    <div class="num">{total}</div>
    <div class="label">things shipped this week</div>
  </div>

  <div class="stat-strip">{stat_strip}</div>

  <div class="legend">
    <b>Legend:</b> hive-asset = registered Hive pattern · workflow = repeatable build workflow · custom-flow = one-off automation · project = larger project ship · bug-fix = fix landed · infrastructure = node/network/storage change · content = published writing/visual/audio.
  </div>

  {''.join(cards_blocks) if cards_blocks else '<p class="empty">Nothing logged this week.</p>'}

  <footer class="bot">Generated {now_iso} · weekly-rollup · {WEEK_TAG}</footer>

</div>
</body>
</html>
"""

html_path = WEEKLY_DIR / f"{WEEK_TAG}-rollup.html"
html_path.write_text(html_doc, encoding="utf-8")

# ---------- 1200x630 social card ----------
top3 = entries[:3]
top3_html = "".join(
    f'<li>{h.escape(e["title"])}</li>' for e in top3
) or '<li style="opacity:.6">nothing this week</li>'

social = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{WEEK_TAG} Completions — Hive AI</title>
<link rel="stylesheet" href="file://{TOKENS}">
<style>
  html, body {{ margin:0; padding:0; width:1200px; height:630px; overflow:hidden; background: var(--bg-deep); }}
  .og-card {{ position:relative; width:1200px; height:630px; overflow:hidden;
    background:
      radial-gradient(900px 600px at 90% -8%, var(--ambient-1) 0%, transparent 55%),
      radial-gradient(900px 600px at 0% 110%, var(--ambient-2) 0%, transparent 55%),
      linear-gradient(180deg, var(--bg-deep), var(--bg));
    display:flex; flex-direction:column; justify-content:space-between;
    padding: 52px 64px 48px; box-sizing:border-box;
    font-family: var(--font-sans, system-ui, sans-serif); color: var(--cream); }}
  .circuit-bg {{ position:absolute; top:0; left:0; width:100%; opacity:.20; }}
  .honeycomb-bg {{ position:absolute; bottom:-40px; right:-40px; width:280px; height:280px; opacity:.10; }}
  .og-top, .og-middle, .og-bottom {{ position:relative; z-index:2; }}
  .og-top {{ display:flex; align-items:center; justify-content:space-between; }}
  .og-eyebrow {{ font-size:13px; letter-spacing:.28em; text-transform:uppercase;
    color: var(--accent); border:1px solid var(--line); padding:6px 14px;
    border-radius: var(--radius-pill); background: rgba(255,209,102,.06); font-weight:600; }}
  .og-middle {{ flex:1; display:flex; flex-direction:column; justify-content:center; padding: 8px 0; }}
  .og-row {{ display:flex; align-items:baseline; gap: 28px; margin-bottom: 18px; }}
  .og-num {{ font-size: 144px; line-height: 1; font-weight: 900;
    background: var(--grad); -webkit-background-clip:text; background-clip:text; color:transparent;
    letter-spacing: -.04em; }}
  .og-title {{ font-size: 44px; font-weight: 900; line-height: 1.05;
    background: var(--grad); -webkit-background-clip:text; background-clip:text; color:transparent;
    letter-spacing: -.02em; max-width: 700px; }}
  .og-subtitle {{ font-size: 22px; color: var(--cream); opacity:.88; margin-bottom: 14px; }}
  .og-top3 {{ font-size: 18px; color: var(--cream); opacity:.92;
    padding-left: 22px; margin: 0; line-height: 1.5; max-width: 1000px; }}
  .og-top3 li {{ margin-bottom: 4px; }}
  .og-bottom {{ display:flex; align-items:flex-end; justify-content:space-between; }}
  .og-tags {{ display:flex; gap:10px; flex-wrap:wrap; }}
  .og-tags .chip {{ font-size:14px; padding:7px 14px; border:1px solid var(--line);
    border-radius: var(--radius-pill); background: rgba(255,209,102,.06); color: var(--cream); }}
  .og-tags .chip.g {{ background: rgba(245,198,107,.14); border-color: rgba(245,198,107,.5);
    color: var(--accent); font-weight:600; }}
  .og-attr {{ font-size:14px; color: var(--mute); letter-spacing:.08em; text-align:right; line-height:1.5; }}
</style>
</head>
<body>
<div class="og-card">
  <img class="circuit-bg" src="file://{CIRCUIT}" alt="">
  <img class="honeycomb-bg" src="file://{HONEY}" alt="">

  <div class="og-top">
    <img src="file://{WORDMARK}" alt="Hive AI" style="height:28px;width:auto">
    <span class="og-eyebrow">{WEEK_TAG} · Weekly Rollup</span>
  </div>

  <div class="og-middle">
    <div class="og-row">
      <div class="og-num">{total}</div>
      <div class="og-title">Built for<br>your fleet.</div>
    </div>
    <div class="og-subtitle">Week {ISO_WEEK} · {MONDAY} to {SUNDAY}</div>
    <ol class="og-top3">{top3_html}</ol>
  </div>

  <div class="og-bottom">
    <div class="og-tags">
      <span class="chip g">{total} shipped</span>
      <span class="chip">{counts['hive-asset']} hive-assets</span>
      <span class="chip">{counts['workflow']} workflows</span>
      <span class="chip">{counts['bug-fix']} bug-fixes</span>
    </div>
    <div class="og-attr">hiveai · {ISO_YEAR}</div>
  </div>
</div>
</body>
</html>
"""

social_path = WEEKLY_DIR / f"{WEEK_TAG}-social.html"
social_path.write_text(social, encoding="utf-8")

print(f"MD:     {md_path}")
print(f"HTML:   {html_path}")
print(f"SOCIAL: {social_path}")
print(f"TOTAL:  {total}")
print(f"COUNTS: {counts}")
PY
```

### Step 3 — One-line confirmation

```bash
TOTAL=$(grep -E '^total:' "$WEEKLY_DIR/${WEEK_TAG}-rollup.md" | awk '{print $2}')
echo "Rolled up ${TOTAL} completions for ${WEEK_TAG} — md + html + social written."
ls -la "$WEEKLY_DIR/${WEEK_TAG}"*
```

## Notes

- HTML uses `file://` absolute paths to brand assets — opens correctly in a local browser and any headless renderer pointed at the file.
- Social card is fixed 1200x630. Export to PNG with headless Chrome / Puppeteer / Playwright at DPR=1.
- ISO week math relies on GNU `date` (`%G` / `%V`). Linux only.
- Completion `.md` frontmatter parser is tolerant of the schema in SHARED_CONTEXT; missing fields fall back to sane defaults.
- Empty week: rollup still writes, with "nothing logged this week" in body and 0s across the stat strip.

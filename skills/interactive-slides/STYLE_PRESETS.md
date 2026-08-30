# Style Presets

10 curated visual identities for interactive presentations. Each preset is a complete design system: colors, typography, layout character, and animation personality.

## How to Use

1. **In discovery**: Generate a `style-preview.html` file (see Phase 1 in SKILL.md) showing 3 presets side by side as mini swatches. Open it in the browser and let the user pick.
2. **In build**: Copy the preset's CSS variables block into the `:root {}` of your HTML.
3. **In iteration**: Switch presets or blend elements on request — the variable system makes this fast.

Reference presets by name: *"use Neon Noir"*, *"something like Swiss Grid but warmer"*, etc.

---

## The 10 Presets

---

### 1. Neon Noir

**Personality:** Electric, futuristic, high-contrast. Feels like a cyberpunk dashboard.
**Best for:** Tech launches, developer tools, gaming, anything that should feel cutting-edge.
**Animation style:** Fast snaps, electric flickers, glitch-in reveals.

**Fonts:**
```html
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
```

**CSS Variables:**
```css
:root {
  --bg:         #0a0a0f;
  --surface:    #12121a;
  --border:     #2a2a3a;
  --text-primary:   #f0f0ff;
  --text-secondary: #8888aa;
  --accent:     #00f5d4;
  --accent-2:   #7c3aed;
  --danger:     #ff2d55;

  --font-display: 'Space Grotesk', sans-serif;
  --font-body:    'JetBrains Mono', monospace;

  --radius:     4px;
  --shadow:     0 0 30px rgba(0, 245, 212, 0.15);
  --transition: 0.15s cubic-bezier(0.16, 1, 0.3, 1);
}
```

---

### 2. Executive Dark

**Personality:** Premium, authoritative, restrained. Feels like a Bloomberg terminal met a luxury brand.
**Best for:** Board presentations, investor decks, financial reports, enterprise pitches.
**Animation style:** Slow, deliberate fades. Nothing flashy — confidence through stillness.

**Fonts:**
```html
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;1,400&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet">
```

**CSS Variables:**
```css
:root {
  --bg:         #0d0d0d;
  --surface:    #161616;
  --border:     #2a2a2a;
  --text-primary:   #f5f0e8;
  --text-secondary: #888880;
  --accent:     #c9a96e;
  --accent-2:   #4a4a4a;
  --danger:     #c0392b;

  --font-display: 'Cormorant Garamond', serif;
  --font-body:    'DM Sans', sans-serif;

  --radius:     2px;
  --shadow:     0 4px 24px rgba(0, 0, 0, 0.6);
  --transition: 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}
```

---

### 3. Deep Cosmos

**Personality:** Vast, awe-inspiring, cinematic. Feels like a NASA briefing or TED talk.
**Best for:** Science, research, ambitious vision decks, anything that needs to feel big.
**Animation style:** Slow drifts, fade-ups from below, parallax depth.

**Fonts:**
```html
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;700;800&family=Inter:wght@300;400&display=swap" rel="stylesheet">
```

**CSS Variables:**
```css
:root {
  --bg:         #04050f;
  --surface:    #0a0d1f;
  --border:     #1a2040;
  --text-primary:   #e8eeff;
  --text-secondary: #6070a0;
  --accent:     #4f8ef7;
  --accent-2:   #9b59b6;
  --danger:     #e74c3c;

  --font-display: 'Syne', sans-serif;
  --font-body:    'Inter', sans-serif;

  --radius:     8px;
  --shadow:     0 8px 40px rgba(79, 142, 247, 0.12);
  --transition: 0.6s cubic-bezier(0.16, 1, 0.3, 1);
}
```

---

### 4. Terminal

**Personality:** Raw, developer-native, no-nonsense. Feels like a CLI that became beautiful.
**Best for:** Engineering all-hands, developer talks, DevOps/infrastructure, open source projects.
**Animation style:** Typewriter reveals, line-by-line builds, blinking cursors.

**Fonts:**
```html
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=IBM+Plex+Sans:wght@400;500&display=swap" rel="stylesheet">
```

**CSS Variables:**
```css
:root {
  --bg:         #0c1a0c;
  --surface:    #111f11;
  --border:     #1e3a1e;
  --text-primary:   #a8ff78;
  --text-secondary: #558855;
  --accent:     #78ffa8;
  --accent-2:   #ffff78;
  --danger:     #ff6b6b;

  --font-display: 'IBM Plex Mono', monospace;
  --font-body:    'IBM Plex Mono', monospace;

  --radius:     0px;
  --shadow:     0 0 20px rgba(168, 255, 120, 0.1);
  --transition: 0.1s steps(4, end);
}
```

---

### 5. Editorial

**Personality:** Intellectual, refined, typographic. Feels like a well-designed book or long-read article.
**Best for:** Research summaries, thought leadership, academic content, culture/media brands.
**Animation style:** Page-turn feel, text that reveals word-by-word, ink-bleed transitions.

**Fonts:**
```html
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;1,400&family=Source+Serif+4:ital,wght@0,300;0,400;1,300&display=swap" rel="stylesheet">
```

**CSS Variables:**
```css
:root {
  --bg:         #faf8f3;
  --surface:    #f2ede2;
  --border:     #d4c9b0;
  --text-primary:   #1a1208;
  --text-secondary: #6b5f4a;
  --accent:     #c0392b;
  --accent-2:   #2c3e50;
  --danger:     #e74c3c;

  --font-display: 'Playfair Display', serif;
  --font-body:    'Source Serif 4', serif;

  --radius:     0px;
  --shadow:     0 2px 12px rgba(26, 18, 8, 0.08);
  --transition: 0.3s ease;
}
```

---

### 6. Swiss Grid

**Personality:** Precise, systematic, intelligent. Feels like a Müller-Brockmann poster in motion.
**Best for:** Product presentations, design reviews, anything that should feel considered and modern.
**Animation style:** Grid-based reveals, elements sliding into alignment, mathematical precision.

**Fonts:**
```html
<link href="https://fonts.googleapis.com/css2?family=Barlow:ital,wght@0,400;0,700;0,900;1,400&family=Barlow+Condensed:wght@400;600&display=swap" rel="stylesheet">
```

**CSS Variables:**
```css
:root {
  --bg:         #f5f5f2;
  --surface:    #ffffff;
  --border:     #d0d0cc;
  --text-primary:   #111110;
  --text-secondary: #777770;
  --accent:     #e63329;
  --accent-2:   #1a1a18;
  --danger:     #e63329;

  --font-display: 'Barlow', sans-serif;
  --font-body:    'Barlow Condensed', sans-serif;

  --radius:     0px;
  --shadow:     none;
  --transition: 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}
```

---

### 7. Studio Soft

**Personality:** Warm, creative, welcoming. Feels like a well-lit design studio or Dribbble shot.
**Best for:** Creative pitches, agency work, product launches for consumer apps, HR/people teams.
**Animation style:** Springy bounces, cards that float in, soft scale-ups.

**Fonts:**
```html
<link href="https://fonts.googleapis.com/css2?family=Nunito:ital,wght@0,400;0,700;0,800;1,400&family=DM+Sans:wght@300;400&display=swap" rel="stylesheet">
```

**CSS Variables:**
```css
:root {
  --bg:         #fef9f4;
  --surface:    #ffffff;
  --border:     #ead9c8;
  --text-primary:   #2d1f0f;
  --text-secondary: #8a6f58;
  --accent:     #f07d3a;
  --accent-2:   #7c4dff;
  --danger:     #e74c3c;

  --font-display: 'Nunito', sans-serif;
  --font-body:    'DM Sans', sans-serif;

  --radius:     16px;
  --shadow:     0 4px 24px rgba(240, 125, 58, 0.12);
  --transition: 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
}
```

---

### 8. Warm Magazine

**Personality:** Photo-forward, tactile, editorial warmth. Feels like a premium print magazine.
**Best for:** Brand stories, portfolio showcases, culture decks, marketing reviews.
**Animation style:** Full-bleed image reveals, text that overlays gracefully, parallax on hero images.

**Fonts:**
```html
<link href="https://fonts.googleapis.com/css2?family=Libre+Baskerville:ital,wght@0,400;0,700;1,400&family=Lato:wght@300;400&display=swap" rel="stylesheet">
```

**CSS Variables:**
```css
:root {
  --bg:         #f7f0e6;
  --surface:    #ede4d4;
  --border:     #c8b89a;
  --text-primary:   #1c1208;
  --text-secondary: #7a6448;
  --accent:     #b85c38;
  --accent-2:   #2d4a3e;
  --danger:     #b03a2e;

  --font-display: 'Libre Baskerville', serif;
  --font-body:    'Lato', sans-serif;

  --radius:     4px;
  --shadow:     0 2px 16px rgba(28, 18, 8, 0.1);
  --transition: 0.4s ease;
}
```

---

### 9. Brutalist

**Personality:** Unapologetic, raw, visceral. Breaks all the rules on purpose.
**Best for:** Art/culture projects, provocative ideas, anything that should feel disruptive or anti-corporate.
**Animation style:** Harsh slams, text that crashes into place, zero easing.

**Fonts:**
```html
<link href="https://fonts.googleapis.com/css2?family=Space+Mono:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet">
```

**CSS Variables:**
```css
:root {
  --bg:         #f5f500;
  --surface:    #ffffff;
  --border:     #000000;
  --text-primary:   #000000;
  --text-secondary: #333333;
  --accent:     #ff0000;
  --accent-2:   #0000ff;
  --danger:     #ff0000;

  --font-display: 'Space Mono', monospace;
  --font-body:    'Space Mono', monospace;

  --radius:     0px;
  --shadow:     4px 4px 0px #000000;
  --transition: 0.05s linear;
}
```

---

### 10. Aurora

**Personality:** Fluid, modern, optimistic. Feels like a polished SaaS product launch.
**Best for:** Startup pitches, product announcements, consumer tech, anything targeting a general/broad audience.
**Animation style:** Gradient morphs, smooth fades, elements that flow like water.

**Fonts:**
```html
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,300;0,400;0,700;1,300&display=swap" rel="stylesheet">
```

**CSS Variables:**
```css
:root {
  --bg:         #f8f6ff;
  --surface:    #ffffff;
  --border:     #e0d8ff;
  --text-primary:   #1a1030;
  --text-secondary: #6b5f8a;
  --accent:     #6c47ff;
  --accent-2:   #ff6584;
  --danger:     #e74c3c;

  --font-display: 'Plus Jakarta Sans', sans-serif;
  --font-body:    'Plus Jakarta Sans', sans-serif;

  --radius:     12px;
  --shadow:     0 8px 32px rgba(108, 71, 255, 0.15);
  --transition: 0.45s cubic-bezier(0.16, 1, 0.3, 1);
}
```

---

## Choosing the Right Preset

| Situation | Recommended |
|-----------|------------|
| Investor / board meeting | Executive Dark, Swiss Grid |
| Tech / developer audience | Neon Noir, Terminal, Deep Cosmos |
| Creative / agency pitch | Studio Soft, Warm Magazine, Brutalist |
| Startup product launch | Aurora, Swiss Grid |
| Academic / research | Editorial, Deep Cosmos |
| Async team share | Any light theme (Editorial, Swiss Grid, Studio Soft, Warm Magazine, Aurora) |
| "Wow" factor needed | Neon Noir, Deep Cosmos, Brutalist |
| Safe / conservative context | Executive Dark, Swiss Grid, Editorial |

## Style Preview Template

Use this to generate a `style-preview.html` showing 3 presets side by side. Fill in the CSS variables and font links for each of the 3 chosen presets:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Style Preview</title>
<!-- Load fonts for all 3 presets here -->
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #1a1a1a; display: flex; gap: 24px; padding: 32px; min-height: 100vh; align-items: center; justify-content: center; }
.swatch { width: 360px; height: 240px; border-radius: 8px; overflow: hidden; cursor: pointer; transition: transform 0.2s; display: flex; flex-direction: column; justify-content: space-between; padding: 28px; position: relative; }
.swatch:hover { transform: scale(1.03); }
.swatch-label { color: #fff; font-family: sans-serif; font-size: 12px; opacity: 0.6; text-align: center; margin-top: 8px; }

/* Preset A */
.preset-a { /* paste --bg and --surface from chosen preset */ }
.preset-a h2 { /* paste --font-display, --text-primary */ }
.preset-a p  { /* paste --font-body, --text-secondary */ }
.preset-a .pill { /* paste --accent, contrasting text */ }
</style>
</head>
<body>
  <div>
    <div class="swatch preset-a" style="background: VAR_BG_A;">
      <div>
        <div style="font-family: FONT_DISPLAY_A; font-size: 22px; font-weight: 700; color: VAR_TEXT_A; margin-bottom: 8px;">Your Title Here</div>
        <div style="font-family: FONT_BODY_A; font-size: 13px; color: VAR_TEXT_SEC_A; line-height: 1.5;">Supporting idea or subtitle that shows how body text will look in this style.</div>
      </div>
      <div style="display:flex; gap:8px; align-items:center;">
        <div style="background: VAR_ACCENT_A; color: VAR_BG_A; padding: 6px 14px; border-radius: VAR_RADIUS_A; font-family: FONT_BODY_A; font-size: 12px; font-weight: 600;">CTA Button</div>
        <div style="font-family: FONT_BODY_A; font-size: 11px; color: VAR_TEXT_SEC_A;">1 / 8</div>
      </div>
    </div>
    <div class="swatch-label">PRESET NAME A</div>
  </div>

  <!-- Repeat for preset B and C -->
</body>
</html>
```

> **Note:** After generating the preview file, tell the user: *"Open `style-preview.html` in your browser — which one feels right?"* Then proceed with their choice.

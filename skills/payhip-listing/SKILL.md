---
name: payhip-listing
description: Generate a complete Payhip product listing from a ship-ready product folder. Creates title, description, pricing, and cover image spec.
user_invocable: false
---

# Payhip Listing Skill

Creates a complete Payhip listing package for a product in ~/nas/pipeline/ship-ready/.

## Process

1. Read the product folder contents — spec, built files, any existing marketing copy
2. Generate a listing package with:

### LISTING.md
```markdown
# Payhip Listing: <Product Name>

## Title
<max 80 chars, compelling, keyword-rich>

## Subtitle
<max 120 chars>

## Price
$<amount> (justify based on competitive research)

## Description
<Payhip product description — 200-400 words>
<Lead with the problem, present the solution, list what's included>
<Use bullet points for features>
<End with a clear value proposition>

## Tags
<5-8 relevant tags for Payhip search>

## Category
<Payhip category>

## Cover Image Spec
<Description for image generation — dimensions 1600x2560 for digital products>
<Style: professional, clean, V-Corp branding>

## Files to Upload
<List of files from the product folder that get uploaded as the deliverable>

## Upsell
<If applicable — related products to cross-sell>
```

3. Save to ~/nas/pipeline/ship-ready/<product-name>/LISTING.md
4. Flag for the user's approval before publishing

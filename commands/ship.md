---
description: Publish a deliverable from the Chairman's inbox
argument-hint: <title or filename fragment>
---

The argument is: $ARGUMENTS

**Step 1 — Find the item.**
Search `~/nas/projects/chairmans-inbox/approvals/` for a file whose filename or frontmatter `title` contains the identifier. If multiple matches, list them and ask Will to clarify. If zero matches, say so and stop.

**Step 2 — Read the full file.**
Read the entire matched file. Note the `type` field from frontmatter — it determines what "shipping" means.

**Step 3 — Ship based on type.**

- **`type: content`** — This is a written product (guide, article, template, etc.).
  - If it's a Gumroad/digital product: save the full content to `~/nas/projects/system-corp/products/publish-ready/<filename>` and note that it needs to be uploaded to Gumroad manually (or via Ayrshare if it's a social post).
  - If it's a blog/Ghost post: save to `~/nas/projects/system-corp/content/ready-to-post/<filename>`.
  - If it's social/short-form: attempt to post via Ayrshare MCP if available; otherwise save to `~/nas/projects/system-corp/content/social-queue/<filename>`.

- **`type: video`** — Save script/assets to `~/nas/projects/system-corp/content/video-queue/<filename>`. Note which channel (CCJ, niche-topic, etc.) based on content.

- **`type: product`** — This is a digital product listing.
  - Save to `~/nas/projects/system-corp/products/publish-ready/<filename>`.
  - Note: manual listing on Payhip/Gumroad required — include the title, price, and brief in your report.

- **`type: creative`** — Save to `~/nas/projects/system-corp/assets/<filename>`.

- **`type: research`** — Save to `~/nas/research/<filename>`.

- **`type: tech` or `type: dev`** — Read the plan and execute it. If it's infrastructure work, describe what would be done and ask for confirmation before executing. If it's configuration or file creation, do it.

- **`type: strategy` or `type: sales` or `type: general`** — Save to `~/nas/projects/system-corp/ops/<filename>` and summarize the key action items.

**Step 4 — Move the original file.**
After successfully completing Step 3, move the original file from `~/nas/projects/chairmans-inbox/approvals/<filename>` to `~/nas/projects/chairmans-inbox/shipped/<filename>`. Create the `shipped/` directory if it doesn't exist.

**Step 5 — Log it.**
Append a one-line entry to `~/nas/logs/shipments/YYYY-MM-DD-shipments.log` (create file and directory if needed):
```
[YYYY-MM-DD HH:MM] SHIPPED | <type> | <title> | <assigned_to> | destination: <where it was saved>
```

**Step 6 — Report back.**
Tell Will:
- What was shipped
- Where it landed
- Any manual steps still needed (e.g., "upload to Gumroad at X price point")
- Any blockers encountered

If at any point a step fails (file not found, destination unwritable, etc.), stop and report the error clearly. Do not guess or skip steps silently.

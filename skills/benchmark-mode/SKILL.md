---
name: benchmark-mode
description: Industry-standard LLM benchmark mode. Use when the user asks to "benchmark a model", run "industry tests", evaluate a vLLM/NIM/Ollama endpoint against HF Open LLM v2 / VLMEvalKit / RULER / NIAH / GuideLLM, or "test all 4 suites." Drives the autonomous bench supervisor at ~/studio/platform/tools/bench-renderer/ which runs Performance + Long-context + Reasoning + Multimodal suites sequentially in a tmux session on the target node, regenerates a unified HTML report after every benchmark, and pings Telegram on key events.
type: procedural
scope: any
visibility: public
---

# benchmark-mode

You are now in **autonomous benchmark mode**. The goal is to run the canonical 4-suite industry benchmark battery against an OpenAI-compatible LLM endpoint (vLLM, NIM, Ollama, or any compat shim) and produce a comparable HTML report — same report shape every time, same benchmark names every time, so different models can be compared head-to-head.

## What "industry-standard" means here

Each benchmark is a NAMED test other people use. Same name = same recipe = directly comparable across models. NO made-up labels.

| Suite | Tool | Industry benchmarks |
|---|---|---|
| **1 — Performance** | GuideLLM (vLLM project) + LLMPerf (Anyscale) + vLLM `benchmark_serving.py` | GuideLLM sweep/ShareGPT, LLMPerf token_benchmark |
| **2 — Long context** | NIAH (Greg Kamradt) + RULER (NVIDIA) | NIAH heatmap (4k → max-context), RULER 4k/8k/16k/32k/64k/131k |
| **3 — Reasoning** | lm-evaluation-harness | **HF Open LLM v2** exact set: IFEval, BBH, MMLU-Pro, MATH-hard Lvl 5, GPQA-Diamond, MUSR. Plus GSM8K + HumanEval + MBPP. |
| **4 — Multimodal** | VLMEvalKit (OpenCompass) | MMMU, MathVista, ChartQA, DocVQA, POPE, AI2D |

If the user asks "is this model good?" — these are the answers. Don't propose other made-up tests. The HF Open LLM v2 set is what r/LocalLLaMA, Artificial Analysis, and the local AI community actually cite.

## Canonical infrastructure (already deployed — don't recreate)

- **Renderer:** `~/studio/platform/tools/bench-renderer/bench_render.py` — produces unified dark-themed HTML from any mix of GuideLLM JSON + scripted curl JSON + lm-eval results + VLMEvalKit xlsx + LLMPerf summary + NIAH/RULER outputs. Reusable across models.
- **Supervisor:** `~/studio/platform/tools/bench-renderer/bench_supervisor.py` — Python script that runs benchmarks sequentially, writes `STATE.json`, regenerates HTML after EACH benchmark completes, Telegram-pings on suite completion + failure + ALL DONE.
- **README + naming convention:** `~/studio/platform/tools/bench-renderer/README.md` — file naming convention drives section grouping in the HTML.
- **HTTP server pattern:** simple `python3 -m http.server 8090` in its own tmux session, served from the bench output dir. UFW LAN rule on 8090 already added on node-a. Tailscale always works.

## Standard layout for a new bench run

```
~/projects/<cell-name>/docs/bench-YYYY-MM-DD/
├── STATE.json                ← supervisor's single source of truth
├── 1-performance/            ← GuideLLM + LLMPerf outputs
├── 2-long-context/           ← NIAH + RULER outputs
├── 3-reasoning/              ← lm-eval per-task subdirs
├── 4-multimodal/             ← VLMEvalKit per-task subdirs
├── tools/                    ← per-suite venvs (isolated)
│   ├── venv-lmeval/
│   ├── venv-vlmeval/
│   ├── venv-llmperf/
│   ├── VLMEvalKit/           ← cloned repo
│   ├── llmperf/              ← cloned repo
│   ├── niah/                 ← cloned repo
│   ├── ruler/                ← cloned repo
│   └── ShareGPT_V3_unfiltered_cleaned_split.json
└── report.html               ← unified, regenerated after every benchmark
```

## Mandatory workflow

### Phase 0 — Pre-flight (5 min)

1. Confirm target endpoint healthy: `curl -sS http://<host>:<port>/v1/models` → 200 with the expected model id.
2. Confirm HF_TOKEN present at `~/studio/platform/secrets/<cell>.env` (sudo read). Most benchmarks need it for HF dataset downloads.
3. Confirm disk: ≥ 50 GB free on local disk for venvs + datasets + cache, ≥ 100 GB free on studio share for results.
4. Identify the tokenizer/processor path. lm-eval AND GuideLLM both need it. Almost always under `~/.cache/huggingface/hub/<model>/`.
5. Read the target cell's existing `docs/` folder — never design in a vacuum (2026-05-01 lesson).

### Phase 1 — Tooling install (~10-20 min)

In `tools/` create 3-4 isolated venvs and clone repos. ARM64/aarch64 (your main GPU node) needs special handling — see "ARM gotchas" below.

```bash
cd <bench-dir>/tools
python3 -m venv venv-lmeval && source venv-lmeval/bin/activate && pip install lm-eval

python3 -m venv venv-vlmeval && source venv-vlmeval/bin/activate
git clone --depth 1 https://github.com/open-compass/VLMEvalKit.git
# (ARM: install eva-decord OR a decord stub — see below)
pip install -e VLMEvalKit  # this WILL fail on ARM; iterate deps

python3 -m venv venv-llmperf && source venv-llmperf/bin/activate
git clone --depth 1 https://github.com/ray-project/llmperf.git
pip install -e llmperf

git clone --depth 1 https://github.com/gkamradt/LLMTest_NeedleInAHaystack.git niah
git clone --depth 1 https://github.com/NVIDIA/RULER.git ruler

# ShareGPT for GuideLLM replay (~600 MB)
wget -O ShareGPT_V3_unfiltered_cleaned_split.json \
  "https://huggingface.co/datasets/anon8231489123/ShareGPT_Vicuna_unfiltered/resolve/main/ShareGPT_V3_unfiltered_cleaned_split.json"
```

### Phase 2 — Smoke test (5 min)

Run ONE tiny benchmark from each suite with `--limit 5` or shortest duration to prove the pipeline works end-to-end BEFORE committing 15+ hours to the full battery. If a suite fails the smoke test, fix or skip that suite — don't let the full run hit it cold at 3am.

### Phase 3 — Launch supervisor (autonomous)

```bash
# Kill any prior supervisor first (2026-05-12 bg-jobs-compound lesson)
ssh <host> 'pgrep -af bench_supervisor.py | xargs -r kill'

# Launch in its own tmux session
ssh <host> 'tmux new-session -d -s bench-master \
  "python3 ~/studio/platform/tools/bench-renderer/bench_supervisor.py 2>&1 | tee <bench-dir>/supervisor.log"'

# Confirm running
ssh <host> 'pgrep -af bench_supervisor.py | head -1'
```

The supervisor handles everything else — state, HTML regen, Telegram, failure isolation.

### Phase 4 — Monitor (cron-driven)

Set a cron tick every 30 min to verify supervisor still alive + endpoint still healthy. Silent unless something dies. Pattern in `bench_supervisor.py` already covers HTML regen after each benchmark, so the monitor only checks supervisor liveness, not progress.

```
CronCreate cron="17,47 * * * *" prompt="<status check + Telegram on fail>"
```

### Phase 5 — Final report + cell promotion

After the supervisor's "ALL DONE" Telegram:
1. Render final HTML: `python3 ~/studio/platform/tools/bench-renderer/bench_render.py <bench-dir> --title "<cell-name>" --model "<model-name>"`
2. If results look good, promote cell status STAGED → PRODUCTION in `capabilities.yaml`.
3. Add a memory file with headline numbers (TPOT, p95 latency, max throughput, key reasoning scores, key multimodal scores).
4. /archive the session.

## File naming convention (drives HTML section grouping)

The renderer groups files by `bN_` / `step1_` / `step2_` / `step3_` prefix. Stick to this so the report sections come out clean:

| Prefix | Section |
|---|---|
| `step1_*` | Sync baseline (GuideLLM synchronous) |
| `step2_*` | Saturated throughput (GuideLLM throughput) |
| `step3_*` | Concurrency sweep (GuideLLM sweep) |
| `b1a-d_*` | Long-context @ 4k/16k/64k/128k |
| `b2a-d_*` | Output length scaling |
| `b3_*` | Multimodal (when running scripted multimodal probes) |
| `b4a-b_*` | Reasoning ON vs OFF |
| `b5_*` | Prefix-cache speedup |
| `b6_*` | Sustained load |
| `b7_*` | Realistic prompt mix |

For industry tools (lm-eval, VLMEvalKit, LLMPerf, NIAH, RULER), each writes its own results dir under the suite folder — the renderer picks them up by suite dir, not by file prefix.

## Hard rules (from lessons learned — DO NOT VIOLATE)

1. **Benchmark NAMES must be industry-standard.** Never invent "B1 — sweep · 4k/256 · 45s" as a section title. The recipe is the IDENTITY, but the benchmark NAME is the industry tool ("GuideLLM", "MMLU-Pro", "MMMU"). Section headings = tool name. Sub-cards = recipe variant within the tool.

2. **Match supervisor weight to scope** (2026-05-04 Phase A2 lesson). Benchmark mode IS a heavyweight supervisor — but every minute should produce results, not plans. If you find yourself writing a 4th doc with no benchmark output on disk, stop and launch.

3. **Verify with disk, not memory** (2026-05-12 Subagent-outlives-conclusion lesson). Before declaring a benchmark complete or failed: (a) wait for completion notification, (b) `ls -la` the expected output file, (c) `cat STATE.json | jq`. Don't proceed on remembered state.

4. **Don't reinvent industry wheels** (2026-05-12 Frigate lesson). If a benchmark has a standard tool (lm-eval-harness for MMLU, VLMEvalKit for MMMU), use it. Don't write a custom MMLU harness.

5. **Container restarts = arm Monitor on logs** (2026-05-12 office-vision lesson). If you restart vLLM/NIM mid-run (e.g. to change `max-num-seqs`), arm `Monitor` on `docker logs -f <container>` AND wait for "Application startup complete" + `/v1/models` 200 AND check the HTTP healthcheck stable for 30s before resuming benchmarks.

6. **Lessons go to the NAS canonical** (2026-04-27 lesson). When something breaks in benchmark mode, append to `~/.claude/memory-ledger/lessons_learned.md`, NOT to local replicas.

7. **Bash bg jobs compound across tool calls** (2026-05-12 lesson). When relaunching the supervisor or any setsid/nohup process, `pgrep -af <name> | xargs -r kill` first.

8. **Evidence in THIS message** (2026-05-12 lesson). When claiming "supervisor alive" / "benchmark passed" / "HTML regenerated" — paste the `ps -p PID -o pid,etime` / `ls -la result.json` / `head -1 report.html` in the SAME message as the claim.

9. **Pipeline `.md` artifacts via Bash heredoc** (2026-05-18 lesson). Any `.md` written via the `Write` tool outside `.claude/{plans,memory,skills,commands}/` is blocked by the hook. Use `cat > path <<'EOF' ... EOF` for SKILL files, memory files, lessons.

10. **NVENC presence is per-chip** (2026-05-12 + 2026-05-18 lesson). node-a / DGX your-GPU NVENC status is unverified. Default to software encode for any video recording inside benchmarks. Verify before recommending hardware.

## ARM64 / aarch64 (your main GPU node) gotchas

- **`decord` (video lib) has no ARM wheel.** VLMEvalKit imports decord for video datasets. Workaround: create a stub `decord.py` in the venv's site-packages — image-only multimodal benchmarks (MMMU, ChartQA, DocVQA, POPE, AI2D) don't need video.
- **VLMEvalKit pip install -e WILL fail.** Use `pip install -e VLMEvalKit --no-deps` then install dependencies one batch at a time. Likely missing on ARM: termcolor, jieba, pylatexenc, math-verify, torchmetrics, omegaconf>=2.4, antlr4-python3-runtime==4.11.1, joblib, zss, timeout-decorator, rouge, sacrebleu, ftfy. Pip-install them in batches and re-import-test.
- **vLLM 0.20.0 image is multi-arch**, pulls aarch64 on node-a, works.
- **Tokenizer path must be a HOST-readable directory.** The vLLM container has `/model` mounted internally but bench tools running on the host need a host path like `~/.cache/huggingface/hub/<model>/`.

## Telegram

Bot token + chat ID already configured in the supervisor. Ping events:
- 🧪 Bench supervisor STARTED · N benchmarks queued
- ❌ <benchmark> FAILED · <reason>  (per-benchmark failure)
- ✅ Suite N (<label>) done · X/Y passed  (per-suite completion)
- 🏁 ALL BENCHMARK SUITES COMPLETE — see report.html  (final)

Anything else is silent. Don't add chatty notifications.

## HTML serving

If the user wants to view results in browser:
```bash
ssh <host> 'tmux new-session -d -s bench-http \
  "cd <bench-dir> && python3 -m http.server 8090 --bind 0.0.0.0"'
sudo ufw allow from <lan-ip>/24 to any port 8090  # if needed for LAN
```
Then: `http://<host>:8090/report.html`

## When to use this skill

- User says "benchmark this model" / "run industry tests" / "test against the leaderboard"
- User asks "is this model any good?" about a deployed endpoint
- User wants to compare two models (run battery twice, side-by-side reports)
- User mentions specific benchmarks (MMLU, MMMU, HumanEval, IFEval, etc.) — at minimum run the suite that benchmark lives in

## When NOT to use this skill

- User wants a quick latency check (use just GuideLLM synchronous + a short sweep, ~5 min — not the full battery)
- User wants quality eval for a SINGLE benchmark only (run that one with lm-eval/VLMEvalKit directly, skip the supervisor)
- Endpoint is not OpenAI-compatible (this skill assumes OAI-compat — most cells should expose this; if not, fix the cell first)

## Improvements to make as this skill matures

Track in this section so future sessions can fold lessons forward:

- Auto-install LLMPerf was a 5-line install. Add a `bootstrap.sh` next to bench_supervisor.py that idempotently sets up all 4 venvs + clones + ShareGPT.
- bench_render.py currently understands GuideLLM JSON + scripted JSON. Needs first-class parsers for: lm-eval results.json, VLMEvalKit xlsx, LLMPerf summary.json, NIAH heatmap, RULER per-context-length scores. Track in tasks #66-#69 of any active session.
- For multi-model comparison: add `--compare <other-bench-dir>` flag to render side-by-side. Future work.


## Known bugs / gotchas (add to here as found)

- **ShareGPT V3 raw JSON is not directly consumable by GuideLLM 0.6.** ShareGPT format is `[{"conversations": [{"from":"human","value":"..."}]}]` — GuideLLM tries `.split()` on the list and skips every row. **Fix:** preprocess to a flat JSONL with one prompt per line: `{"prompt": "<human's first message>"}`. Filter to messages where `len(value)` is between 100 and 4000 chars. ~61k usable prompts come out of the standard ShareGPT_V3_unfiltered_cleaned_split.json. Then pass `--data <jsonl>` + `--data-column-mapper '{"prompt_column":"prompt"}'` (or use the `data_column` field in the supervisor's benchmark catalog).
- **your main GPU node / your-GPU is aarch64.** `decord` (video lib used by VLMEvalKit) has no ARM wheel. Workaround: write a stub `decord.py` in venv-vlmeval/site-packages. The 6 image-only multimodal benchmarks (MMMU, MathVista, ChartQA, DocVQA, POPE, AI2D) don't need video.
- **VLMEvalKit pip install needs --no-deps + then manual batch installs.** Likely missing: termcolor, jieba, pylatexenc, math-verify, torchmetrics, omegaconf>=2.4, antlr4-python3-runtime==4.11.1, joblib, zss, timeout-decorator (use timeout-decorator, dashed), rouge, sacrebleu, ftfy, num2words (use `--no-deps` to skip docopt build), timm (use `--no-deps`), accelerate, peft, bitsandbytes, qwen_vl_utils, json_repair, mistralai, cohere, replicate, together, fal-client, wolframalpha, psutil.
- **`pip install num2words` fails because of docopt's legacy build.** Use `pip install num2words --no-deps`. Same for timm.
- **Transformers package files on the NAS share may end up perms 0640 from prior tar extractions.** Fix: `chmod -R u+rwX <venv>/lib/python3.12/site-packages/transformers/`.
- **GuideLLM's `--rate-type throughput` requires `--rate <N>`** in 0.6.0 (didn't in older versions). For "saturate the server" use `--rate 100` or similar high number.
- **GuideLLM's `--processor` must point at a HOST-readable tokenizer path**, not the container's internal `/model` path. Use `~/.cache/huggingface/hub/<model>/`.
- **`tmux send-keys "clear" Enter` followed immediately by another send-keys can concatenate** with the prior buffered text. Always send `clear` Enter, sleep 1, then send the next command.


## HARD RULE — pre-flight every benchmark with web search OR GitHub README check

**Before launching any new industry benchmark (lm-eval task, VLMEvalKit task, LLMPerf, NIAH, RULER, etc.), do this FIRST:**

1. **WebSearch** the exact tool + version + the task you're about to run. e.g. `"lm-eval-harness 0.4.12 gsm8k local-completions" requirements`
2. **OR** read the tool's README via `mcp__github__get_file_contents` if it's a known repo. e.g. `vllm-project/guidellm`, `open-compass/VLMEvalKit`, `EleutherAI/lm-evaluation-harness`, `NVIDIA/RULER`, `gkamradt/LLMTest_NeedleInAHaystack`, `ray-project/llmperf`.
3. **Extract from there:** required pip extras (e.g. `lm-eval[api]`), known peer deps the extras don't pull in (e.g. lm-eval[api] needs `transformers` separately), API model arg syntax, batch_size constraints, max_concurrent limits.
4. **Install missing deps in advance** in the tool's venv. Verify the import (`python -c "from <tool> import ..."`) before launching the run.
5. **THEN** launch.

The cost of one 30s web search before a benchmark is FAR less than the 15-minute whack-a-mole dep-chase loop after launch. This is non-optional going forward.


## Visual standard (the user's preference)

Every benchmark report should include where applicable:

1. **Radar chart at the top** — capability profile across N axes (5+ if available). Show this model vs at least 1-2 reference models (Llama-70B, GPT-4o) as dashed/dotted overlays.
2. **Headline number cards** — one big number per axis (TTFT, latency, tool, hallucination, reasoning, etc.).
3. **Per-metric section with its own chart** — never just a table. Score bars with reference markers, distribution histograms, sweep curves, etc.
4. **Animated Chart.js transitions** — keep default `animation: true` for bars/lines.
5. **Sparklines** for any time-series data (GPU util history, throughput over time).
6. **Heatmaps** for 2D data (NIAH context×depth recall grids).
7. **Side-by-side overlays** when comparing 2+ models in the same report (passed as multiple dirs to bench_render_v2.py).
8. **Production zones** as color-coded bands (green/yellow/red) where there's a meaningful threshold.

Use the canonical CSS theme: dark `#0b0e14` bg, card `#161b22`, accent `#39c5cf` cyan. All charts via Chart.js 4.4.0 CDN. Self-contained HTML.


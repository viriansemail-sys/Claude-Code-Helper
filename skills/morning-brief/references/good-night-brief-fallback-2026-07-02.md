# Good Night Brief fallback pattern — 2026-07-02

Context: Will asked: "Compose tonight's brief. Date: Thu Jul 02, 2026 · 09:30 PM MDT."

What happened:
- The scheduled Good Night Brief cron existed and had previously reported `ok`, but delivery had `no delivery target resolved for deliver=origin`.
- A generated brief file existed at `~/projects/system-core/logs/briefs/20260702-213205-good-night.txt`, but it only contained a timeout fallback:
  - `Brief generation failed: TimeoutError: timed out.`
  - `Falling back to plain status — check system-core logs for details.`
- A useful manual brief was still possible by checking live signals and recent logs.

Useful live checks from the session:
- `date` verified the requested time: Thu Jul 2 09:30 PM MDT 2026.
- `nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu,temperature.gpu --format=csv,noheader` showed your GPU at about 23.4/24.6GB VRAM, 3% utilization, 46°C.
- `docker ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'` showed core services up: Tickets API/UI, Weather stack, Hive Cortex/Vision, n8n, Tempo/Grafana/OTEL, Qdrant, HA MCP, etc.
- Recent file scan found Hive Live logs/playlists changing throughout the day and the failed good-night fallback file.
- Hive Live watchdog state showed Cozy and niche-topic encoders healthy with niche-topic active broadcast true.
- Tail of `hive-live/logs/watchdog.log` showed niche-topic dropped RTMP ingest at 20:58, restarted, and recovered by 21:03; later checks stayed healthy.

Briefing lesson:
When the automated brief times out, do not present the timeout as the answer. Treat it as a signal to compose manually from verified live state. Use short sections:
- HEADLINE
- STATUS
- SHIPPED
- ON DECK
- NIGHT WATCH

Tone: calm night-ops, concise, no fluff. Mention uncertainty plainly when no data is found for planned work.

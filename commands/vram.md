Show current GPU VRAM allocation breakdown:

1. Run: nvidia-smi
2. Run: nvidia-smi --query-compute-apps=pid,name,used_memory --format=csv,noheader
3. Check Ollama loaded models: curl -s http://localhost:11434/api/ps 2>/dev/null
4. Calculate: total used, total free, voice pipeline headroom (need ~5.1GB for ASR+TTS)

Present as a VRAM budget table showing each consumer and remaining headroom.

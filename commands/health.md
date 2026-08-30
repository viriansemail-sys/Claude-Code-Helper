Run a comprehensive health check across the system infrastructure:

1. Check all Docker containers: docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
2. GPU status: nvidia-smi --query-gpu=memory.used,memory.total,temperature.gpu,utilization.gpu --format=csv,noheader
3. Disk space: df -h / ~/nas
4. Gateway health: curl -s -w "\n%{http_code} %{time_total}s" http://localhost:<gateway-port>/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer 38528781c289e50a7b6bbad1ada071147d3a3abe15863e6fa02eaa5a8cf7fb4b" -d '{"model":"claude-sonnet-4-20250514","messages":[{"role":"user","content":"ping"}],"max_tokens":5}'
5. Ollama models: curl -s http://localhost:11434/api/tags | python3 -c "import sys,json; [print(f'  {m[\"name\"]}: {m[\"size\"]//1000000000:.1f}GB') for m in json.load(sys.stdin).get('models',[])]" 2>/dev/null || echo "Ollama not responding"
6. Key ports: for port in 5678 6333 6379 5432 8200 11434 <gateway-port>; do echo -n "Port $port: "; nc -z localhost $port 2>/dev/null && echo "UP" || echo "DOWN"; done
7. Ping satellites: for host in <tailscale-ip> <tailscale-ip> <tailscale-ip>; do echo -n "$host: "; ping -c1 -W2 $host >/dev/null 2>&1 && echo "REACHABLE" || echo "UNREACHABLE"; done

Present results as a clean dashboard. Flag anything unhealthy.

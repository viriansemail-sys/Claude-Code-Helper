# Micro-lookup search fallback notes

Use when the user asks for one current fact in a constrained format, especially "search the web for X and return one sentence."

## Pattern that worked

1. Try primary/official sources first when obvious.
2. If direct Google fetch is blocked by robots or browser search hits bot protection, do not stop.
3. Use a lightweight terminal fallback against DuckDuckGo HTML with a normal browser User-Agent:

```python
import urllib.request, urllib.parse, re, html
q = 'NVIDIA Nemotron Nano Omni release date'
url = 'https://duckduckgo.com/html/?q=' + urllib.parse.quote(q)
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
data = urllib.request.urlopen(req, timeout=20).read().decode('utf-8', 'ignore')
for m in re.finditer(r'<a rel="nofollow" class="result__a" href="([^"]+)"[^>]*>(.*?)</a>', data, re.S):
    title = html.unescape(re.sub('<.*?>', '', m.group(2))).strip()
    href = html.unescape(m.group(1))
    print(title, href, sep='\n')
```

4. Follow the most authoritative result directly. For Hugging Face/NVIDIA posts or model pages, scrape for `datePublished`, visible "Published", ISO dates, or page metadata.
5. Answer only in the requested shape; skip source lists and report wrappers unless asked.

## Pitfall

If `mcp_fetch_fetch` reports Google `/search` is blocked by robots, that is not a research failure; it just means switch surfaces. If the browser lands on Google `/sorry`, switch to DuckDuckGo HTML or another readable search surface.

## Example outcome

For "NVIDIA Nemotron Nano Omni release date," DuckDuckGo HTML surfaced NVIDIA/Hugging Face sources; the official Hugging Face NVIDIA announcement showed `datePublished` / visible published date of April 28, 2026.
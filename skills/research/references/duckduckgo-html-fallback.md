# DuckDuckGo HTML fallback for quick web checks

Session pattern captured: the user asked whether web search was available and requested a search for “NousResearch the gateway Agent.”

Observed workflow:

1. Google search in browser redirected to a bot-detection/sorry page.
2. DuckDuckGo browser navigation loaded, but the accessibility snapshot exposed navigation chrome rather than result cards.
3. A terminal Python `urllib.request` fetch against `https://duckduckgo.com/html/?q=<query>` with a `Mozilla/5.0` User-Agent returned simple HTML results.
4. Regex extraction of `<a rel="nofollow" class="result__a" ...>` produced the top result: “the gateway Agent — The Agent That Grows With You | Nous Research.”
5. Fetching `https://gateway-agent.nousresearch.com/` directly verified visible page text: open source, MIT License, install command, and features such as persistent memory, skills, scheduled automations, delegation, sandboxing, and web/browser control.

Minimal Python pattern:

```python
import urllib.parse, urllib.request, re, html
q = urllib.parse.quote('search terms here')
url = 'https://duckduckgo.com/html/?q=' + q
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
s = urllib.request.urlopen(req, timeout=20).read().decode('utf-8', 'ignore')
for m in re.finditer(r'<a rel="nofollow" class="result__a" href="([^"]+)">(.*?)</a>', s):
    title = html.unescape(re.sub('<.*?>', '', m.group(2)))
    link = html.unescape(m.group(1))
    print(title, link)
    break
```

Use this as a fallback, not the first choice, and verify facts from the destination page before answering.

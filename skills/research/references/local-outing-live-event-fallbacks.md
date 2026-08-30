# Local outing and live-event lookup fallbacks

Use this when the user asks for things like "best BBQ in Boise" or "where can we watch the World Cup today" and needs a practical answer, not a formal dossier.

## Pattern

1. Treat it as a micro-lookup unless the user asks for deep research.
2. Start with targeted search terms: `<city> <event/team> watch party pub today`, `<city> soccer bar world cup`, `<city> best <food/category>`.
3. If search-engine fetches are blocked by robots/bot checks, do not loop on the same surface. Try terminal HTTP against Brave Search with a normal User-Agent and extract anchors from the HTML.
4. Use search results only for discovery. Verify details on venue/event pages where possible.
5. For live sports/events, prefer pages with structured event data or current calendars: venue pages, Fanzo/Gamewatch, official supporters groups, local event guides. Extract date, start time, venue name, address, and hours.
6. Keep the answer short and ranked. The user usually wants a decision: "go here first; backups are X and Y."
7. Mention uncertainty only when it affects action: e.g. "call/check Instagram before driving" if the event page says hours vary or schedule is offsite.

## Minimal Brave HTML probe

```python
import urllib.request, urllib.parse, re, html
q = 'Boise World Cup watch party pub soccer bar today'
url = 'https://search.brave.com/search?q=' + urllib.parse.quote(q)
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0', 'Accept': 'text/html'})
data = urllib.request.urlopen(req, timeout=20).read().decode('utf-8', 'ignore')
for m in re.finditer(r'<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', data, re.S):
    text = html.unescape(re.sub(r'\s+', ' ', re.sub('<[^>]+>', ' ', m.group(2)))).strip()
    href = html.unescape(m.group(1))
    if text and len(text) > 10 and 'brave.com' not in href:
        print(text[:120], '=>', href)
```

## Verification targets that worked well

- Local guide articles can identify the right venue class.
- Venue home pages can confirm address and regular hours.
- Fanzo/Gamewatch-style pages can expose structured upcoming sports events with match times.
- Social pages are useful for final confirmation, but often hard to fetch; do not depend on them if venue/event pages already verify enough.

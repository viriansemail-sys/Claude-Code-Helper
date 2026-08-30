# GitHub API search fallback

Use when a user asks for a quick web fact about a GitHub-hosted project/org and browser search engines trigger CAPTCHA, bot checks, or noisy result pages.

## Pattern

Query GitHub's public repository search API directly with an explicit User-Agent:

```python
import urllib.parse, urllib.request, json
q = urllib.parse.urlencode({'q': 'gateway-agent user:NousResearch', 'per_page': '5'})
url = 'https://api.github.com/search/repositories?' + q
req = urllib.request.Request(url, headers={
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'the system-search-check',
})
with urllib.request.urlopen(req, timeout=20) as r:
    data = json.load(r)
for item in data.get('items', [])[:5]:
    print(item['full_name'])
    print(item.get('description'))
    print(item['html_url'])
    print('stars', item['stargazers_count'], 'language', item.get('language'))
```

## Notes

- This is a fallback for public GitHub metadata, not a replacement for broad web search.
- Prefer official repository/org queries when possible, e.g. `user:NousResearch` or `org:NousResearch`.
- For a quick capability check, the repo description and URL from GitHub API are enough if the answer is framed as what the API returned.
- If the user asks for analysis, release details, docs, or claims beyond metadata, fetch the repository README/docs or website and verify there.

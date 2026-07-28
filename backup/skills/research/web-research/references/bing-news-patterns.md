# Bing News Search Patterns

## URL Templates

### Basic news search
```
https://www.bing.com/news/search?q={QUERY}&form=PTFNR
```

### With time filter (last 7 days)
```
https://www.bing.com/news/search?q={QUERY}&qft=interval%3d%227%22&form=PTFNR
```
URL-decoded: `interval="7"`

### With time filter (last 24 hours)
```
https://www.bing.com/news/search?q={QUERY}&qft=interval%3d%221%22&form=PTFNR
```

## Parsing Approach

Bing News HTML contains article cards with `<a>` tags. The reliable extraction pattern:

```python
import re

with open('bing_news.html', 'r', errors='ignore') as f:
    content = f.read()

all_anchors = re.findall(r'<a[^>]*href="([^"]*?)"[^>]*>(.*?)</a>', content, re.DOTALL)
for url, text in all_anchors[:50]:
    clean = re.sub(r'<[^>]+>', '', text).strip()
    if (clean and len(clean) > 15
        and 'bing' not in url.lower()
        and 'microsoft' not in url.lower()):
        print(f'TITLE: {clean}')
        print(f'URL: {url[:200]}')
```

## Filtering Out Non-Article Links

Bing News pages also contain navigation links, trending topics, and "popular now" items. Filter these by:
- Excluding URLs containing `bing.com`, `microsoft.com`, `live.com`
- Requiring title length > 15 characters
- Excluding relative URLs (start with `/news/topicview`)

## Common Gotchas

1. **"Show inaccessible results"** — Bing sometimes shows a link to unblock region-restricted results. Ignore it.
2. **Trending topics carousel** — Appear as `/news/topicview?q=...` relative links. These are not article results.
3. **Duplicate results across queries** — Deduplicate by URL when running multiple queries.
4. **No results for compound queries** — Simplify: drop specific date ranges, use broader keywords.

## Working Query Examples

```
Iran US war 2026
Iran US military conflict latest 2026
Iran US ceasefire negotiations 2026
Iran US strikes 2026
Iran war Netanyahu Trump July 2026
Iran drone attack Gulf 2026
Iran war casualty Trump bombing
Iran Oman talks ceasefire diplomacy July 2026
Iran nuclear IAEA 2026
```

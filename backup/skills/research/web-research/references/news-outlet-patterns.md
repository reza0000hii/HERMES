# News Outlet Scraping Patterns

## BBC

### RSS Feeds
- Middle East: `https://feeds.bbci.co.uk/news/world/middle_east/rss.xml`
- World: `https://feeds.bbci.co.uk/news/world/rss.xml`
- Top Stories: `https://feeds.bbci.co.uk/news/rss.xml`
- Topics page: `https://www.bbc.com/news/topics/c50v1j4wnx7t` (Iran-related)

### JSON-LD Extraction (most reliable)
BBC articles embed `application/ld+json` with headline, datePublished, description:
```python
import json, re
with open('/tmp/bbc_article.html') as f:
    html = f.read()
m = re.search(r'application/ld\+json[^>]*>(.*?)</script>', html, re.DOTALL)
if m:
    data = json.loads(m.group(1))
    print(data.get('headline'))
    print(data.get('datePublished'))  # ISO 8601
    print(data.get('description'))
```

### Search Page
BBC search (`/search?q=...`) returns server-rendered HTML with article cards.
Headlines in `<h2 data-testid="card-headline">`, dates in `<span data-testid="card-metadata-lastupdated">`.
Article URLs follow pattern `/news/articles/SLUG` or `/news/videos/SLUG`.

### Live Blogs
BBC live blogs at `/news/live/SLUG`. Content is JS-rendered and not extractable via curl. Use RSS or JSON-LD from the main live blog page instead.

---

## Al Jazeera

### RSS Feed
- All content: `https://www.aljazeera.com/xml/rss/all.xml`
- Feed only shows ~20-30 most recent items. Older dates may require tag pages.

### Tag Pages (server-rendered, parseable)
URL: `https://www.aljazeera.com/tag/iran/` (or any topic)

**HTML structure for article cards:**
- Container: `<article class="gc u-clickable-card ...">`
- Title: `<h3 class="gc__title"><a href="URL"><span>TITLE</span></a></h3>`
- Description: `<div class="gc__excerpt"><p>TEXT</p></div>`
- Date: `<span class="screen-reader-text">Published On 29 Jul 2026</span>` inside `<div class="gc__date">`
- Image alt text often contains useful context (e.g., date-stamped captions)

**Regex extraction:**
```python
import re
articles = re.findall(
    r'href="(/(?:news|opinions)/2026/7/\d+/[^"]+)"[^>]*><span>([^<]+)</span>',
    html
)
dates = re.findall(r'Published On (\d+ \w+ \d+)', html)
for i, (href, title) in enumerate(articles):
    d = dates[i] if i < len(dates) else 'unknown'
    print(f'{d}: {title}  ->  https://www.aljazeera.com{href}')
```

### Search Page
Al Jazeera search (`/search?q=...`) is **JS-rendered** — returns only footer/boilerplate via curl. Do NOT use. Use tag pages or RSS instead.

### Live Blogs
URL pattern: `/news/liveblog/YYYY/M/DD/SLUG`
Content is JS-rendered. The page itself only returns the liveblog title and datePublished in JSON-LD, not individual entries.

---

## AP News

### Hub Pages (best for topic research)
URL: `https://apnews.com/hub/TOPIC` (e.g., `/hub/iran`)

**HTML structure:**
- Title: `<span class="PagePromoContentIcons-text">TITLE</span>` inside `<h3 class="PagePromo-title">`
- Timestamp: `<bsp-timestamp data-timestamp="EPOCH_MS">`
- URL: `<a class="Link " href="URL">` inside the title container

**Warning:** Hub page `data-timestamp` may not match original publish date. For accurate dates, fetch each article and check `<meta property="article:published_time">`.

### Search Page
AP search is **JS-rendered** — do NOT use. Use hub pages.

### Article Metadata Extraction (for exact dates)
AP News articles embed `article:published_time` and `article:modified_time` in `<meta>` tags. This is the **most reliable** way to confirm exact publication dates — more reliable than hub page timestamps.

```python
import re
with open('/tmp/ap_article.html') as f:
    html = f.read()
pub = re.findall(r'article:published_time.*?content="([^"]+)"', html)
mod = re.findall(r'article:modified_time.*?content="([^"]+)"', html)
title = re.findall(r'og:title.*?content="([^"]+)"', html)
print(f'Title: {title[0] if title else "N/A"}')
print(f'Published: {pub[0] if pub else "N/A"}')  # ISO 8601, e.g. 2026-07-28T23:27:30
print(f'Modified: {mod[0] if mod else "N/A"}')
```

**Why this matters:** AP News hub page `data-timestamp` values may reflect when an article was placed on the hub, not the original publish date. For date-filtered research, always verify via article-level metadata.

---

## Reuters

### Direct Scraping
Reuters blocks curl with Cloudflare CAPTCHA (~771 bytes response). Use Brave Search with `site:reuters.com` instead — Brave embeds article metadata in its page HTML.

---

## General Pattern for Date-Filtered Research

1. **Google News RSS first** — Search across ALL outlets with `when:Xd` date filter. This is the single most reliable technique for finding articles from a specific date.
2. **RSS feed confirmation** — Check individual outlet RSS feeds to confirm presence/absence of articles.
3. **Tag/hub pages** — Parse article cards for dates.
4. **JSON-LD from individual articles** — For exact date verification.
5. **Brave Search `site:`** — For outlets that block direct scraping.
6. **Confirm negative results** — If nothing found, verify via RSS that the outlet genuinely published nothing.

---

## Google News RSS — Cross-Source Date-Verified Research

The most reliable technique for finding articles from a specific date across all sources.

**URL:** `https://news.google.com/rss/search?q=QUERY+when:Xd&hl=en-US&gl=US&ceid=US:en`

**Source-scoped:** `site:reuters.com+Iran+US` or just `reuters+Iran+US`

**Returns:** Up to 100 `<item>` elements with `<title>`, `<pubDate>` (RFC 2822), `<source>` (outlet name), and `<link>` (article URL).

**Date filtering:** Check `<pubDate>` for target date string (e.g., `'28 Jul 2026' in pubdate`).

**Limitations:** Google News may not index every article from every outlet. For comprehensive coverage, combine with outlet-specific RSS feeds.

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

---

## Reuters

### Direct Scraping
Reuters blocks curl with Cloudflare CAPTCHA (~771 bytes response). Use Brave Search with `site:reuters.com` instead — Brave embeds article metadata in its page HTML.

---

## General Pattern for Date-Filtered Research

1. **RSS feed first** — Check if the outlet's RSS covers the target date
2. **Tag/hub pages** — Parse article cards for dates
3. **JSON-LD from individual articles** — For exact date verification
4. **Brave Search `site:`** — For outlets that block direct scraping
5. **Confirm negative results** — If nothing found, verify via RSS that the outlet genuinely published nothing

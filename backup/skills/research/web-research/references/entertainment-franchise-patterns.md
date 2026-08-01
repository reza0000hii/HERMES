# Entertainment Franchise Research Patterns

## Wikipedia Page Hierarchy for TV/Film Franchises

When researching a franchise (e.g., Game of Thrones), check pages in this order:

1. **Franchise page** (e.g., `A_Song_of_Ice_and_Fire_(franchise)`)
   - Lists ALL series in the franchise
   - Shows current status of each (active, cancelled, in development)
   - Often has the most complete overview of spinoffs

2. **Individual show page** (e.g., `House_of_the_Dragon`)
   - Season renewal status
   - Cast additions
   - Production updates
   - Points to season sub-pages

3. **Season sub-pages** (e.g., `House_of_the_Dragon_season_3`)
   - Episode counts, air dates
   - Ratings data
   - Critical reception

4. **New spinoff pages** (e.g., `A_Knight_of_the_Seven_Kingdoms_(TV_series)`)
   - Premiere date, cast, showrunner
   - Renewal status
   - Production company details

## Key Regex Patterns for TV Show Data

```bash
# Renewal/season status
grep -oiP '(renewed|cancelled|ordered|season [0-9]+)[^.]{0,300}'

# Premiere/air dates
grep -oiP '(premiered|premieres?|aired?|release)[^.]{0,300}(20[0-9]{2})'

# Production status
grep -oiP '(in development|in production|filming|post-production|wrapped)[^.]{0,300}'

# Source attributions (to verify what Variety/Deadline/THR reported)
grep -oiP '(Variety|Deadline|Hollywood Reporter|THR|Entertainment Weekly)[^"]{0,200}'
```

## Entertainment News Site Access — What Works and What Doesn't

### ⚠️ Variety.com is fully JS-rendered — do NOT scrape pages directly

Variety.com's HTML pages (homepage, section pages, tag pages, article pages) return **empty/minimal HTML** via curl — only CSS/JS boilerplate. Tag pages like `variety.com/t/house-of-the-dragon/` and section pages like `variety.com/v/tv/` are NOT server-rendered. Do not waste time trying to parse them.

**What DOES work for Variety:**
1. **WordPress RSS feed** (`https://variety.com/feed/`) — returns full article titles, descriptions, and `<pubDate>` for the most recent ~10 articles. Works perfectly via curl. Filter by date in post-processing.
2. **Google News RSS** with `site:variety.com` — finds articles across all dates, returns `<source>` tag. Best for date-specific research.
3. **Individual article URLs** — return 301 redirects (not 404) for valid articles, so you can verify URLs exist but can't extract content.

### Deadline and Hollywood Reporter — RSS + Homepage Scraping

| Site | Homepage works? | Tag/archive page? | RSS feed works? | Article meta? | Google News `site:` |
|------|----------------|-------------------|-----------------|--------------|---------------------|
| **Deadline** | **YES** — `deadline.com/` and `/2026/07/` archives return server-rendered article blocks with `<h2>` titles, `<time datetime="...">` dates, and full URLs | Tag pages (`/tag/SHOW-SLUG/`) — sometimes server-rendered, test first | `deadline.com/feed/` — works, ~15 items, full `<pubDate>` | Yes — `og:title`, `og:description`, `article:published_time` all extractable | Yes |
| **Hollywood Reporter** | JS-rendered | JS-rendered | `hollywoodreporter.com/feed/` — works, ~10 items, full `<pubDate>` | og:title/description yes; article:published_time NO (JS-rendered) | Yes |
| **Variety** | JS-rendered — DO NOT USE | JS-rendered — DO NOT USE | `variety.com/feed/` — works, primary method | og:title/description sometimes; article:published_time NO (JS-rendered) | Yes, primary for date-specific |

**Deadline homepage scraping detail:** The Deadline homepage (`deadline.com/`) and monthly archive pages (`deadline.com/2026/07/`) return server-rendered HTML containing:
- `<article>` blocks or `<h2>`/`<h3>` tags with article titles
- `<time datetime="2026-07-31T05:09:00-07:00">` timestamps (ISO 8601 with timezone)
- Full article URLs in `<a href="https://deadline.com/2026/07/...">` links
- Article counts of 15-25 per page, with dates clearly visible

To extract today's articles from Deadline's archive page:
```bash
curl -sL -A 'Mozilla/5.0' "https://deadline.com/2026/07/" > /tmp/deadline_archive.html
python3 -c "
import re, html
with open('/tmp/deadline_archive.html') as f:
    c = f.read()
links = re.findall(r'href=\"(https://deadline\.com/2026/07/[^\"]+)\"', c)
seen = set()
for url in links:
    if url not in seen and '#' not in url:
        seen.add(url)
        print(url)
"
```

**`article:published_time` meta tag — works on Deadline only, NOT THR or Variety:** Only Deadline article pages are server-rendered enough to expose this meta tag reliably. THR and Variety article pages are fully JS-rendered — `article:published_time` doesn't appear in raw HTML. For THR/Variety dates, use RSS feeds exclusively. Deadline pattern:
```bash
curl -sL -A 'Mozilla/5.0' "https://deadline.com/ARTICLE_URL" 2>/dev/null | \
  python3 -c "
import sys, re, html as h
c = sys.stdin.read()
title = re.search(r'og:title.*?content=\"([^\"]+)\"', c)
desc = re.search(r'og:description.*?content=\"([^\"]+)\"', c)
date = re.search(r'article:published_time.*?content=\"([^\"]+)\"', c)
print(f'Title: {h.unescape(title.group(1)) if title else \"N/A\"}')
print(f'Desc: {h.unescape(desc.group(1))[:300] if desc else \"N/A\"}')
print(f'Date: {date.group(1) if date else \"N/A\"}')
"
```

**Confirmed:** Both Deadline and THR RSS feeds return server-rendered `<item>` blocks with accurate `<pubDate>` timestamps in RFC 2822 format (e.g., `Fri, 31 Jul 2026 05:09:00 +0000`). Filter by target date string (e.g., `'31 Jul 2026'`) in post-processing.

### Multi-source parallel RSS pattern for entertainment research

When researching entertainment news from multiple outlets on a specific date, run these in parallel:

```bash
# 1. Fetch RSS feeds from all target outlets simultaneously
curl -s -A 'UA' "https://deadline.com/feed/" > /tmp/deadline_rss.xml
curl -s -A 'UA' "https://www.hollywoodreporter.com/feed/" > /tmp/thr_rss.xml
curl -s -A 'UA' "https://variety.com/feed/" > /tmp/variety_rss.xml

# 2. Fetch Google News RSS for each outlet × topic combination
#    Use when:3d to scope to recent articles, add topic keywords
curl -s -A 'UA' \
  "https://news.google.com/rss/search?q=site:deadline.com+TOPIC+when:3d&hl=en-US&gl=US&ceid=US:en" \
  > /tmp/gn_deadline_TOPIC.xml
```

Then parse all feeds, filter by date, and deduplicate by headline. The RSS feeds give the most complete "what they published today" picture; Google News RSS adds cross-reference coverage and catches articles the RSS feed may have dropped.

### Primary technique: RSS feeds + Google News RSS

For entertainment research, **start with RSS feeds**, not page scraping:

```bash
# 1. Check the outlet's RSS feed for today's articles
curl -s -A 'Mozilla/5.0' "https://variety.com/feed/" > /tmp/variety_feed.xml
python3 -c "
import re, html
with open('/tmp/variety_feed.xml') as f:
    xml = f.read()
items = re.findall(r'<item>(.*?)</item>', xml, re.DOTALL)
for item in items:
    title = re.search(r'<title>(.*?)</title>', item)
    pubdate = re.search(r'<pubDate>(.*?)</pubDate>', item)
    desc = re.search(r'<description><!\[CDATA\[(.*?)\]\]></description>', item)
    if title and pubdate and '31 Jul 2026' in pubdate.group(1):
        t = html.unescape(title.group(1))
        d = html.unescape(desc.group(1))[:300] if desc else ''
        print(f'TITLE: {t}')
        print(f'DESC: {d}')
        print()
"

# 2. Cross-reference with Google News RSS (site-scoped)
curl -s -A 'Mozilla/5.0' \
  "https://news.google.com/rss/search?q=site:variety.com+house+of+the+dragon&hl=en-US&gl=US&ceid=US:en" \
  > /tmp/gn_variety.xml
python3 -c "
import re, html
with open('/tmp/gn_variety.xml') as f:
    xml = f.read()
items = re.findall(r'<item>(.*?)</item>', xml, re.DOTALL)
for item in items:
    title = re.search(r'<title>(.*?)</title>', item)
    pubdate = re.search(r'<pubDate>(.*?)</pubDate>', item)
    source = re.search(r'<source[^>]*>(.*?)</source>', item)
    if title and pubdate and '31 Jul 2026' in pubdate.group(1):
        print(f'[{html.unescape(source.group(1)) if source else \"?\"}] {html.unescape(title.group(1))}')
        print(f'  Date: {pubdate.group(1)}')
"
```

**Why both?** The Variety RSS feed only has ~10 items (latest articles). Google News RSS indexes more articles but may miss some. Using both gives comprehensive coverage.

### Deadline tag page scraping (when it works)

Deadline's tag pages sometimes return server-rendered HTML. Test first, then parse:

```bash
curl -sL -A 'Mozilla/5.0' "https://deadline.com/tag/house-of-the-dragon/" | \
  grep -oP '<h[23][^>]*>(.*?)</h[23]>' | \
  sed 's/<[^>]*>//g' | head -10
```

**If empty HTML is returned** (JS-rendered), fall back to Google News RSS with `site:deadline.com`.

### Meta description extraction for article summaries

Even on JS-heavy sites like THR and Deadline, `<meta name="description">` and `<meta property="og:description">` tags are server-rendered and always available via curl. This is the fastest way to get a 1-sentence summary of an article without parsing body text:

```bash
curl -s -A 'Mozilla/5.0 ...' "https://deadline.com/ARTICLE-URL" 2>/dev/null | \
  python3 -c "
import sys, re
content = sys.stdin.read()
desc = re.findall(r'<meta[^>]*name=\"description\"[^>]*content=\"([^\"]+)\"', content)
if not desc:
    desc = re.findall(r'<meta[^>]*property=\"og:description\"[^>]*content=\"([^\"]+)\"', content)
title = re.findall(r'<meta[^>]*property=\"og:title\"[^>]*content=\"([^\"]+)\"', content)
print('TITLE:', title[0] if title else 'N/A')
print('DESC:', desc[0] if desc else 'N/A')
"
```

**Note:** THR article URLs are not predictable from headlines — always get the exact URL from the RSS feed or Google News RSS `<link>` tag. Guessed URLs return 404/N/A.

### Individual article scraping — keyword extraction from body text

Entertainment articles on working sites often contain structured data in `<p>` tags. Extract with keyword searches:
```bash
curl -sL -A 'Mozilla/5.0' "https://deadline.com/ARTICLE-URL" | \
  python3 -c "
import sys, re, html
content = sys.stdin.read()
text = html.unescape(re.sub(r'<[^>]+>', ' ', content))
text = re.sub(r'\s+', ' ', text)
for kw in ['Episode 1', 'premiere', 'viewers', 'season 4']:
    idx = text.lower().find(kw.lower())
    if idx > -1:
        print(text[max(0,idx-100):idx+300])
"
```

## Wikipedia Content Quirks

- Categories at top contain useful metadata (e.g., "2026 American television series debuts")
- `RLCONF` JSON blob contains structured page metadata
- Episode tables are embedded as wikitext templates, not always visible in HTML
- References section contains the actual Variety/Deadline/THR links
- Some pages redirect (e.g., `House_of_the_Dragon_season_4` → `House_of_the_Dragon`)

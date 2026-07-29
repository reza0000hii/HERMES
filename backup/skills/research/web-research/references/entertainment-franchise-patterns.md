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

## Direct Entertainment News Site Scraping

When searching for TV show / film franchise news, skip search engines and go **directly** to entertainment news tag/hub pages. These are server-rendered, CAPTCHA-free, and return article titles reliably.

**Tag page URL patterns:**

| Site | URL Pattern | Notes |
|------|-------------|-------|
| Variety | `https://variety.com/t/SHOW-SLUG/` | Slug uses hyphens (e.g., `house-of-the-dragon`) |
| Deadline | `https://deadline.com/tag/SHOW-SLUG/` | Uses `/tag/` prefix |
| Hollywood Reporter | `https://www.hollywoodreporter.com/t/SHOW-SLUG/` | Same as Variety pattern |

**Parsing tag pages:** Extract `<h2>` and `<h3>` titles that contain the show name. These are article headlines — follow up by fetching individual articles for details.

```bash
curl -sL -A 'Mozilla/5.0' "https://deadline.com/tag/house-of-the-dragon/" | \
  grep -oP '<h[23][^>]*>(.*?)</h[23]>' | \
  sed 's/<[^>]*>//g' | head -10
```

**Individual article scraping:** Entertainment articles often contain structured data (episode schedules, viewership numbers) in `<p>` tags. Extract with keyword searches:
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

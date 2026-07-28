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

## Wikipedia Content Quirks

- Categories at top contain useful metadata (e.g., "2026 American television series debuts")
- `RLCONF` JSON blob contains structured page metadata
- Episode tables are embedded as wikitext templates, not always visible in HTML
- References section contains the actual Variety/Deadline/THR links
- Some pages redirect (e.g., `House_of_the_Dragon_season_4` → `House_of_the_Dragon`)

# Wikipedia HTML Table Extraction for Structured Data

When you need structured tabular data from Wikipedia (release schedules, rankings, comparison tables), the standard `action=parse` wikitext API can be unwieldy for large tables with templates. **Downloading the full HTML and parsing `<table>` elements with Python** is often more reliable for extracting clean row data.

## When to Use This Pattern

- Release calendar tables (e.g., "List of American films of 2026" — 97+ rows, 170KB+ table)
- Box office rankings, comparison tables, multi-month schedules
- Tables where wikitext templates obscure the actual data
- Any article with multiple tables covering different periods/sections

## Step-by-Step Pattern

### 1. Download the full HTML page
```bash
curl -sL --max-time 15 "https://en.wikipedia.org/wiki/ARTICLE" \
  -H "User-Agent: Mozilla/5.0" -o /tmp/wiki_page.html
```

### 2. Find table boundaries (critical for large pages)
Wikipedia HTML pages can be 1-2MB. Tables don't always have unique IDs, so use **offset-based extraction**:

```python
import re, html as h

with open('/tmp/wiki_page.html', 'r', encoding='utf-8', errors='replace') as f:
    text = f.read()

# Find all opening table tags and their closing tags
for m in re.finditer(r'<table[^>]*>', text):
    abs_offset = m.start()
    close_idx = text.find('</table>', abs_offset)
    if close_idx > 0:
        print(f"Table at {abs_offset}, length {close_idx - abs_offset}")
        print(f"  Tag: {m.group()[:80]}")
```

### 3. Extract rows with correct offsets
```python
# Use known offsets from step 2
table_start = ABS_START_OFFSET
table_end = ABS_END_OFFSET + len('</table>')
table = text[table_start:table_end]

rows = re.findall(r'<tr[^>]*>(.*?)</tr>', table, re.DOTALL)
print(f"Table has {len(rows)} rows")

for i, row in enumerate(rows):
    cells = re.findall(r'<t[dh][^>]*>(.*?)</t[dh]>', row, re.DOTALL)
    clean = [re.sub(r'<[^>]+>', '', h.unescape(c)).strip()[:100] for c in cells]
    if clean and len(''.join(clean)) > 5:
        print(f"Row {i}: {' | '.join(clean)}")
```

### 4. Handle section/month markers within tables
Large tables often have month or category headers as special rows. Track them:

```python
current_section = "DEFAULT"
for i, row in enumerate(rows):
    cells = re.findall(r'<t[dh][^>]*>(.*?)</t[dh]>', row, re.DOTALL)
    clean = [re.sub(r'<[^>]+>', '', h.unescape(c)).strip()[:100] for c in cells]
    if clean:
        first = clean[0].upper()
        # Detect section markers (JULY, AUGUST, etc.)
        for marker in ['JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER']:
            if marker in first:
                current_section = marker
        print(f"[{current_section}] {' | '.join(clean)}")
```

## Pitfalls

1. **Regex `</table>` match fails on massive tables** — For tables >100KB, `re.search(r'<table...>(.*?)</table>', text, re.DOTALL)` may fail or return None. Use **manual offset extraction** instead: find opening tag position, then `text.find('</table>', start_pos)` for the close.

2. **Table spans multiple wiki section headings** — A "July–September" section may have ONE table containing all three months. Don't assume section boundaries = table boundaries.

3. **`aria-label` attributes contain section names** — Month markers in Wikipedia tables often use `aria-label="JULY"` or `id="mwFMg"` patterns. These are more reliable than cell text for detecting section transitions.

4. **`errors='replace'` is essential** — Wikipedia HTML contains multi-byte UTF-8 characters (em dashes, accented names). Without `errors='replace'`, Python may crash on decode errors.

5. **Table ID attributes are unreliable** — Wikipedia auto-generates IDs like `mwFLw`, `mwHDY` that change with edits. Don't hardcode them; always discover offsets dynamically.

## Example: Movie Release Calendar

The "List of American films of 2026" page contains a single `<table>` with 97 rows covering July–September releases, organized by month markers. Key structure:

- **Header row**: Opening | Title | Production company | Cast and crew | Ref
- **Month rows**: `JULY | 1 |` (date is second cell)
- **Title rows**: Movie title without date prefix
- **References**: Numbered `[264]` linking to Variety/Deadline/THR sources

This pattern repeats for other franchise/release calendar Wikipedia pages.

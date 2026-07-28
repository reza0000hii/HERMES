# Supabase SPA Data Extraction

## Problem
React/Vue SPAs backed by Supabase don't expose data via traditional HTML.
The data loads client-side via Supabase REST API, so curl on the HTML returns nothing.

## Solution: Extract Credentials from JS Bundle

### Step 1: Download the JS bundle
```bash
curl -s "https://example.com/assets/index-*.js" \
  -H "Referer: https://example.com/" \
  -H "User-Agent: Mozilla/5.0" \
  -o /tmp/app.js
```

### Step 2: Find the Supabase project ID
Look for the project ID in the JS (appears in URLs):
```
grep -oP '[a-z0-9]{20,}\.supabase\.co' /tmp/app.js
```

### Step 3: Extract the anon key (JWT)
The anon key appears near the Supabase URL reference in the JS.
It's a long JWT (typically 200+ chars):
```
python3 -c "
import re
data = open('/tmp/app.js').read()
pattern = r'\"https://<project-id>\.supabase\.co\",\s*\"(eyJ[^\"]+)\"'
match = re.search(pattern, data)
if match: print(match.group(1))
"
```

### Step 4: Query the REST API
```bash
curl -s "https://<project-id>.supabase.co/rest/v1/<table>?select=*&limit=5" \
  -H "apikey: <anon-key>" \
  -H "Authorization: Bearer <anon-key>"
```

## Common Pitfalls
- Some SPAs use multiple JS chunks; check for `index-*.js` patterns
- The anon key may be split across chunks; search near the supabase URL reference
- Rate limits may apply; add delays between bulk queries
- Some tables require auth (not just anon key)

## Worked Example: fundbase.ir

Project ID: `fyeguwhlfqhomqpkbgxb`
Tables: `funds`, `fund_live_data`, `categories`, `fund_return_data`
Gold category ID: `b4096a4d-122e-4bf3-821b-7ce484d1cb5b`

Query gold funds with bubble data:
```bash
curl -s "https://fyeguwhlfqhomqpkbgxb.supabase.co/rest/v1/funds?category_id=eq.b4096a4d-122e-4bf3-821b-7ce484d1cb5b&select=id,name,slug" \
  -H "apikey: <key>" -H "Authorization: Bearer <key>"
```

Join with fund_live_data for bubble analysis:
```bash
curl -s "https://fyeguwhlfqhomqpkbgxb.supabase.co/rest/v1/fund_live_data?select=fund_id,bubble_percent,bubble_amount,current_price,nav&order=bubble_percent.desc" \
  -H "apikey: <key>" -H "Authorization: Bearer <key>"
```

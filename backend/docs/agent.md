# Wirtualny Dziekanat – Webpage Analysis
> Findings from scraper debugging session (2026-03-03)

## Site Overview

- **URL pattern**: `https://plany.am.szczecin.pl/Plany/PlanyTokow/{flow_id}`
- **Stack**: ASP.NET MVC with DevExpress UI controls (v4.3.0.93)
- **Theme**: DevExpress iOS skin — all CSS classes are suffixed `_iOS` (e.g. `dxgvGroupRow_iOS`, `dxgvDataRow_iOS`)
- **Language**: Defaults to **English** on a fresh Selenium session. Polish requires navigating to `/ZmienJezyk?lang=pl`, which sets a session cookie. **Do not use the dropdown click to change language** — use `driver.get('https://plany.am.szczecin.pl/ZmienJezyk?lang=pl')` directly, then `driver.get(url)` to reload the plan page. Clicking the dropdown programmatically causes Chrome to close the window unexpectedly after ~43 seconds.

---

## Page Load Behaviour

### IDs to watch
| ID | Element | Purpose |
|----|---------|---------|
| `cc_essential` | Cookie consent banner | Present on first visit / cleared cookies |
| `ho-language` | Language dropdown button | Toggles between PL/EN |
| `gridViewPlanyTokow` | DevExpress grid `<table>` | Outer grid container |
| `gridViewPlanyTokow_DXMainTable` | Inner data `<table>` | The actual rows to scrape |
| `loading-wrapper` | Overlay spinner | Only visible **during DevExpress AJAX callbacks**, NOT during initial page load — waiting for its invisibility is a no-op on page load |
| `SzukajLogout` | Search/filter button (`<a>` tag) | Triggers `FiltrujDane()` |

### Initial render — CRITICAL FINDING
The **initial page renders with empty data in a fresh Selenium session**. The grid only contains header rows (`gridViewPlanyTokow_DXHeadersRow0`) with no `dxgvGroupRow_iOS` or `dxgvDataRow_iOS` rows.

This is because:
- In a fresh session the **default selected radio is "Dzisiaj" (index 0, today only)**, NOT "Najbliższe zajęcia" as the HTML attribute `Checked="checked"` on radio index 2 might suggest.
- The server renders the grid for "today only" on first load. If there are no classes today, the grid is empty.
- The `source.html` showing populated data was captured from a **browser session with prior filter state stored server-side** — it does not reflect what a fresh Selenium session sees.

Verified via JS:
```python
driver.execute_script('return { od: MVCxDataOd.GetDate()?.toString(), do: MVCxDataDo.GetDate()?.toString() }')
# Fresh session result: both dates = today (e.g. Tue Mar 03 2026)
```

### What the 15 "empty" rows are
`tbody.find_elements(By.TAG_NAME, "tr")` finds ALL `<tr>` elements including those **nested inside the header row** (`DXHeadersRow0`). Each column header is its own `<tr>` inside a nested table — hence ~13-15 rows with no class. These are not data rows.

---

## DevExpress Grid

### JavaScript variable
`ASPx.createControl(MVCxClientGridView, 'gridViewPlanyTokow', ...)` creates the global JS object `window.gridViewPlanyTokow`. This overrides the implicit browser global (the HTML element). Confirmed working in Selenium: `typeof gridViewPlanyTokow === 'object'` and `typeof gridViewPlanyTokow.PerformCallback === 'function'`.

### Callback URL
```
POST /Plany/PlanyTokowGrid/{plan_id}
```
`plan_id` is the **internal ASP.NET plan ID** (e.g. 419), distinct from the **flow_id** used in the URL (e.g. 100). The plan_id is embedded in the `SzukajLogout` button's onclick attribute and in the grid's `callbackUrl`.

### `callbackState`
A long base64-encoded blob embedded in the page JS. Sent with every `PerformCallback` call. Server uses it to validate the callback context. Tied to the current session/page render — if the session or page state changes, the callback may return empty results.

### Outer grid CSS class `dxgvAE`
When the grid is empty (no data rows), the outer `<table id="gridViewPlanyTokow">` has the additional class `dxgvAE`. This can be used to detect empty grid state without parsing rows.

---

## Date Editors

Both date pickers use DevExpress `MVCxClientDateEdit`:

| JS variable | HTML ID | Fresh session value | After radio[2] click |
|------------|---------|--------------------|-----------------------|
| `MVCxDataOd` | `DataOd` | today (e.g. Mar 3) | Mar 2, 2026 |
| `MVCxDataDo` | `DataDo` | today (e.g. Mar 3) | Apr 1, 2026 |

Date formatter: `dd.MM.yyyy` (Polish format). This is **display-only** — `GetDate()` always returns a standard JS `Date` object regardless of locale. `FiltrujDane` uses `getFullYear()`, `getMonth()+1`, `getDate()` so locale has no effect on what is sent to the server.

Both pickers fire `ZmianaDaty` on `DateChanged`.

---

## Key JavaScript Functions (defined in `/Scripts/bundles/Main`)

### `RadioButtonZmiana(radioBt)`
Called by each radio button's `onclick`. Parses the radio's `value` attribute (`"YYYY,M,D\YYYY,M,D\index"`) and calls `MVCxDataOd.SetDate()` / `MVCxDataDo.SetDate()` to update the date pickers. **Does not trigger any grid AJAX reload** — it only updates the date picker values. The user confirmed this.

```javascript
function RadioButtonZmiana(radioBt) {
    var d = radioBt.value.split('\\');
    // d[0] = start date "YYYY,M,D", d[1] = end date "YYYY,M,D"
    MVCxDataOd.SetDate(new Date(year, month - 1, day));
    MVCxDataDo.SetDate(new Date(year, month - 1, day));
}
```

### `FiltrujDane(grid, id)`
Called by the `SzukajLogout` button. Reads dates from the DevExpress date objects (NOT from raw input values) and fires a DevExpress grid callback.

```javascript
function FiltrujDane(grid, id) {
    // Returns early (with alert) if either date is null
    if (MVCxDataOd.GetDate() == null || MVCxDataDo.GetDate() == null)
        return alert('Uzupełnij daty');

    // Builds param string: "YYYY-M-D;YYYY-M-D;radioIndex"
    // radioIndex: 0=today, 1=this week, 2=nearest classes, 5=custom (none selected)
    var zazButton = 5;
    for (var i = 0; i < 4; i++) { /* finds checked radio, sets zazButton = i */ }

    var parametr = dataOd_str + ";" + dataDo_str + ";" + zazButton + ";" + id;
    grid.PerformCallback({ parametry: parametr, id: id });
}
```

**Known failure modes:**
- `MVCxDataOd.GetDate()` returns `null` → early return with alert, no AJAX, table never goes stale
- Fresh session defaults to "Dzisiaj" dates → if no classes today, `PerformCallback` returns empty grid
- `gridViewPlanyTokow` is the raw HTML element (not DevExpress object) → `TypeError` on `.PerformCallback()`
- `callbackState` mismatch → server returns empty grid
- `arguments[0].click()` JS click sets `event.isTrusted = false` — DevExpress may handle untrusted clicks differently. Prefer Selenium's `.click()` for `SzukajLogout`.

---

## Radio Buttons

| Index | Label | Radio value | Date range set by RadioButtonZmiana |
|-------|-------|-------------|--------------------------------------|
| 0 | Dzisiaj | `2026,3,3\2026,3,3\0` | Today only (**actual fresh-session default**) |
| 1 | Ten tydzień/zjazd | `2026,3,2\2026,3,8\1` | Current week |
| 2 | Najbliższe zajęcia | `2026,3,2\2026,4,1\2` | Mar 2 – Apr 1 2026 |

**The HTML `Checked="checked"` on radio index 2 is misleading** — in a fresh Selenium session, the effective server-side default is "Dzisiaj" (today). The radio click is **required** to switch to a useful date range before calling `FiltrujDane`.

After clicking `custom-control-label[2]`, dates correctly change to Mar 2 – Apr 1 (verified with JS). Selenium's `.click()` on the label triggers `RadioButtonZmiana` synchronously.

---

## Cookie Consent

The `cc_essential` popup appears on fresh sessions. The scraper dismisses it by clicking `driver.find_elements(By.CSS_SELECTOR, "button.btn.my-2")[1]` — the **second** button matching that selector. Cookie is session-scoped and persists across `driver.get()` calls within the same Selenium session. After dismissal, navigating to `/ZmienJezyk?lang=pl` and back does NOT re-trigger the popup.

---

## CSS Row Classes (for scraping)

After DevExpress renders the grid with data, rows use these classes:

| Class | Row type | Content |
|-------|----------|---------|
| `dxgvGroupRow_iOS` | Date group header | Contains "Data Zajęć: YYYY.MM.DD dzień" in `td.dxgv.dxgRRB` at index [1] |
| `dxgvDataRow_iOS` | Schedule entry | `all_tds[1:-1]` gives the data cells (first and last are indent/adaptive cells) |

Data cell order in a `dxgvDataRow_iOS` row (0-indexed from `all_tds[1]`):
`Czas od, Czas do, Liczba godzin, Grupy, Przedmiot, Forma zajęć, Nr uruch., Sala, Prowadzący, Forma zaliczenia, Id uruch., Uwagi`

---

## Required Scraping Flow

```
1. driver.get(plan_url)                          # English by default
2. wait for cc_essential → click dismiss button  # cookies
3. driver.get('/ZmienJezyk?lang=pl')             # set Polish language cookie (NOT via dropdown)
4. driver.get(plan_url)                          # reload in Polish
5. wait for gridViewPlanyTokow_DXMainTable
6. click custom-control-label[2]                 # switch radio to "Najbliższe zajęcia"
7. [brief pause if needed for RadioButtonZmiana]
8. old_table = find(gridViewPlanyTokow_DXMainTable)
9. find(SzukajLogout).click()                    # trigger FiltrujDane — use Selenium .click(), NOT JS
10. wait staleness_of(old_table)                 # wait for AJAX table reload
11. [brief sleep for render]
12. re-find table, parse dxgvGroupRow_iOS / dxgvDataRow_iOS rows
```

**Outstanding issue (as of 2026-03-03):** Even with the correct language, radio selection, and dates (Mar 2 – Apr 1 confirmed via JS), `PerformCallback` still returns a table with only header rows and no data rows. Root cause not yet confirmed — likely a server-side session requirement or the `callbackState` not matching. Next step: inspect the actual HTTP request/response from the AJAX callback (network tab) to see what the server returns and why.

---

## Language Change — What NOT to do

| Approach | Result |
|----------|--------|
| Click `ho-language` dropdown then XPATH link | Chrome window closes after ~43s with "web view not found" |
| `wait.until(staleness_of(body))` after language click | Waits for a second navigation that never comes; wrong approach |
| `wait.until(invisibility_of(loading-wrapper))` | Passes instantly — loading-wrapper is only shown during AJAX, not page load |
| `driver.get('/ZmienJezyk?lang=pl')` then `driver.get(url)` | **Works correctly** |

---

# Backend Architecture

## Project Structure

```
backend/
├── main.py                         # Entry point — runs the full pipeline
├── pytest.ini                      # pytest config (registers "slow" marker)
├── requirements.txt
├── docs/
│   ├── agent.md                    # This file
│   ├── source.html                 # Captured page HTML for reference
│   └── structure.xml               # Reference university structure
├── mapper/
│   ├── __init__.py                 # Re-exports Mapper
│   ├── mapper.py
│   └── test_mapper.py
├── scrapper/
│   ├── __init__.py                 # Re-exports Scrapper
│   ├── scrapper.py
│   └── test_scrapper.py
├── parser/
│   ├── __init__.py                 # Re-exports Parser
│   ├── parser.py
│   └── test_parser.py
├── json2db/
│   ├── __init__.py                 # Re-exports json2db
│   ├── json2db.py
│   └── test_json2db.py
├── structure_updater/
│   ├── __init__.py                 # Empty (side-effect code at module level)
│   ├── structure_updater.py
│   └── test_structure_updater.py
├── logs/                           # All log files land here (gitignored)
└── output/                         # All JSON outputs land here (gitignored)
```

Each module re-exports its public class from `__init__.py` so `main.py` can do `from mapper import Mapper` etc.

---

## Data Pipeline

```
Mapper → Scrapper → Parser → json2db
```

| Step | Input | Output | Description |
|------|-------|--------|-------------|
| `Mapper` | ID range | `output/mapper.json` | HTTP GET each ID, detect valid plan pages by presence of "Plan dla toku:" string |
| `Scrapper` | `output/mapper.json` | `output/scrapper.json` | Selenium scrape per flow_id, outputs flat list of schedule rows |
| `Parser` | `output/scrapper.json` | `output/parser.json` | Normalises data, deduplicates, extracts teachers/rooms/subjects, converts dates to UNIX timestamps |
| `json2db` | `output/parser.json` | Supabase DB | Upserts all entities into Supabase tables |

The `structure_updater` is a **separate pipeline** — it populates the university structure tables independently of the schedule pipeline.

---

## Module Details

### Mapper (`mapper/mapper.py`)
- `Mapper(output="./output/mapper.json")`
- `run(minID, maxID)` — parallel HTTP GETs using `ThreadPoolExecutor(max_workers=10)`
- Detects valid plans by parsing HTML with BeautifulSoup: looks for `"Plan dla toku:"` string then the next `<strong>` tag for the name
- Output format: `{ "flow_id": "plan_name", ... }`
- Logging: `./logs/mapper.log` (mode `w+`)

### Scrapper (`scrapper/scrapper.py`)
- `Scrapper(debug, output, input)`
- `run(max_workers=5, flow_id=-1)` — if `flow_id == -1`, reads all IDs from mapper output; otherwise scrapes single ID
- `scrapper(flow_id, progress=None)` — single-ID Selenium scrape
- Stats: `success`, `download_fail`, `interaction_fail`, `parse_fail`, `total`
- Thread-safe via `threading.Lock()` on `self.results` and `self.stats`
- Chrome flags required for headless parallel: `--headless=new`, `--no-sandbox`, `--disable-dev-shm-usage`
- **Critical**: `os._exit(1)` was replaced with `return` — using `os._exit` kills the entire process from a thread, stopping the progress bar and all other threads
- `future.result()` is wrapped in `try/except` so one thread's exception doesn't stall the progress loop
- Output: list of flat schedule-row dicts with Polish field names
- Fields in each row: `Plan dla toku`, `Data zajęć`, `Czas od`, `Czas do`, `Liczba godzin`, `Grupy`, `Przedmiot`, `Forma zajęć`, `Sala`, `Prowadzący`, `Forma zaliczenia`, `Uwagi`
- Logging: `./logs/scrapper.log` (mode `w+`)

### Parser (`parser/parser.py`)
- `Parser(debug, input, output, outputFile)`
- Reads scrapper output JSON, normalises into structured data
- Key parsing:
  - `tokStringToDic` — extracts `program_type` (S/N), `degree_level` (lic/mgr/inż.), `language` (POL/ANG), `course_length`, `academic_year`, `name` from the raw "Plan dla toku" string
  - `parseTeachers` — recursive split by academic title prefixes (`prof.`, `dr`, `mgr`)
  - `breakDownRoom` — splits room string into `(room, building)` — known buildings: `WChrobrego`, `HPobożnego`, `Willowa`, `Szczerbcow`, `Żołnierska`
  - `convertDateToTimestamp` — date format is `YYYY.MM.DD dzień` (Polish locale, scraper strips the day name)
  - Classes with comma-separated groups are split into separate records
- Output JSON keys: `programs`, `classes`, `teachers`, `teachersclasses`, `subjects`, `rooms`, `building`
- Uses index-based cross-referencing (e.g. `"program": 3` means `programs[3]`)

### json2db (`json2db/json2db.py`)
- `json2db(input)` — loads JSON from file immediately at `__init__`
- `run()` — calls `load_env()` then all loaders in order
- Table load order (dependency-safe): teachers → buildings → rooms → programs → classes → teachersclasses
- All inserts use `upsert` with conflict keys — safe to re-run
- `clear_db()` exists but is commented out in `run()` — uses `neq("id", "00000000-...")` pattern for full table delete

### Supabase DB Tables (schedule pipeline)

| Table | Key columns | Upsert conflict |
|-------|-------------|-----------------|
| `teachers` | `fullName`, `title` | `fullName, title` |
| `building` | `name` | `name` |
| `rooms` | `name`, `building` (FK) | `name, building` |
| `programs` | `name`, `programType`, `degreeLevel`, `language`, `academicYear`, `courseLength` | all of those |
| `classes` | `subject`, `startTime`, `group`, `program` (FK), `room` (FK), `notes` | `subject, startTime, group` |
| `teachersclasses` | `teachers` (FK), `classes` (FK) | `teachers, classes` |

---

## structure_updater (`structure_updater/structure_updater.py`)

Independent pipeline that populates the university hierarchy tables in Supabase.

### Supabase DB Tables (structure pipeline)

| Table | Key columns |
|-------|-------------|
| `faculties` | `id`, `name` |
| `degree_courses` | `id`, `name`, `faculty_id` |
| `specialisations` | `id`, `name`, `degree_course_id` |

### Data Sources

**Web (default, `--source web`)**: Scrapes `https://plany.am.szczecin.pl/Plany/ZnajdzTok?Ukryj=True`

The site uses **DevExpress ASP.NET MVC combo boxes** with dependent dropdowns. The endpoints are:

| Endpoint | Method | POST body | Response |
|----------|--------|-----------|----------|
| `/Plany/ZnajdzTok?Ukryj=True` | GET | — | Full page HTML containing `Wydzialy` listbox |
| `/Plany/ZnajdzTokKierunekCombo` | POST | `wydzialy=<id>` | HTML fragment with `Kierunki` listbox |
| `/Plany/ZnajdzTokSpecjalnoscCombo` | POST | `wydzialy=<id>&kierunki=<id>` | HTML fragment with `Specjalnosci` listbox |

Required header: `X-Requested-With: XMLHttpRequest`

**XML fallback (`--source xml`)**: Reads `docs/structure.xml` (or `--xml-path` argument).

### `_extract_items(html, control_name)` — DevExpress JS Parser

DevExpress embeds listbox data directly in page JS as:
```javascript
ASPx.createControl(MVCxClientListBox,'Kierunki_DDD_L','',{
    'itemsInfo':[
        {'value':'','text':''},
        {'value':'787','text':'Informatyka'},
        ...
    ],...
});
```

The parser:
1. Finds the marker string `'{control_name}_DDD_L'`
2. Bracket-counts from `'itemsInfo':[` to find the matching `]`
3. Converts single quotes to double quotes (JS → JSON) via regex
4. Parses with `json.loads`
5. Filters out blank `value` entries (the "select one..." placeholder)
6. Normalises whitespace with `' '.join(x['text'].split())` (collapses internal spaces, strips edges, preserves capitalisation)

### Parallelism

- All `Wydziały` fetched in parallel (thread pool, 7 workers)
- For each `Wydział`, all its `Kierunki` fetched in parallel (10 workers)
- All `Specjalności` for a `Wydział`'s `Kierunki` fetched in parallel (10 workers)
- Results sorted by `value` ID to ensure deterministic order before inserting

### DB Write Strategy

3 bulk inserts total (not N individual inserts):

```python
# 1 — all faculties
faculty_rows = db.table("faculties").insert([{"name": f["name"]} for f in structure]).execute()

# 2 — all degree courses (with faculty_id from returned data)
dc_rows = db.table("degree_courses").insert([
    {"name": dc["name"], "faculty_id": row["id"]}
    for faculty, row in zip(structure, faculty_rows.data)
    for dc in faculty["degree_courses"]
]).execute()

# 3 — all specialisations (with degree_course_id from returned data)
db.table("specialisations").insert([
    {"name": spec, "degree_course_id": row["id"]}
    for dc, row in zip(degree_courses_flat, dc_rows.data)
    for spec in dc["specialisations"]
]).execute()  # only called if specialisations_flat is non-empty
```

`clear_structure_tables` deletes via `.delete().gte("id", 0)` to work around Supabase RLS requiring a WHERE clause.

### CLI Arguments

```
python -m structure_updater.structure_updater
  --source {web,xml}     # default: web
  --xml-path PATH        # default: structure.xml (used only with --source xml)
  --dry-run              # print JSON to stdout, skip DB write
```

Dry-run always writes to `./output/structure_updater.json` before exiting. Stdout is clean JSON only.

### Known Differences: Web vs XML

| Aspect | Web | XML (`docs/structure.xml`) |
|--------|-----|----------------------------|
| "Szkoła Doktorska" | Present | Missing |
| Mechatronika faculty | "Mechatroniki i Elektrotechniki" | "Mechatroniki i robotyki" |
| Faculty name format | Short (e.g. "Informatyki") | Full (e.g. "Wydział Informatyki") in some cases |
| Whitespace | May have double spaces → normalised | Usually clean |

### Logging

`./logs/structure_updater.log`, mode `w+`, format `%(asctime)s [%(levelname)s] %(message)s`.

---

## Testing Setup

### pytest.ini

```ini
[pytest]
markers =
    slow: marks tests that make real network or Selenium calls (deselect with -m "not slow")
```

Run fast tests only: `pytest -m "not slow"`
Run slow (live) tests: `pytest -m slow`

### Coverage (fast tests only, `pytest -m "not slow"`)

| Module | Coverage | Notes |
|--------|----------|-------|
| `parser/parser.py` | 99% | 2 dead-code lines (see below) |
| `structure_updater/structure_updater.py` | 72% | `fetch_structure_from_web` only covered by slow tests |
| `json2db/json2db.py` | 15% | All Supabase I/O — expected |
| `scrapper/scrapper.py` | 11% | Selenium — expected |
| `mapper/mapper.py` | 14% | Selenium — expected |

Install coverage tool: `pip install pytest-cov`. Generate lcov for VSCode Coverage Gutters extension:
```bash
pytest --cov=. --cov-report=lcov:coverage/lcov.info -m "not slow"
```

### Known dead code / bugs found via coverage

- **`parser.py:120-121`** — `except` block in `tokStringToDic` is unreachable: if no degree level is found `tok['degree_level']` stays `""` and `original.split("")` raises `ValueError` at line 99, *outside* the try block. The except never fires.
- **`parser.py:269`** — `else: pop(old)` in `run()` for MAP entries where `MAP[old]` is falsy — currently all MAP values are non-empty strings, so branch is dead.
- **`parser.py:280`** (fixed) — previously `self.sched.classes[535]` hardcoded index in DEBUG mode caused `IndexError` on datasets with fewer than 536 classes. Fixed to use `self.sched.classes[0]` with a guard.

### Test Files Summary

| File | Tests | Notes |
|------|-------|-------|
| `mapper/test_mapper.py` | `@pytest.mark.slow` — real HTTP | Skipped if `output/mapper.json` not found |
| `scrapper/test_scrapper.py` | 2 `@pytest.mark.slow` Selenium tests | ID 404 = valid (has data); ID 1 = invalid (`interaction_fail=1`) |
| `parser/test_parser.py` | 11 unit + integration tests | Skipped if `output/scrapper.json` not found |
| `json2db/test_json2db.py` | Integration — calls `json2db()` | Skipped if `output/parser.json` not found |
| `structure_updater/test_structure_updater.py` | 21 unit tests + 2 slow | See below |

### parser Tests

**`parseTeachers`** (4 tests): single dr, multiple dr, **prof branch** (requires teacher string where `prof.` is found after position 1 and `dr` is at position 0 so `find("dr ", 7)` misses it), empty string.

**`tokStringToDic`** (2 tests): standard parse, no-degree-level raises `ValueError`.

**`Parser(debug=True)`** (1 test): verifies DEBUG mode works on small datasets after fixing hardcoded index 535.

**Bugs found in tests**: room `None` for PSM plan 457 caused by `\xa0` before `, ` separator in sala strings — `parseRooms` already strips it correctly, but `parser.json` was stale (generated before the fix was applied).

### structure_updater Tests

**`_extract_items`** (9 tests): blank value filtering, text/value preservation, whitespace stripping, internal space collapse, unknown control name → empty list, capitalisation preserved, **no `itemsInfo`** (line 40), **unbalanced brackets** (line 55).

**`parse_university_structure`** (4 tests): shape, specialisations list, empty specialisations, real XML (skipped if not found).

**`propagate_structure_to_db`** (4 tests): mocked Supabase — uses `MagicMock` with **stable per-table caching** (critical: `db.table.side_effect` returns a new `MagicMock` each call by default; must cache in a dict to allow `assert_called_once_with` to work correctly):

```python
def _make_db_mock(faculty_ids=None, dc_ids=None):
    db = MagicMock()
    _tables = {}
    def _tbl(name):
        if name not in _tables:
            tbl = MagicMock()
            # set return values per table name
            _tables[name] = tbl
        return _tables[name]
    db.table.side_effect = _tbl
    return db
```

**`clear_structure_tables`** (1 test): mocked db, verifies delete called on all 3 tables.

**`main()`** (3 tests): dry-run with xml, missing env vars → prints error and exits cleanly, `clear_structure_tables` raises → `RuntimeError` propagated. Uses `monkeypatch.setattr(su, "create_client", lambda *_: fake_db)` to inject mock DB.

**`fetch_structure_from_web`** (2 `@pytest.mark.slow` tests): shape validation and whitespace checks against live site.

---

## Environment Variables

Both pipelines use `.env` at the backend root:

```
SUPABASE_URL=https://...supabase.co
SUPABASE_KEY=...
```

Loaded via `python-dotenv`. Missing variables cause an error log and early exit (not an exception) in the main entry points.

`SUPABASE_SERVICE_KEY` (service role key) is optional but required for:
- `json2db clear_db()` — deletes all rows from schedule tables (bypasses RLS and statement timeout)
- `news_tool` — image uploads to Supabase Storage

If `SUPABASE_SERVICE_KEY` is absent, `json2db` falls back to the anon key for `clear_db()` (likely to time out on large tables).

---

## News Tool

A local Flask web app for managing news posts displayed in the mobile app. Located at `news_tool/`.

### File Structure

```
news_tool/
├── app.py              # Flask application (routes + Supabase logic)
├── templates/
│   └── index.html      # Main page – form, live preview, post list, edit modal
└── static/
    └── style.css       # Dark theme styles
```

### Running

```bash
python news_tool/app.py
# opens at http://localhost:5050
```

Requires `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` in `.env`.

### Routes

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | List all posts, show add form |
| POST | `/add` | Insert new post, upload image if provided |
| POST | `/edit/<uuid>` | Update post fields, replace image if provided |
| POST | `/delete/<uuid>` | Delete post row and its image from Storage |

All POST routes redirect to `/` (POST-Redirect-GET pattern) with a flash message stored in `session`.

### Image Handling

Images are stored in Supabase Storage bucket `Files` under path `News/{post_id}.png`.

- Upload: `PIL.Image` opens the file, converts to RGBA, calls `.thumbnail((1024, 1024), LANCZOS)`, saves as PNG to a `BytesIO` buffer, uploads with `x-upsert: true` (safe to call on insert or update).
- Retrieval: `db.storage.from_("Files").get_public_url("News/{post_id}.png")` — injected as `_image_url` into each post dict before rendering.
- Missing images: `<img onerror="this.style.display='none'">` hides the element gracefully.
- For new posts: the row is inserted first to obtain the UUID, then the image is uploaded using that UUID.

### Message Types

Three types stored in the `message_type` column:

| Value | Polish label | Badge color |
|-------|-------------|-------------|
| `info` | Komunikat | Blue (`#93c5fd`) |
| `warning` | Ostrzeżenie | Yellow (`#fcd34d`) |
| `alert` | Alert | Red (`#fca5a5`) |

### Live Preview

JavaScript in `index.html` listens to `input`/`change` events on the title, content, type, and image fields. Content is rendered as `innerHTML` (supports HTML tags like `<b>`, `<i>`, `<h2>`). Image preview uses `URL.createObjectURL()`.

### Edit Modal

Clicking "Edytuj" on a post calls `openEdit(post)` with the full post object serialised via `{{ post | tojson }}`. The modal populates form fields and sets `action="/edit/{id}"` dynamically.

### Supabase Table: `news`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key, auto-generated |
| `title` | text | Post title |
| `content` | text | HTML content |
| `message_type` | text | `info` / `warning` / `alert` |
| `created_at` | timestamptz | Auto-set by Supabase |

Image URL is derived from the `id` at runtime — there is no `image_url` column.
